require 'rails_helper'

describe LeaguesController, type: :request do
  let(:user) { create(:user) }
  let(:league) { create(:league) }
  let!(:membership) { create(:league_membership, user: user, league: league, role: :owner) }

  before { sign_in user }

  describe 'GET /leagues' do
    it 'renders the index template' do
      get leagues_path
      expect(response).to be_successful
    end
  end

  describe 'GET /leagues/new' do
    context 'when user has no sleeper account connected' do
      it 'redirects to connect sleeper page' do
        get new_league_path
        expect(response).to redirect_to(connect_sleeper_path)
      end
    end

    context 'when user has sleeper account connected' do
      before { user.update!(sleeper_id: '123456') }
      
      it 'redirects to select sleeper leagues page' do
        get new_league_path
        expect(response).to redirect_to(select_sleeper_leagues_path)
      end
    end
  end

  describe 'POST /leagues' do
    it 'creates a new league and redirects' do
      expect {
        post leagues_path, params: { league: { name: 'Test League', season_year: 2025, sleeper_league_id: '123456' } }
      }.to change(League, :count).by(1)
      expect(response).to redirect_to(League.last)
    end
  end

  describe 'GET /leagues/:id' do
    it 'renders the show template' do
      get league_path(league)
      expect(response).to be_successful
    end
  end

  describe 'GET /leagues/:id/edit' do
    it 'renders the edit template' do
      get edit_league_path(league)
      expect(response).to be_successful
    end
  end

  describe 'PATCH /leagues/:id' do
    it 'updates the league and redirects' do
      patch league_path(league), params: { league: { name: 'Updated' } }
      expect(response).to redirect_to(league)
      expect(league.reload.name).to eq('Updated')
    end
  end

  describe 'DELETE /leagues/:id' do
    it 'destroys the league and redirects' do
      expect {
        delete league_path(league)
      }.to change(League, :count).by(-1)
      expect(response).to redirect_to(leagues_path)
    end
  end

  describe 'GET /leagues/:id/dashboard' do
    it 'renders the dashboard template' do
      get league_dashboard_path(league)
      expect(response).to be_successful
    end
  end
end 