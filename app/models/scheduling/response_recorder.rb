# PORO for recording scheduling poll responses
# Extracted from SchedulingResponse.record_public_response
module Scheduling
  class ResponseRecorder
    # Result object for response recording operations
    RecordingResult = Struct.new(:success?, :response, :message, :error, :redirect_path, :notice, :time_slots,
      keyword_init: true)

    def initialize(poll:, request:, notice_message:)
      @poll = poll
      @request = request
      @notice_message = notice_message
    end

    def record(params)
      # Security: Sanitize input parameters early
      sanitized_params = sanitize_response_params(params)

      recording_result = record_response_for_poll(
        sanitized_params.merge(
          ip_address: @request.remote_ip,
          metadata: { user_agent: @request.user_agent }
        )
      )

      if recording_result.success?
        RecordingResult.new(
          success?: true,
          redirect_path: Rails.application.routes.url_helpers.public_scheduling_path(@poll.public_token),
          notice: @notice_message,
          response: recording_result.response
        )
      else
        RecordingResult.new(
          success?: false,
          error: recording_result.error,
          response: find_existing_response_for_poll(sanitized_params),
          time_slots: @poll.event_time_slots.order(:order_index, :starts_at)
        )
      end
    end

    private

    attr_reader :poll, :request, :notice_message

    def record_response_for_poll(params)
      Rails.logger.info "Recording response for poll #{poll.id}"

      return failure_result("This poll is no longer accepting responses.") unless poll.active?

      ActiveRecord::Base.transaction do
        response = find_or_initialize_response_for_poll(params)

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

    # Class-level input sanitization
    def sanitize_response_params(params)
      sanitized = params.dup

      if sanitized[:respondent_name].present?
        # Strip HTML tags and harmful characters
        name = ActionController::Base.helpers.strip_tags(sanitized[:respondent_name]).strip
        sanitized[:respondent_name] = name.gsub(/[<>&"']/, '').truncate(50)
      end

      sanitized
    end

    def find_or_initialize_response_for_poll(params)
      identifier = generate_response_identifier(params[:respondent_name], poll.id)

      poll.scheduling_responses.find_or_initialize_by(
        respondent_identifier: identifier
      ).tap do |response|
        response.respondent_name = params[:respondent_name]
        response.ip_address = params[:ip_address]
        response.metadata = params[:metadata] || {}
      end
    end

    def update_response_with_availabilities(response, params)
      # Save the response first
      return false unless response.save

      # Update availabilities for each time slot
      if params[:availabilities].present?
        response.update_availabilities(params[:availabilities])
      end

      true
    end

    def find_existing_response_for_poll(params)
      return nil if params[:respondent_name].blank?

      identifier = generate_response_identifier(params[:respondent_name], poll.id)
      poll.scheduling_responses.find_by(respondent_identifier: identifier)
    end

    def generate_response_identifier(respondent_name, poll_id)
      # Use name + poll id to create a consistent identifier
      # This allows people to update their response later
      Digest::SHA256.hexdigest("#{respondent_name.downcase.strip}-#{poll_id}")
    end

    def success_result(response:, message:)
      RecordingResult.new(
        success?: true,
        response: response,
        message: message,
        error: nil
      )
    end

    def failure_result(error_message)
      RecordingResult.new(
        success?: false,
        response: nil,
        message: nil,
        error: error_message
      )
    end
  end
end