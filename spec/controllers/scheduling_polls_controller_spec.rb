require 'rails_helper'

RSpec.describe SchedulingPollsController, type: :controller do
  let(:user) { create(:user) }
  let(:league) { create(:league, owner: user) }
  let(:other_user) { create(:user) }

  before { sign_in user }

  describe 'GET #new' do
    it 'assigns a new poll with default event type' do
      get :new, params: { league_id: league.id }
      expect(response).to have_http_status(:success)
    end

    it 'builds 3 time slots by default' do
      get :new, params: { league_id: league.id }
      expect(response).to have_http_status(:success)
    end

    it 'redirects non-owners' do
      sign_in other_user
      get :new, params: { league_id: league.id }
      expect(response).to redirect_to(dashboard_league_path(league))
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: '2024 Draft Scheduling',
        description: 'Finding the best time for our draft',
        event_type: 'draft',
        event_time_slots_attributes: {
          '0' => { starts_at: 3.days.from_now, duration_minutes: 180 },
          '1' => { starts_at: 4.days.from_now, duration_minutes: 180 },
        },
      }
    end

    context 'with valid params' do
      it 'creates a new scheduling poll' do
        expect do
          post :create, params: { league_id: league.id, scheduling_poll: valid_attributes }
        end.to change(SchedulingPoll, :count).by(1)
      end

      it 'creates associated time slots' do
        post :create, params: { league_id: league.id, scheduling_poll: valid_attributes }
        poll = SchedulingPoll.last
        expect(poll.event_time_slots.count).to eq(2)
      end

      it 'redirects to the created poll' do
        post :create, params: { league_id: league.id, scheduling_poll: valid_attributes }
        poll = SchedulingPoll.last
        expect(response).to redirect_to(league_scheduling_poll_path(league, poll))
        expect(flash[:notice]).to be_present
      end
    end

    context 'with invalid params' do
      it 'does not create a poll with invalid event type' do
        invalid_attributes = valid_attributes.merge(event_type: 'invalid_type')
        expect do
          post :create, params: { league_id: league.id, scheduling_poll: invalid_attributes }
        end.not_to change(SchedulingPoll, :count)
      end

      it 're-renders the new template' do
        invalid_attributes = valid_attributes.merge(event_type: 'invalid_type')
        post :create, params: { league_id: league.id, scheduling_poll: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'prevents non-owners from creating polls' do
      sign_in other_user
      post :create, params: { league_id: league.id, scheduling_poll: valid_attributes }
      expect(response).to redirect_to(dashboard_league_path(league))
      expect(SchedulingPoll.count).to eq(0)
    end
  end

  describe 'GET #show' do
    let(:poll) { create(:scheduling_poll, :with_responses, league: league) }

    it 'displays the poll and responses' do
      get :show, params: { league_id: league.id, id: poll.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH #close' do
    let(:poll) { create(:scheduling_poll, league: league, created_by: user) }

    it 'closes an active poll' do
      patch :close, params: { league_id: league.id, id: poll.id }
      expect(poll.reload).to be_closed
      expect(response).to redirect_to(league_scheduling_poll_path(league, poll))
    end
  end

  describe 'PATCH #reopen' do
    let(:poll) { create(:scheduling_poll, :closed, league: league, created_by: user) }

    it 'reopens a closed poll' do
      patch :reopen, params: { league_id: league.id, id: poll.id }
      expect(poll.reload).to be_active
      expect(response).to redirect_to(league_scheduling_poll_path(league, poll))
    end
  end
end
