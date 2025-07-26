require 'ostruct'

# Domain object responsible for recording responses to scheduling polls
# Handles creating/updating responses with availability for each time slot
class ResponseRecorder
  attr_reader :poll, :params

  def initialize(poll:, params:)
    @poll = poll
    @params = params
  end

  def record
    Rails.logger.info "Recording response for poll #{poll.id}"

    return failure("This poll is no longer accepting responses.") unless poll.active?

    ActiveRecord::Base.transaction do
      response = find_or_initialize_response
      
      if update_response(response)
        Rails.logger.info "Response recorded successfully for poll #{poll.id}"
        success(response: response, message: "Your availability has been recorded!")
      else
        Rails.logger.error "Failed to record response: #{response.errors.full_messages.join(', ')}"
        failure(response.errors.full_messages.join(', '))
      end
    end
  rescue StandardError => exception
    Rails.logger.error "Error recording response: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    failure("An error occurred while recording your response: #{exception.message}")
  end

  private

  def find_or_initialize_response
    identifier = generate_identifier
    
    poll.scheduling_responses.find_or_initialize_by(
      respondent_identifier: identifier
    ).tap do |response|
      response.respondent_name = params[:respondent_name]
      response.ip_address = params[:ip_address]
      response.metadata = params[:metadata] || {}
    end
  end

  def update_response(response)
    # Save the response first
    return false unless response.save

    # Update availabilities for each time slot
    if params[:availabilities].present?
      response.update_availabilities(params[:availabilities])
    end

    true
  end

  def generate_identifier
    # Use name + poll id to create a consistent identifier
    # This allows people to update their response later
    Digest::SHA256.hexdigest("#{params[:respondent_name].downcase.strip}-#{poll.id}")
  end

  def success(response:, message:)
    OpenStruct.new(
      success?: true,
      response: response,
      message: message,
      error: nil
    )
  end

  def failure(error_message)
    OpenStruct.new(
      success?: false,
      response: nil,
      message: nil,
      error: error_message
    )
  end
end