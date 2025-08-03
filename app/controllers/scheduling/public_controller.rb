# Handles public responses to scheduling polls without authentication
# League members can submit their availability via a unique link
class Scheduling::PublicController < ApplicationController
  include RateLimitable
  include SpamProtectable

  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :set_poll_by_token
  before_action :check_poll_active, except: [:thank_you]
  before_action :apply_security_checks, only: [:create, :update]
  before_action :set_response_identifier, except: [:thank_you]

  def show
    Rails.logger.info "PublicSchedulingController#show called"
    Rails.logger.info "Poll found: #{@poll.inspect}"
    @time_slots = @poll.event_time_slots.order(:starts_at)
    @existing_response = find_existing_response
    @response = @existing_response || SchedulingResponse.new
    @form_start_time = Time.current.iso8601
  end

  def create
    handle_response_submission(notice_message: I18n.t('controllers.public_scheduling.availability_recorded'))
  end

  def update
    handle_response_submission(notice_message: I18n.t('controllers.public_scheduling.availability_updated'))
  end

  def thank_you
    # Just display the thank you page
    # The poll is already loaded by set_poll_by_token
  end

  private

  def set_poll_by_token
    Rails.logger.info "Looking for poll with token: #{params[:token]}"
    @poll = SchedulingPoll.find_by!(public_token: params[:token])
    Rails.logger.info "Found poll: #{@poll&.id}, status: #{@poll&.status}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Poll not found for token: #{params[:token]}"
    render plain: I18n.t('controllers.public_scheduling.poll_not_found'), status: :not_found
  end

  def check_poll_active
    Rails.logger.info "Checking poll active status: #{@poll&.status}"
    unless @poll.active?
      Rails.logger.warn "Poll is not active, rendering 403"
      render plain: I18n.t('controllers.public_scheduling.poll_inactive'), status: :forbidden
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
    params.permit(:respondent_name, :form_start_time, :email_confirm, availabilities: {})
  end

  def apply_security_checks
    # Each security check method renders an error response and returns false if it fails
    # For before_action callbacks, we need to stop execution if any check fails
    return unless check_rate_limit(:public_response, request.remote_ip)
    return unless check_honeypot(:email_confirm)
    return unless check_spam_patterns([:respondent_name])
    nil unless check_submission_timing(:form_start_time)
  end

  def handle_response_submission(notice_message:)
    result = SchedulingResponse.record_public_response(
      poll: @poll,
      params: response_params,
      request: request,
      notice_message: notice_message
    )

    result.success? ? handle_success(result) : handle_failure(result)
  end

  def handle_success(result)
    # Broadcast updates to all viewers of the poll
    result.response.scheduling_poll.broadcast_updates

    redirect_to public_scheduling_thank_you_path(@poll.public_token), notice: result.notice
  end

  def handle_failure(result)
    @response = result.response
    @time_slots = result.time_slots
    @form_start_time = Time.current.iso8601
    flash.now[:alert] = result.error
    render :show, status: :unprocessable_entity
  end
end