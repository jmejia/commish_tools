# Domain object that analyzes draft results and generates grades
# Encapsulates the business logic for evaluating draft performance
class DraftAnalysis
  attr_reader :league, :draft_data

  def initialize(league, draft_data)
    @league = league
    @draft_data = draft_data
  end

  def calculate_all_grades
    return if league.draft_grades.any?

    ActiveRecord::Base.transaction do
      team_projections = calculate_team_projections
      generate_and_save_grades(team_projections)
    end
  end

  private

  def calculate_team_projections
    projections = {}
    picks_by_user = organize_picks_by_user

    picks_by_user.each do |user, picks|
      projections[user] = calculate_single_team_projection(picks)
    end

    add_relative_rankings(projections)
  end

  def organize_picks_by_user
    picks_by_user = Hash.new { |h, k| h[k] = [] }

    draft_data['draft'].each do |pick_data|
      sleeper_user_id = pick_data['picked_by']
      user = find_user_by_sleeper_id(sleeper_user_id)
      next unless user

      pick = create_draft_pick_object(pick_data)
      picks_by_user[user] << pick
    end

    picks_by_user
  end

  def create_draft_pick_object(pick_data)
    pick = OpenStruct.new(
      round: pick_data['round'],
      pick_number: pick_data['pick_no'],
      overall_pick: calculate_overall_pick(pick_data),
      player_id: pick_data['player_id'],
      sleeper_user_id: pick_data['picked_by']
    )

    # Add mock projections
    projection = generate_mock_projection(pick_data)
    pick.player_name = projection[:name]
    pick.position = projection[:position]
    pick.projected_points = projection[:projected_points]
    pick.value_over_replacement = projection[:projected_points] - replacement_level_for_position(projection[:position])
    pick.adp = nil # No ADP data for now

    # Add methods needed by the analysis
    pick.define_singleton_method(:is_value?) { (adp || overall_pick + 12) < overall_pick }
    pick.define_singleton_method(:is_reach?) { (adp || overall_pick - 12) > overall_pick }
    pick.define_singleton_method(:reach_value) { adp ? (adp - overall_pick) : 0 }
    pick.define_singleton_method(:pick_summary) do
      {
        player_name: player_name,
        position: position,
        round: round,
        pick: pick_number,
        projected_points: projected_points,
      }
    end

    pick
  end

  def calculate_overall_pick(pick_data)
    league_size = draft_data['league_size'] || 12
    ((pick_data['round'] - 1) * league_size) + pick_data['pick_no']
  end

  def generate_mock_projection(pick_data)
    base_points = 300 - (pick_data['pick_no'].to_i * 2) - (pick_data['round'].to_i * 10)
    variance = rand(-20..20)
    position = determine_position_from_pick(pick_data)

    {
      name: extract_player_name(pick_data),
      position: position,
      projected_points: [base_points + variance, 50].max.to_f,
    }
  end

  def determine_position_from_pick(pick_data)
    case pick_data['pick_no'].to_i
    when 1..3 then 'RB'
    when 4..6 then rand < 0.5 ? 'RB' : 'WR'
    when 7..9 then 'WR'
    when 10..12 then rand < 0.3 ? 'QB' : 'WR'
    else %w(RB WR QB TE DST K).sample
    end
  end

  def extract_player_name(pick_data)
    metadata = pick_data['metadata'] || {}
    first_name = metadata['first_name'] || 'Unknown'
    last_name = metadata['last_name'] || 'Player'
    "#{first_name} #{last_name}"
  end

  def replacement_level_for_position(position)
    replacement_levels = {
      'QB' => 180, 'RB' => 80, 'WR' => 90, 'TE' => 60, 'DST' => 50, 'K' => 100,
    }
    replacement_levels[position] || 50
  end

  def calculate_single_team_projection(picks)
    league_size = draft_data['league_size'] || 12
    starter_points = TeamRosterAnalyzer.new(picks, league_size).starter_points
    positional_balance = PositionalStrengthAnalyzer.new(picks).analyze

    {
      starter_points: starter_points,
      positional_balance: positional_balance,
      picks: picks,
    }
  end

  def find_user_by_sleeper_id(sleeper_user_id)
    league.league_memberships.
      find_by(sleeper_user_id: sleeper_user_id)&.
      user
  end

  def add_relative_rankings(projections)
    sorted_teams = projections.sort_by { |_, data| -data[:starter_points] }

    sorted_teams.each_with_index do |(user, data), index|
      data[:projected_rank] = index + 1
      data[:projected_wins] = ProjectedWinsCalculator.new(
        data[:starter_points],
        projections
      ).calculate
      data[:playoff_probability] = playoff_probability_for_rank(index + 1)
    end

    projections
  end

  def playoff_probability_for_rank(rank)
    # Assumes 6 team playoff - should be configurable
    case rank
    when 1..2 then 0.95
    when 3..4 then 0.80
    when 5..6 then 0.60
    when 7..8 then 0.35
    when 9..10 then 0.20
    when 11..12 then 0.05
    else 0.02
    end
  end

  def generate_and_save_grades(projections)
    projections.each do |user, data|
      grade_generator = DraftGradeGenerator.new(
        user: user,
        league: league,
        projection_data: data
      )

      grade_generator.create_grade
    end
  end
