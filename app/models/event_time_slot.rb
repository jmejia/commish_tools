# Represents a time slot option for a scheduling poll
# Each slot has a start time, duration, and can collect availability from respondents
class EventTimeSlot < ApplicationRecord
  belongs_to :scheduling_poll
  has_many :slot_availabilities, dependent: :destroy

  validates :starts_at, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }

  delegate :event_type, to: :scheduling_poll

  def ends_at
    starts_at + duration_minutes.minutes
  end

  def availability_summary
    availabilities = slot_availabilities.group(:availability).count
    {
      available: availabilities[2] || 0,
      maybe: availabilities[1] || 0,
      unavailable: availabilities[0] || 0
    }
  end

  def available_count
    availability_summary[:available]
  end

  def availability_score
    summary = availability_summary
    total_responses = summary.values.sum
    return 0 if total_responses.zero?

    # Weighted score: available = 2 points, maybe = 1 point
    ((summary[:available] * 2 + summary[:maybe]) / (total_responses * 2.0) * 100).round
  end

  def formatted_time(timezone = nil)
    # TODO: Respect league timezone when we add that feature
    time_format = '%B %d, %Y at %l:%M %p'
    starts_at.strftime(time_format).strip
  end

  def display_label
    case scheduling_poll.event_type
    when 'draft'
      "#{formatted_time} - #{duration_minutes / 60}hr draft window"
    else
      "#{formatted_time} - #{duration_minutes}min"
    end
  end
end