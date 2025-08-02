# Value object representing a draft pick with calculated projections and analysis methods
# Uses Dry::Struct for better type safety and validation
require_relative 'types'

class DraftPickValue < Dry::Struct
  # Pick evaluation thresholds
  VALUE_THRESHOLD = 12
  REACH_THRESHOLD = 12

  attribute :round, Types::Integer
  attribute :pick_number, Types::Integer
  attribute :overall_pick, Types::Integer
  attribute :player_id, Types::String
  attribute :sleeper_user_id, Types::String
  attribute :player_name, Types::String
  attribute :position, Types::String
  attribute :projected_points, Types::Float
  attribute :value_over_replacement, Types::Float
  attribute :adp, Types::Float.optional

  def value?
    return false if adp.nil?
    adp > overall_pick + VALUE_THRESHOLD
  end

  def reach?
    return false if adp.nil?
    adp < overall_pick - REACH_THRESHOLD
  end

  def reach_value
    adp ? (overall_pick - adp) : 0
  end

  def pick_summary
    {
      player_name: player_name,
      position: position,
      round: round,
      pick: pick_number,
      projected_points: projected_points,
    }
  end

  # Legacy method names for backward compatibility
  alias_method :is_value?, :value?
  alias_method :is_reach?, :reach?
end
