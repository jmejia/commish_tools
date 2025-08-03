# Manages scheduling polls for league events
# Allows commissioners to create and manage polls with time slots
class SchedulingPollsController < ApplicationController
  before_action :set_league
  before_action :ensure_league_member, only: [:index, :show]
  before_action :authorize_commissioner!, only: [:new, :create]
  before_action :set_poll, only: [:show, :edit, :update, :destroy, :close, :reopen, :export]
  before_action :authorize_poll_management!, only: [:edit, :update, :destroy, :close, :reopen, :export]

  def index
    @polls = @league.scheduling_polls.with_time_slots
  end

  def show
    @responses = @poll.scheduling_responses.includes(slot_availabilities: :event_time_slot)
  end

  def new
    @poll = @league.scheduling_polls.build(event_type: params[:event_type] || 'draft')
    3.times { @poll.event_time_slots.build }
  end

  def edit
  end

  def create
    result = SchedulingPoll.create_for_league(
      league: @league,
      created_by: current_user,
      params: poll_params
    )

    if result.success?
      redirect_to league_scheduling_poll_path(@league, result.poll),
                  notice: result.message
    else
      @poll = result.poll
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @poll.update(poll_params)
      redirect_to league_scheduling_poll_path(@league, @poll),
                  notice: 'Poll updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @poll.destroy!
    redirect_to dashboard_league_path(@league),
                notice: 'Poll deleted successfully.'
  end

  def close
    @poll.close!
    redirect_to league_scheduling_poll_path(@league, @poll),
                notice: 'Poll closed successfully.'
  end

  def reopen
    @poll.reopen!
    redirect_to league_scheduling_poll_path(@league, @poll),
                notice: 'Poll reopened successfully.'
  end

  def export
    respond_to do |format|
      format.csv do
        csv_data = @poll.to_csv
        send_data csv_data,
                  filename: "#{@poll.title.parameterize}-results-#{Date.current}.csv",
                  type: 'text/csv; charset=utf-8'
      end
    end
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_poll
    @poll = @league.scheduling_polls.find(params[:id])
  end

  def authorize_commissioner!
    membership = current_user.league_memberships.find_by(league: @league)
    unless membership&.owner?
      redirect_to dashboard_league_path(@league),
                  alert: 'You must be the league owner to create polls.'
    end
  end

  def ensure_league_member
    unless current_user.leagues.include?(@league) || @league.owner == current_user
      redirect_to leagues_path, alert: 'You are not a member of this league.'
    end
  end

  def authorize_poll_management!
    unless @poll.created_by == current_user || @league.owner == current_user
      redirect_to league_scheduling_poll_path(@league, @poll),
                  alert: 'You are not authorized to manage this poll.'
    end
  end

  def poll_params
    params.expect(
      scheduling_poll: [
        :event_type, :title, :description, :closes_at,
        event_time_slots_attributes: [:id, :starts_at, :duration_minutes, :_destroy],
      ]
    )
  end
end