end

# Analyzes which players will start and calculates projected points
class TeamRosterAnalyzer
  STANDARD_ROSTER = {
    'QB' => 1,
    'RB' => 2,
    'WR' => 2,
    'TE' => 1,
    'DST' => 1,
    'K' => 1,
  }.freeze

  FLEX_POSITIONS = %w(RB WR TE).freeze

  attr_reader :picks, :league_size

  def initialize(picks, league_size)
    @picks = picks
    @league_size = league_size
  end

  def starter_points
    position_starters = calculate_position_starters
    flex_starter = calculate_flex_starter(position_starters)

    position_starters.sum { |pick| pick.projected_points || 0 } +
      (flex_starter&.projected_points || 0)
  end

  private

  def calculate_position_starters
    starters = []

    STANDARD_ROSTER.each do |position, count|
      position_picks = picks.
        select { |p| p.position == position }.
        sort_by { |p| -(p.projected_points || 0) }.
        first(count)

      starters.concat(position_picks)
    end

    starters
  end

  def calculate_flex_starter(position_starters)
    used_player_ids = position_starters.map(&:player_id)

    picks.
      select { |p| FLEX_POSITIONS.include?(p.position) }.
      reject { |p| used_player_ids.include?(p.player_id) }.
      max_by { |p| p.projected_points || 0 }
  end
end

# Analyzes positional strength for draft grades
class PositionalStrengthAnalyzer
  POSITION_THRESHOLDS = {
    'QB' => { 'A' => 40, 'B' => 20, 'C' => 10, 'D' => 0 },
    'RB' => { 'A' => 120, 'B' => 80, 'C' => 40, 'D' => 0 },
    'WR' => { 'A' => 100, 'B' => 60, 'C' => 30, 'D' => 0 },
    'TE' => { 'A' => 30, 'B' => 15, 'C' => 5, 'D' => 0 },
  }.freeze

  attr_reader :picks

  def initialize(picks)
    @picks = picks
  end

  def analyze
    strengths = {}

    POSITION_THRESHOLDS.keys.each do |position|
      position_picks = picks.select { |p| p.position == position }
      total_value = position_picks.sum(&:value_over_replacement)

      strengths[position] = {
        value: total_value,
        count: position_picks.size,
        grade: grade_for_position(position, total_value),
      }
    end

    strengths
  end

  private

  def grade_for_position(position, total_value)
    thresholds = POSITION_THRESHOLDS[position]
    return 'C' unless thresholds

    case total_value
    when thresholds['A']..Float::INFINITY then 'A'
    when thresholds['B']...thresholds['A'] then 'B'
    when thresholds['C']...thresholds['B'] then 'C'
    when thresholds['D']...thresholds['C'] then 'D'
    else 'F'
    end
  end
end

# Calculates projected wins based on team strength
class ProjectedWinsCalculator
  GAMES_PER_SEASON = 14
  POINT_DIFF_FACTOR = 20.0

  attr_reader :team_points, :all_projections

  def initialize(team_points, all_projections)
    @team_points = team_points
    @all_projections = all_projections
  end

  def calculate
    total_wins = 0.0

    all_projections.each do |_, opponent_data|
      next if opponent_data[:starter_points] == team_points

      win_probability = calculate_win_probability(opponent_data[:starter_points])
      total_wins += win_probability
    end

    (total_wins * GAMES_PER_SEASON / (all_projections.size - 1)).round(1)
  end

  private

  def calculate_win_probability(opponent_points)
    point_diff = team_points - opponent_points
    1.0 / (1.0 + Math.exp(-point_diff / POINT_DIFF_FACTOR))
  end
