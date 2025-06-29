class LeaguesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league, only: [:show, :edit, :update, :destroy, :dashboard]
  before_action :ensure_league_member, only: [:show, :dashboard]
  before_action :ensure_league_admin, only: [:edit, :update, :destroy]

  def index
    Rails.logger.info "User #{current_user.id} accessing leagues index"
    @leagues = current_user.leagues.includes(:league_memberships)
    Rails.logger.info "Found #{@leagues.count} leagues for user"
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
    Rails.logger.info "User #{current_user.id} attempting to connect Sleeper account with username: #{params[:sleeper_username]}"

    if current_user.connect_sleeper_account(params[:sleeper_username])
      Rails.logger.info "Sleeper account connected successfully for user #{current_user.id}"
      redirect_to select_sleeper_leagues_path, notice: 'Sleeper account connected successfully!'
    else
      Rails.logger.warn "Failed to connect Sleeper account for user #{current_user.id}"
      flash.now[:alert] = 'Failed to connect Sleeper account. Please check your username and try again.'
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
    Rails.logger.info "User #{current_user.id} importing Sleeper league #{params[:sleeper_league_id]}"

    unless current_user.sleeper_connected?
      redirect_to connect_sleeper_path, alert: 'Please connect your Sleeper account first.'
      return
    end

    sleeper_league_id = params[:sleeper_league_id]

    # Check if league already exists
    if League.exists?(sleeper_league_id: sleeper_league_id)
      redirect_to select_sleeper_leagues_path, alert: 'This league has already been imported.'
      return
    end

    # Fetch league details and user's roster from Sleeper
    client = SleeperFF.new
    league_data = client.league(sleeper_league_id)

    if league_data
      # Get league rosters to find user's team info
      rosters = client.league_rosters(sleeper_league_id)
      user_roster = rosters&.find { |roster| roster.owner_id == current_user.sleeper_id }

      # Get league users to find team name
      league_users = client.league_users(sleeper_league_id)
      user_in_league = league_users&.find { |u| u.user_id == current_user.sleeper_id }

      # Determine team name - use display name or fallback to username
      team_name = user_in_league&.display_name || current_user.sleeper_username || "#{current_user.first_name}'s Team"

      ActiveRecord::Base.transaction do
        @league = League.create!(
          name: league_data.name,
          sleeper_league_id: sleeper_league_id,
          season_year: league_data.season.to_i,
          owner_id: current_user.id
        )

        @league.league_memberships.create!(
          user: current_user,
          role: :owner,
          sleeper_user_id: current_user.sleeper_id,
          team_name: team_name
        )

        Rails.logger.info "Sleeper league #{sleeper_league_id} imported successfully by user #{current_user.id}"
        redirect_to dashboard_league_path(@league), notice: 'League imported successfully!'
      end
    else
      Rails.logger.warn "Failed to import Sleeper league #{sleeper_league_id} for user #{current_user.id}"
      redirect_to select_sleeper_leagues_path, alert: 'Failed to import league. Please try again.'
    end
  rescue StandardError => e
    Rails.logger.error "Error importing Sleeper league #{sleeper_league_id}: #{e.message}"
    redirect_to select_sleeper_leagues_path, alert: 'An error occurred while importing the league.'
  end

  def edit
    Rails.logger.info "User #{current_user.id} editing league #{@league.id}"
  end

  def create
    Rails.logger.info "User #{current_user.id} attempting to create league with params: #{league_params}"
    @league = League.new(league_params.merge(owner_id: current_user.id))

    ActiveRecord::Base.transaction do
      if @league.save
        @league.league_memberships.create!(
          user: current_user,
          role: :owner
        )
        Rails.logger.info "League #{@league.id} created successfully by user #{current_user.id}"
        redirect_to dashboard_league_path(@league), notice: 'League was successfully created.'
      else
        Rails.logger.warn "League creation failed for user #{current_user.id}: #{@league.errors.full_messages}"
        render :new, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  def update
    Rails.logger.info "User #{current_user.id} updating league #{@league.id} with params: #{league_params}"

    if @league.update(league_params)
      Rails.logger.info "League #{@league.id} updated successfully"
      redirect_to dashboard_league_path(@league), notice: 'League was successfully updated.'
    else
      Rails.logger.warn "League update failed: #{@league.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "User #{current_user.id} deleting league #{@league.id}"
    @league.destroy!
    Rails.logger.info "League #{@league.id} deleted successfully"
    redirect_to leagues_url, notice: 'League was successfully deleted.'
  end

  def dashboard
    Rails.logger.info "User #{current_user.id} accessing dashboard for league #{@league.id}"
    @league_membership = current_user.league_memberships.find_by(league: @league)
    @recent_press_conferences = @league.press_conferences
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
    unless current_user.leagues.include?(@league)
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
