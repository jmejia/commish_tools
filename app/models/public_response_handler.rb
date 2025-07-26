require 'ostruct'

# Domain object responsible for handling public poll responses
# Encapsulates the logic for processing responses from the public scheduling interface
class PublicResponseHandler
  attr_reader :poll, :params, :request

  def initialize(poll:, params:, request:)
    @poll = poll
    @params = params
    @request = request
  end

  def handle(notice_message:)
    result = record_response

    if result.success?
      success_response(notice_message)
    else
      failure_response(result.error)
    end
  end

  private

  def record_response
    ResponseRecorder.new(
      poll: poll,
      params: params.merge(
        ip_address: request.remote_ip,
        metadata: { user_agent: request.user_agent }
      )
    ).record
  end

  def success_response(message)
    OpenStruct.new(
      success?: true,
      redirect_path: Rails.application.routes.url_helpers.public_scheduling_path(poll.public_token),
      notice: message
    )
  end

  def failure_response(error_message)
    OpenStruct.new(
      success?: false,
      error: error_message,
      response: find_existing_response,
      time_slots: poll.event_time_slots.order(:order_index, :starts_at)
    )
  end

  def find_existing_response
    return nil unless params[:respondent_name].present?

    identifier = generate_identifier
    poll.scheduling_responses.find_by(respondent_identifier: identifier)
  end

  def generate_identifier
    Digest::SHA256.hexdigest("#{params[:respondent_name].downcase.strip}-#{poll.id}")
  end
end