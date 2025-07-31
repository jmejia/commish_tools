# Handles draft grade generation and display for fantasy leagues
# Integrates with Sleeper API to import draft data and calculate grades
class DraftGradesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_league
  before_action :require_league_membership
  before_action :set_draft, only: [:index]
  before_action :set_draft_grade, only: [:show]

  def index
    @draft_grades = @league.draft_grades
                          .with_associations
                          .by_projected_rank
  end

  def show
    @draft_grade = @draft_grade.includes(:user, :league_membership)
  end

  def import
    sleeper_draft = SleeperDraft.new(@league)
    success = sleeper_draft.import_and_calculate_grades

    if success
      redirect_to league_draft_grades_path(@league),
                  notice: "Draft grades calculated successfully!"
    else
      redirect_to league_dashboard_path(@league),
                  alert: "No completed draft found for this league"
    end
  rescue => e
    Rails.logger.error "Draft import failed: #{e.message}"
    redirect_to league_dashboard_path(@league),
                alert: "Failed to import draft. Please try again."
  end

  private

  def set_league
    @league = League.includes(:drafts).find(params[:league_id])
  end

  def set_draft
    @draft = @league.drafts.completed.recent.first
  end

  def require_league_membership
    return if @league.owner == current_user

    unless @league.users.exists?(current_user.id)
      redirect_to leagues_path, alert: "You are not a member of this league"
    end
  end

  def set_draft_grade
    @draft_grade = @league.draft_grades
                          .includes(:draft, :user, :league_membership)
                          .find(params[:id])
  end
end

