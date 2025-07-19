# Manages press conference creation and management for league owners
class PressConferencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league
  before_action :ensure_league_owner, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_press_conference, only: [:show, :edit, :update, :destroy]

  def index
    Rails.logger.info "User #{current_user.id} viewing press conferences for league #{@league.id}"
    @press_conferences = @league.press_conferences.includes(:target_manager)
  end

  def show
    Rails.logger.info "User #{current_user.id} viewing press conference #{@press_conference.id}"
    @league_membership = current_user.league_memberships.find_by(league: @league)
  end

  def new
    Rails.logger.info "User #{current_user.id} creating new press conference for league #{@league.id}"
    @press_conference = @league.press_conferences.build
    @league_members = @league.league_memberships.includes(:user)
  end

  def edit
    Rails.logger.info "User #{current_user.id} editing press conference #{@press_conference.id}"
  end

  def create
    Rails.logger.info "User #{current_user.id} submitting press conference for league #{@league.id}"

    # Validate league member selection first
    if params[:league_member_id].blank?
      flash.now[:alert] = 'League Member must be selected'
      @press_conference = @league.press_conferences.build
      @league_members = @league.league_memberships.includes(:user)
      render :new, status: :unprocessable_entity
      return
    end

    # Extract the three questions from params
    questions = [
      params[:question_1]&.strip,
      params[:question_2]&.strip,
      params[:question_3]&.strip,
    ]

    # Validate questions
    if questions.any?(&:blank?)
      flash.now[:alert] = 'All three questions are required'
      @press_conference = @league.press_conferences.build
      @league_members = @league.league_memberships.includes(:user)
      render :new, status: :unprocessable_entity
      return
    end

    target_member = @league.league_memberships.find(params[:league_member_id])

    # Create press conference
    @press_conference = @league.press_conferences.build(
      target_manager: target_member,
      week_number: 1, # TODO: Calculate current week
      season_year: @league.season_year,
      status: :draft
    )

    if @press_conference.save
      # Create the three questions
      questions.each_with_index do |question, index|
        @press_conference.press_conference_questions.create!(
          question_text: question,
          order_index: index + 1
        )
      end

      # Start ChatGPT response generation in background
      ChatgptResponseGenerationJob.perform_later(@press_conference.id)

      Rails.logger.info "Press conference #{@press_conference.id} created successfully"
      redirect_to league_press_conference_path(@league, @press_conference), notice: 'Press Conference Created'
    else
      Rails.logger.error "Failed to create press conference: #{@press_conference.errors.full_messages}"
      @league_members = @league.league_memberships.includes(:user)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    Rails.logger.info "User #{current_user.id} updating press conference #{@press_conference.id}"

    if @press_conference.update(press_conference_params)
      redirect_to press_conference_path(@press_conference), notice: 'Press conference updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "User #{current_user.id} deleting press conference #{@press_conference.id}"
    
    # Log what will be deleted for audit purposes
    questions_count = @press_conference.press_conference_questions.count
    responses_count = @press_conference.press_conference_responses.count
    has_final_audio = @press_conference.final_audio.attached?
    
    question_audio_count = @press_conference.press_conference_questions
                                            .joins(:question_audio_attachment)
                                            .count
    response_audio_count = @press_conference.press_conference_responses
                                            .joins(:response_audio_attachment)
                                            .count
    
    Rails.logger.info "Deleting press conference #{@press_conference.id}: " \
                      "#{questions_count} questions, #{responses_count} responses, " \
                      "#{question_audio_count} question audio files, " \
                      "#{response_audio_count} response audio files, " \
                      "final audio: #{has_final_audio}"
    
    # Destroy the press conference (cascade will handle associated records and files)
    @press_conference.destroy!
    
    Rails.logger.info "Successfully deleted press conference #{@press_conference.id} and all associated data"
    redirect_to dashboard_league_path(@league), notice: 'Press conference and all associated files deleted successfully'
  end

  private

  def set_league
    @league = current_user.leagues.find(params[:league_id])
    Rails.logger.info "Set league #{@league.id} for press conference action"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "League not found with id: #{params[:league_id]}"
    redirect_to leagues_path, alert: 'League not found.'
  end

  def set_press_conference
    @press_conference = @league.press_conferences.
      includes(press_conference_questions: :press_conference_response,
               target_manager: :user).
      find(params[:id])
    Rails.logger.info "Set press conference #{@press_conference.id}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Press conference not found with id: #{params[:id]}"
    redirect_to dashboard_league_path(@league), alert: 'Press conference not found.'
  end

  def ensure_league_owner
    membership = current_user.league_memberships.find_by(league: @league)
    return if membership&.owner?

    Rails.logger.warn "User #{current_user.id} attempted press conference action on league #{@league.id} without owner rights"
    redirect_to dashboard_league_path(@league), alert: 'Only league owners can create press conferences.'
  end

  def press_conference_params
    params.expect(press_conference: [:week_number, :season_year, :status])
  end
end
