# Represents an individual's availability for a specific time slot
# Part of a scheduling response, tracks if someone is available, maybe, or unavailable
class SlotAvailability < ApplicationRecord
  belongs_to :scheduling_response
  belongs_to :event_time_slot

  enum :availability, { unavailable: 0, maybe: 1, available: 2 }

  validates :availability, presence: true
end
