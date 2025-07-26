# Handles public responses to scheduling polls without authentication
# League members can submit their availability via a unique link
class PublicSchedulingController < ApplicationController
  before_action :set_poll_by_token
  before_action :check_poll_active
  before_action :set_response_identifier

  def show
    @response = find_existing_response
    @time_slots = @poll.event_time_slots.order(:order_index, :starts_at)
  end

  def create
    handle_response_submission(notice_message: 'Your availability has been recorded!')
  end

  def update
    handle_response_submission(notice_message: 'Your availability has been updated!')
  end

  private

  def set_poll_by_token
    @poll = SchedulingPoll.find_by!(public_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render plain: 'Poll not found', status: :not_found
  end

  def check_poll_active
    unless @poll.active?
      render plain: 'This poll is no longer accepting responses', status: :forbidden
    end
  end

  def set_response_identifier
    @identifier = generate_identifier if params[:respondent_name].present?
  end

  def find_existing_response
    return nil unless @identifier

    @poll.scheduling_responses.find_by(respondent_identifier: @identifier)
  end

  def generate_identifier
    Digest::SHA256.hexdigest("#{params[:respondent_name].downcase.strip}-#{@poll.id}")
  end

  def response_params
    params.permit(:respondent_name, availabilities: {})
  end

  def handle_response_submission(notice_message:)
    result = PublicResponseHandler.new(
      poll: @poll,
      params: response_params,
      request: request
    ).handle(notice_message: notice_message)

    if result.success?
      redirect_to result.redirect_path, notice: result.notice
    else
      @response = result.response
      @time_slots = result.time_slots
      flash.now[:alert] = result.error
      render :show, status: :unprocessable_entity
    end
  end
end