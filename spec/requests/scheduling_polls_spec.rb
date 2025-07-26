require 'rails_helper'

RSpec.describe 'SchedulingPolls', type: :request do
  let(:user) { create(:user) }
  let(:league) { create(:league, owner: user) }
  let(:other_user) { create(:user) }

  before { sign_in user }

  describe 'GET /leagues/:league_id/scheduling_polls/new' do
    it 'returns a successful response' do
      get new_league_scheduling_poll_path(league)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Create Draft Scheduling Poll')
    end

    it 'redirects non-owners' do
      sign_in other_user
      get new_league_scheduling_poll_path(league)
      expect(response).to redirect_to(dashboard_league_path(league))
    end
  end

  describe 'POST /leagues/:league_id/scheduling_polls' do
    let(:valid_attributes) do
      {
        title: '2024 Draft Scheduling',
        description: 'Finding the best time for our draft',
        event_type: 'draft',
        event_time_slots_attributes: {
          '0' => { starts_at: 3.days.from_now, duration_minutes: 180 },
          '1' => { starts_at: 4.days.from_now, duration_minutes: 180 }
        }
      }
    end

    context 'with valid params' do
      it 'creates a new scheduling poll' do
        expect {
          post league_scheduling_polls_path(league), params: { scheduling_poll: valid_attributes }
        }.to change(SchedulingPoll, :count).by(1)
      end

      it 'creates associated time slots' do
        post league_scheduling_polls_path(league), params: { scheduling_poll: valid_attributes }
        poll = SchedulingPoll.last
        expect(poll.event_time_slots.count).to eq(2)
      end

      it 'redirects to the created poll' do
        post league_scheduling_polls_path(league), params: { scheduling_poll: valid_attributes }
        poll = SchedulingPoll.last
        expect(response).to redirect_to(league_scheduling_poll_path(league, poll))
      end
    end

    context 'with invalid params' do
      it 'does not create a poll without title' do
        invalid_attributes = valid_attributes.merge(title: '')
        expect {
          post league_scheduling_polls_path(league), params: { scheduling_poll: invalid_attributes }
        }.not_to change(SchedulingPoll, :count)
      end
    end
  end

  describe 'GET /leagues/:league_id/scheduling_polls/:id' do
    let(:poll) { create(:scheduling_poll, :with_responses, league: league) }

    it 'displays the poll and responses' do
      get league_scheduling_poll_path(league, poll)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(poll.title)
      expect(response.body).to include('Time Slot Options')
    end
  end
end