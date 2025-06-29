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
    @league = League.new
  end

  def create
    Rails.logger.info "User #{current_user.id} attempting to create league with params: #{league_params}"
    @league = League.new(league_params)
    
    if @league.save
      # Make the creator an admin
      @league.league_memberships.create!(
        user: current_user,
        role: 'admin'
      )
      Rails.logger.info "League #{@league.id} created successfully by user #{current_user.id}"
      redirect_to @league, notice: 'League was successfully created.'
    else
      Rails.logger.warn "League creation failed for user #{current_user.id}: #{@league.errors.full_messages}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    Rails.logger.info "User #{current_user.id} editing league #{@league.id}"
  end

  def update
    Rails.logger.info "User #{current_user.id} updating league #{@league.id} with params: #{league_params}"
    
    if @league.update(league_params)
      Rails.logger.info "League #{@league.id} updated successfully"
      redirect_to @league, notice: 'League was successfully updated.'
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
    @recent_press_conferences = @league.press_conferences.recent.limit(5)
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
    unless membership&.admin?
      Rails.logger.warn "User #{current_user.id} attempted admin action on league #{@league.id} without admin rights"
      redirect_to @league, alert: 'You must be an admin to perform this action.'
    end
  end

  def league_params
    params.require(:league).permit(:name, :description, :sleeper_league_id, :season_year)
  end
end 