# Represents a response to a scheduling poll from a league member
# Tracks who responded and their availability for each time slot
class SchedulingResponse < ApplicationRecord
  belongs_to :scheduling_poll
  has_many :slot_availabilities, dependent: :destroy

  validates :respondent_name, presence: true, length: { maximum: 50 }
  validates :respondent_identifier, presence: true, uniqueness: { scope: :scheduling_poll_id }

  # Add input sanitization to prevent XSS attacks
  before_validation :sanitize_respondent_name

  accepts_nested_attributes_for :slot_availabilities

  # Delegate to PORO for recording public responses
  def self.record_public_response(poll:, params:, request:, notice_message:)
    recorder = Scheduling::ResponseRecorder.new(
      poll: poll,
      request: request,
      notice_message: notice_message
    )
    recorder.record(params)
  end

  # Backward compatibility methods for tests
  def self.sanitize_response_params(params)
    Scheduling::ResponseRecorder.sanitize_params(params)
  end

  def self.generate_response_identifier(respondent_name, poll_id)
    Scheduling::ResponseRecorder.generate_identifier(respondent_name, poll_id)
  end

  def available_for?(event_time_slot)
    slot_availabilities.find_by(event_time_slot: event_time_slot)&.available_ideal?
  end

  def available_not_ideal_for?(event_time_slot)
    slot_availabilities.find_by(event_time_slot: event_time_slot)&.available_not_ideal?
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
        slot_availability.availability = availability_value.to_i
        slot_availability.save!
      end
    end
  end

  private

  # Input sanitization to prevent XSS attacks
  def sanitize_respondent_name
    return if respondent_name.blank?

    # Strip HTML tags and excessive whitespace
    self.respondent_name = ActionController::Base.helpers.strip_tags(respondent_name).strip

    # Limit length and remove potentially harmful characters
    self.respondent_name = respondent_name.gsub(/[<>&"']/, '').truncate(50)
  end
end
