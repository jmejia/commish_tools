# Manages fantasy football leagues including creation, importing from Sleeper,
# and dashboard functionality for league owners and members.
class LeaguesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league, only: [:show, :edit, :update, :destroy, :dashboard]
  before_action :ensure_league_member, only: [:show, :dashboard]
  before_action :ensure_league_admin, only: [:edit, :update, :destroy]

  def index
    logger = Rails.logger
    user_id = current_user.id

    logger.info "User #{user_id} accessing leagues index"
    @leagues = current_user.leagues.includes(:league_memberships)
    logger.info "Found #{@leagues.count} leagues for user"
  end

  def show
    Rails.logger.info "User #{current_user.id} viewing league #{@league.id}"
    @league_membership = current_user.league_memberships.find_by(league: @league)
  end

  def new
    Rails.logger.info "User #{current_user.id} creating new league"

    if current_user.sleeper_connected?
      # If Sleeper is connected, show league selection
      redirect_to select_sleeper_leagues_path
    else
      # If Sleeper is not connected, show connection form
      redirect_to connect_sleeper_path
    end
  end

  def connect_sleeper
    Rails.logger.info "User #{current_user.id} connecting Sleeper account"
  end

  def connect_sleeper_account
    result = SleeperAccountConnection.new(
      user: current_user,
      username: params[:sleeper_username]
    ).connect

    if result.success?
      # For the new approval workflow, redirect back to connect page with success message
      redirect_to connect_sleeper_path, notice: result.message
    else
      flash.now[:alert] = result.error
      render :connect_sleeper, status: :unprocessable_entity
    end
  end

  def select_sleeper_leagues
    Rails.logger.info "User #{current_user.id} selecting Sleeper leagues to import"

    unless current_user.sleeper_connected?
      redirect_to connect_sleeper_path, alert: 'Please connect your Sleeper account first.'
      return
    end

    @leagues = current_user.fetch_sleeper_leagues
    @existing_league_ids = current_user.leagues.pluck(:sleeper_league_id).compact

    if @leagues.empty?
      flash.now[:alert] = 'No leagues found for your Sleeper account.'
    end
  end

  def import_sleeper_league
    result = SleeperLeagueImporter.new(
      user: current_user,
      sleeper_league_id: params[:sleeper_league_id]
    ).import

    if result.success?
      redirect_to dashboard_league_path(result.league), notice: result.message
    else
      redirect_to select_sleeper_leagues_path, alert: result.error
    end
  end

  def edit
    Rails.logger.info "User #{current_user.id} editing league #{@league.id}"
  end

  def create
    result = LeagueCreation.new(
      user: current_user,
      league_params: league_params
    ).create

    if result.success?
      redirect_to dashboard_league_path(result.league), notice: result.message
    else
      @league = result.league
      render :new, status: :unprocessable_entity
    end
  end

  def update
    Rails.logger.info "User #{current_user.id} updating league #{@league.id}"

    if @league.update(league_params)
      redirect_to dashboard_league_path(@league), notice: 'League was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "User #{current_user.id} deleting league #{@league.id}"
    @league.destroy!
    redirect_to leagues_url, notice: 'League was successfully deleted.'
  end

  def dashboard
    Rails.logger.info "User #{current_user.id} accessing dashboard for league #{@league.id}"
    @league_membership = current_user.league_memberships.find_by(league: @league)
    @recent_press_conferences = @league.press_conferences.
      includes(target_manager: :user).
      order(created_at: :desc).
      limit(5)
  end

  private

  def set_league
    @league = League.find(params[:id])
    Rails.logger.info "Set league #{@league.id} for action"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "League not found with id: #{params[:id]}"
    redirect_to leagues_path, alert: 'League not found.'
  end

  def ensure_league_member
    unless current_user.leagues.include?(@league) || @league.owner == current_user
      Rails.logger.warn "User #{current_user.id} attempted to access league #{@league.id} without membership"
      redirect_to leagues_path, alert: 'You are not a member of this league.'
    end
  end

  def ensure_league_admin
    membership = current_user.league_memberships.find_by(league: @league)
    unless membership&.owner?
      Rails.logger.warn "User #{current_user.id} attempted admin action on league #{@league.id} without owner rights"
      redirect_to dashboard_league_path(@league), alert: 'You must be the league owner to perform this action.'
    end
  end

  def league_params
    params.require(:league).permit(:name, :sleeper_league_id, :season_year)
  end
end
