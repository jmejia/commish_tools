# Stores calculated draft grades for each team in a league
# Generated after draft completion with projections and analysis
class DraftGrade < ApplicationRecord
  include DraftGradeMonitoring

  belongs_to :league
  belongs_to :user

  # Association to get league membership for this user in this league
  def league_membership
    @league_membership ||= user.league_memberships.find_by(league: league)
  end

  validates :grade, presence: true, inclusion: { in: %w(A+ A A- B+ B B- C+ C C- D+ D D- F) }
  validates :projected_rank, presence: true,
                             numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validates :user_id, uniqueness: {
    scope: :league_id,
    message: "can only have one draft grade per league",
  }

  scope :for_league, ->(league) { where(league: league) }
  scope :for_draft, ->(draft) { where(draft: draft) }
  scope :with_associations, -> { includes(:user, :league_membership) }
  scope :by_grade, -> {
    # Safe grade ordering without SQL injection risk
    # Future optimization: consider adding grade_value column for simpler queries
    grade_order_sql = sanitize_sql([
      "CASE grade " +
      "WHEN ? THEN 1 WHEN ? THEN 2 WHEN ? THEN 3 " +
      "WHEN ? THEN 4 WHEN ? THEN 5 WHEN ? THEN 6 " +
      "WHEN ? THEN 7 WHEN ? THEN 8 WHEN ? THEN 9 " +
      "WHEN ? THEN 10 WHEN ? THEN 11 WHEN ? THEN 12 " +
      "WHEN ? THEN 13 END",
      'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F'
    ])
    order(Arel.sql(grade_order_sql))
  }
  scope :by_projected_rank, -> { order(:projected_rank) }

  def display_team_name
    team_name || user.display_name
  end

  # For backwards compatibility with existing tests
  def team_name
    league_membership&.team_name || user.display_name
  end

  def letter_grade_value
    GRADE_VALUES[grade] || 0.0
  end

  # For backwards compatibility with existing tests
  def grade_color_class
    ActiveSupport::Deprecation.warn("grade_color_class is deprecated. Use DraftGradesHelper#grade_color_class instead")
    case grade_category
    when :excellent then 'text-green-600 bg-green-50'
    when :good then 'text-blue-600 bg-blue-50'
    when :average then 'text-yellow-600 bg-yellow-50'
    when :below_average then 'text-orange-600 bg-orange-50'
    when :failing then 'text-red-600 bg-red-50'
    end
  end

  # Move view logic to a helper method instead
  def grade_category
    case grade
    when 'A+', 'A', 'A-' then :excellent
    when 'B+', 'B', 'B-' then :good
    when 'C+', 'C', 'C-' then :average
    when 'D+', 'D', 'D-' then :below_average
    when 'F' then :failing
    end
  end

  private

  GRADE_VALUES = {
    'A+' => 4.3, 'A' => 4.0, 'A-' => 3.7,
    'B+' => 3.3, 'B' => 3.0, 'B-' => 2.7,
    'C+' => 2.3, 'C' => 2.0, 'C-' => 1.7,
    'D+' => 1.3, 'D' => 1.0, 'D-' => 0.7,
    'F' => 0.0,
  }.freeze
end

