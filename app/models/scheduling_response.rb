# Represents a response to a scheduling poll from a league member
# Tracks who responded and their availability for each time slot
class SchedulingResponse < ApplicationRecord
  belongs_to :scheduling_poll
  has_many :slot_availabilities, dependent: :destroy

  validates :respondent_name, presence: true, length: { maximum: 50 }
  validates :respondent_identifier, presence: true, uniqueness: { scope: :scheduling_poll_id }

  accepts_nested_attributes_for :slot_availabilities

  def available_for?(event_time_slot)
    slot_availabilities.find_by(event_time_slot: event_time_slot)&.available?
  end

  def maybe_for?(event_time_slot)
    slot_availabilities.find_by(event_time_slot: event_time_slot)&.maybe?
  end

  def unavailable_for?(event_time_slot)
    availability = slot_availabilities.find_by(event_time_slot: event_time_slot)
    availability.nil? || availability.unavailable?
  end

  def update_availabilities(availabilities_params)
    transaction do
      availabilities_params.each do |slot_id, availability_value|
        slot_availability = slot_availabilities.find_or_initialize_by(
          event_time_slot_id: slot_id
        )
        slot_availability.availability = availability_value
        slot_availability.save!
      end
    end
  end
end