# Represents a fantasy football draft with picks and calculated grades
# Manages draft lifecycle and grade calculation orchestration
class Draft < ApplicationRecord
  include SleeperUserLookup
  
  belongs_to :league
  has_many :draft_picks, dependent: :destroy
  has_many :draft_grades, dependent: :destroy

  enum :status, {
    pending: 'pending',
    in_progress: 'in_progress',
    completed: 'completed',
    cancelled: 'cancelled'
  }, prefix: true

  enum :draft_type, {
    snake: 0,
    auction: 1,
    linear: 2
  }, prefix: true

  validates :sleeper_draft_id, presence: true, uniqueness: true
  validates :status, presence: true
  validates :season_year, presence: true,
                          numericality: { greater_than: 2000, less_than_or_equal_to: -> { Date.current.year + 1 } }
  validates :league_size, presence: true,
                          numericality: { greater_than: 0, less_than_or_equal_to: 32 }

  scope :completed, -> { where(status: 'completed') }
  scope :for_season, ->(year) { where(season_year: year) }
  scope :recent, -> { order(completed_at: :desc) }
  scope :with_grades, -> { includes(:draft_grades) }

  def calculate_grades_async
    return unless status_completed?
    DraftGradeCalculationJob.perform_later(self)
  end

  def calculate_grades
    return unless status_completed?
    # Need to construct draft_data from the draft's picks
    draft_data = {
      'draft' => draft_picks.map do |pick|
        {
          'player_id' => pick.sleeper_player_id,
          'picked_by' => pick.sleeper_user_id,
          'round' => pick.round,
          'pick_no' => pick.pick_number,
          'metadata' => pick.metadata
        }
      end,
      'league_size' => league_size
    }
    DraftAnalysis.new(league, draft_data).calculate_all_grades
  end

  def grades_calculated?
    draft_grades.any?
  end

  def recalculate_grades
    draft_grades.destroy_all
    calculate_grades_async
  end

  def import_picks_from_sleeper(picks_data)
    transaction do
      picks_data.each do |pick_data|
        required_fields = %w[player_id picked_by round pick_no]
        missing_fields = required_fields - pick_data.keys
        raise ArgumentError, "Missing required fields: #{missing_fields.join(', ')}" if missing_fields.any?
        
        draft_picks.create!(
          sleeper_player_id: pick_data['player_id'],
          sleeper_user_id: pick_data['picked_by'],
          user: find_user_by_sleeper_id(pick_data['picked_by']),
          round: pick_data['round'],
          pick_number: pick_data['pick_no'],
          overall_pick: calculate_overall_pick(pick_data['round'], pick_data['pick_no']),
          metadata: pick_data['metadata']
        )
      end
    end
  end

  def picks_by_user
    draft_picks.includes(:user).group_by(&:user)
  end

  def picks_for_user(user)
    draft_picks.where(user: user).order(:overall_pick)
  end

  private

  def calculate_overall_pick(round, pick_number)
    ((round - 1) * league_size) + pick_number
  end

end