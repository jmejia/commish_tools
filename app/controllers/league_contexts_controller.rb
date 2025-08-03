# Manages league context editing for league owners
class LeagueContextsController < ApplicationController
  before_action :set_league
  before_action :ensure_league_owner

  def edit
    Rails.logger.info "User #{current_user.id} editing context for league #{@league.id}"
    @league_context = @league.league_context || @league.build_league_context
  end

  def update
    Rails.logger.info "User #{current_user.id} updating context for league #{@league.id}"
    @league_context = @league.league_context || @league.build_league_context

    if @league_context.update(league_context_params)
      redirect_to dashboard_league_path(@league), notice: 'League context updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_league
    @league = League.find(params[:league_id])
    Rails.logger.info "Set league #{@league.id} for context action"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "League not found with id: #{params[:league_id]}"
    redirect_to leagues_path, alert: 'League not found.'
  end

  def ensure_league_owner
    membership = current_user.league_memberships.find_by(league: @league)
    unless membership&.owner?
      Rails.logger.warn "User #{current_user.id} attempted to edit context for league #{@league.id} without owner rights"
      redirect_to dashboard_league_path(@league), alert: 'You must be the league owner to edit league context.'
    end
  end

  def league_context_params
    params.expect(league_context: [:nature, :tone, :rivalries, :history, :response_style])
  end
end