end

# Generates and saves draft grades
class DraftGradeGenerator
  attr_reader :user, :league, :projection_data

  def initialize(user:, league:, projection_data:)
    @user = user
    @league = league
    @projection_data = projection_data
  end

  def create_grade
    grade = DraftGrade.find_or_initialize_by(
      league: league,
      user: user
    )

    grade.update!(
      grade: calculate_overall_grade,
      projected_rank: projection_data[:projected_rank],
      projected_points: projection_data[:starter_points],
      projected_wins: projection_data[:projected_wins],
      playoff_probability: projection_data[:playoff_probability],
      position_grades: extract_position_grades,
      best_picks: find_best_picks,
      worst_picks: find_worst_picks,
      analysis: generate_analysis,
      calculated_at: Time.current
    )
  end

  private

  def calculate_overall_grade
    rank = projection_data[:projected_rank]

    case rank
    when 1 then 'A+'
    when 2 then 'A'
    when 3 then 'A-'
    when 4 then 'B+'
    when 5 then 'B'
    when 6 then 'B-'
    when 7 then 'C+'
    when 8 then 'C'
    when 9 then 'C-'
    when 10 then 'D+'
    when 11 then 'D'
    when 12 then 'D-'
    else 'F'
    end
  end

  def extract_position_grades
    grades = {}
    projection_data[:positional_balance].each do |pos, data|
      grades[pos] = data[:grade]
    end
    grades
  end

  def find_best_picks
    projection_data[:picks].
      select(&:is_value?).
      sort_by { |p| -(p.reach_value || 0) }.
      first(3).
      map(&:pick_summary)
  end

  def find_worst_picks
    projection_data[:picks].
      select(&:is_reach?).
      sort_by { |p| p.reach_value || 0 }.
      first(3).
      map(&:pick_summary)
  end

  def generate_analysis
    DraftAnalysisSummaryGenerator.new(
      projection_data: projection_data,
      picks: projection_data[:picks]
    ).generate
  end
end

# Generates analysis summaries for draft grades
class DraftAnalysisSummaryGenerator
  # Analysis thresholds
  VALUE_PICK_THRESHOLD = 3
  REACH_PICK_THRESHOLD = 3

  attr_reader :projection_data, :picks

  def initialize(projection_data:, picks:)
    @projection_data = projection_data
    @picks = picks
  end

  def generate
    {
      strengths: analyze_strengths,
      weaknesses: analyze_weaknesses,
      summary: generate_summary,
    }
  end

  private

  def analyze_strengths
    strengths = []

    # Check for strong positions
    projection_data[:positional_balance].each do |pos, info|
      case info[:grade]
      when 'A' then strengths << "Elite #{pos} depth"
      when 'B' then strengths << "Strong #{pos} group"
      end
    end

    # Check for value picks
    value_picks = picks.select(&:is_value?)
    if value_picks.size >= VALUE_PICK_THRESHOLD
      strengths << "Excellent draft value with #{value_picks.size} steals"
    end

    strengths
  end

  def analyze_weaknesses
    weaknesses = []

    # Check for weak positions
    projection_data[:positional_balance].each do |pos, info|
      if %w(D F).include?(info[:grade])
        weaknesses << "Weak #{pos} depth"
      end
    end

    # Check for reaches
    reaches = picks.select(&:is_reach?)
    if reaches.size >= REACH_PICK_THRESHOLD
      weaknesses << "Reached on #{reaches.size} picks"
    end

    weaknesses
  end

  def generate_summary
    rank = projection_data[:projected_rank]

    case rank
    when 1..3
      "Championship contender with elite roster construction"
    when 4..6
      "Solid playoff team with good upside"
    when 7..9
      "Bubble team that needs some breaks"
    when 10..12
      "Rebuilding year ahead - play the waiver wire hard"
    else
      "Rough draft - time to become a waiver wire warrior"
    end
  end
end
