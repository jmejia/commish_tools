# Represents a response to a scheduling poll from a league member
# Tracks who responded and their availability for each time slot
class SchedulingResponse < ApplicationRecord
  # Result object for response recording operations
  RecordingResult = Struct.new(:success?, :response, :message, :error, :redirect_path, :notice, :time_slots,
keyword_init: true)

  belongs_to :scheduling_poll
  has_many :slot_availabilities, dependent: :destroy

  validates :respondent_name, presence: true, length: { maximum: 50 }
  validates :respondent_identifier, presence: true, uniqueness: { scope: :scheduling_poll_id }

  # Add input sanitization to prevent XSS attacks
  before_validation :sanitize_respondent_name

  accepts_nested_attributes_for :slot_availabilities

  # Domain method to record a public response with validation and error handling
  # Replaces PublicResponseHandler and ResponseRecorder service objects
  def self.record_public_response(poll:, params:, request:, notice_message:)
    # Security: Sanitize input parameters early
    sanitized_params = sanitize_response_params(params)

    recording_result = record_response_for_poll(
      poll: poll,
      params: sanitized_params.merge(
        ip_address: request.remote_ip,
        metadata: { user_agent: request.user_agent }
      )
    )

    if recording_result.success?
      RecordingResult.new(
        success?: true,
        redirect_path: Rails.application.routes.url_helpers.public_scheduling_path(poll.public_token),
        notice: notice_message,
        response: recording_result.response
      )
    else
      RecordingResult.new(
        success?: false,
        error: recording_result.error,
        response: find_existing_response_for_poll(poll, sanitized_params),
        time_slots: poll.event_time_slots.order(:order_index, :starts_at)
      )
    end
  end

  # Domain method to record response with transaction safety
  def self.record_response_for_poll(poll:, params:)
    Rails.logger.info "Recording response for poll #{poll.id}"

    return failure_result("This poll is no longer accepting responses.") unless poll.active?

    ActiveRecord::Base.transaction do
      response = find_or_initialize_response_for_poll(poll, params)

      if update_response_with_availabilities(response, params)
        Rails.logger.info "Response recorded successfully for poll #{poll.id}"
        success_result(response: response, message: "Your availability has been recorded!")
      else
        Rails.logger.error "Failed to record response: #{response.errors.full_messages.join(', ')}"
        failure_result(response.errors.full_messages.join(', '))
      end
    end
  rescue StandardError => exception
    Rails.logger.error "Error recording response: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    failure_result("An error occurred while recording your response: #{exception.message}")
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

  # Class-level input sanitization
  def self.sanitize_response_params(params)
    sanitized = params.dup

    if sanitized[:respondent_name].present?
      # Strip HTML tags and harmful characters
      name = ActionController::Base.helpers.strip_tags(sanitized[:respondent_name]).strip
      sanitized[:respondent_name] = name.gsub(/[<>&"']/, '').truncate(50)
    end

    sanitized
  end

  def self.find_or_initialize_response_for_poll(poll, params)
    identifier = generate_response_identifier(params[:respondent_name], poll.id)

    poll.scheduling_responses.find_or_initialize_by(
      respondent_identifier: identifier
    ).tap do |response|
      response.respondent_name = params[:respondent_name]
      response.ip_address = params[:ip_address]
      response.metadata = params[:metadata] || {}
    end
  end

  def self.update_response_with_availabilities(response, params)
    # Save the response first
    return false unless response.save

    # Update availabilities for each time slot
    if params[:availabilities].present?
      response.update_availabilities(params[:availabilities])
    end

    true
  end

  def self.find_existing_response_for_poll(poll, params)
    return nil if params[:respondent_name].blank?

    identifier = generate_response_identifier(params[:respondent_name], poll.id)
    poll.scheduling_responses.find_by(respondent_identifier: identifier)
  end

  def self.generate_response_identifier(respondent_name, poll_id)
    # Use name + poll id to create a consistent identifier
    # This allows people to update their response later
    Digest::SHA256.hexdigest("#{respondent_name.downcase.strip}-#{poll_id}")
  end

  def self.success_result(response:, message:)
    RecordingResult.new(
      success?: true,
      response: response,
      message: message,
      error: nil
    )
  end

  def self.failure_result(error_message)
    RecordingResult.new(
      success?: false,
      response: nil,
      message: nil,
      error: error_message
    )
  end
end
