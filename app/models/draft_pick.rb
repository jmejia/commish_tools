# Represents a single pick in a fantasy football draft
# Tracks player selection, projections, and value analysis
class DraftPick < ApplicationRecord
  # Pick evaluation thresholds
  REACH_THRESHOLD = -8
  VALUE_THRESHOLD = 12
  MASSIVE_REACH_THRESHOLD = -15
  GOOD_VALUE_THRESHOLD = 8
  STEAL_THRESHOLD = 20

  belongs_to :draft
  belongs_to :user

  validates :sleeper_player_id, presence: true
  validates :sleeper_user_id, presence: true
  validates :round, presence: true, numericality: { greater_than: 0 }
  validates :pick_number, presence: true, numericality: { greater_than: 0 }
  validates :overall_pick, presence: true, numericality: { greater_than: 0 }

  scope :by_position, ->(position) { where(position: position) }
  scope :by_round, ->(round) { where(round: round) }
  scope :for_user, ->(user) { where(user: user) }
  scope :with_projections, -> { where.not(projected_points: nil) }
  scope :ordered, -> { order(:overall_pick) }

  # Class method to fetch replacement level points for a position
  def self.replacement_level_for(position)
    REPLACEMENT_LEVELS[position] || 50
  end

  REPLACEMENT_LEVELS = {
    'QB' => 180,
    'RB' => 80,
    'WR' => 90,
    'TE' => 60,
    'DST' => 50,
    'K' => 100,
  }.freeze

  def update_projections(projection_data)
    update!(
      player_name: projection_data[:name],
      position: projection_data[:position],
      projected_points: projection_data[:projected_points],
      value_over_replacement: calculate_vor(projection_data)
    )
  end

  def update_adp(adp_value)
    update!(adp: adp_value)
  end

  def reach_value
    return nil unless adp
    overall_pick - adp.to_f
  end

  def is_reach?
    return false unless reach_value
    reach_value < REACH_THRESHOLD
  end

  def is_value?
    return false unless reach_value
    reach_value > VALUE_THRESHOLD
  end

  def pick_quality
    return 'unknown' unless reach_value

    case reach_value
    when -Float::INFINITY..MASSIVE_REACH_THRESHOLD then 'massive_reach'
    when MASSIVE_REACH_THRESHOLD..REACH_THRESHOLD then 'reach'
    when REACH_THRESHOLD..GOOD_VALUE_THRESHOLD then 'fair_value'
    when GOOD_VALUE_THRESHOLD..STEAL_THRESHOLD then 'good_value'
    when STEAL_THRESHOLD..Float::INFINITY then 'steal'
    end
  end

  def points_per_draft_capital
    return 0 unless projected_points && overall_pick > 0
    projected_points / overall_pick
  end

  def pick_summary
    {
      player_name: player_name,
      position: position,
      round: round,
      pick: pick_number,
      reach_value: reach_value&.round || 'N/A',
    }
  end

  private

  def calculate_vor(projection_data)
    return 0 unless projection_data[:projected_points]
    replacement_level = self.class.replacement_level_for(projection_data[:position])
    projection_data[:projected_points] - replacement_level
  end
end

