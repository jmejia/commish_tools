require 'rails_helper'

RSpec.describe 'PublicScheduling', type: :request do
  let(:league) { create(:league) }
  let(:poll) { create(:scheduling_poll, :with_time_slots, league: league) }

  describe 'GET /schedule/:token' do
    it 'displays the public scheduling form' do
      get public_scheduling_path(poll.public_token)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(poll.title)
      expect(response.body).to include('Submit Your Availability')
    end

    it 'returns 404 for invalid token' do
      get public_scheduling_path('invalid_token')
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 for closed poll' do
      poll.close!
      get public_scheduling_path(poll.public_token)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /schedule/:token' do
    let(:response_params) do
      {
        respondent_name: 'John Doe',
        form_start_time: 5.seconds.ago.iso8601, # Spam protection timing
        email_confirm: '', # Honeypot field (should be empty)
        availabilities: {
          poll.event_time_slots.first.id.to_s => '2',
          poll.event_time_slots.last.id.to_s => '0',
        },
      }
    end

    it 'creates a new response' do
      expect do
        post public_scheduling_path(poll.public_token), params: response_params
      end.to change(SchedulingResponse, :count).by(1)
    end

    it 'creates slot availabilities' do
      post public_scheduling_path(poll.public_token), params: response_params
      response = SchedulingResponse.last
      expect(response.slot_availabilities.count).to eq(2)
    end

    it 'redirects with success message' do
      post public_scheduling_path(poll.public_token), params: response_params
      expect(response).to redirect_to(public_scheduling_path(poll.public_token))
      follow_redirect!
      expect(response.body).to include('Your availability has been recorded!')
    end
  end

  describe 'PATCH /schedule/:token' do
    let!(:existing_response) do
      create(:scheduling_response,
             scheduling_poll: poll,
             respondent_name: 'John Doe',
             respondent_identifier: Digest::SHA256.hexdigest("john doe-#{poll.id}"))
    end

    let(:update_params) do
      {
        respondent_name: 'John Doe',
        form_start_time: 5.seconds.ago.iso8601, # Spam protection timing
        email_confirm: '', # Honeypot field (should be empty)
        availabilities: {
          poll.event_time_slots.first.id.to_s => '1',
          poll.event_time_slots.last.id.to_s => '2',
        },
      }
    end

    it 'updates existing response' do
      patch public_scheduling_path(poll.public_token), params: update_params
      expect(response).to redirect_to(public_scheduling_path(poll.public_token))
      follow_redirect!
      expect(response.body).to include('Your availability has been updated!')
    end
  end
end
