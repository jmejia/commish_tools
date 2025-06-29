require 'rails_helper'

describe LeaguesController, type: :controller do
  let(:user) { create(:user) }
  let(:league) { create(:league) }
  let!(:membership) { create(:league_membership, user: user, league: league, role: :admin) }

  before { sign_in user }

  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      expect(response).to be_successful
      expect(assigns(:leagues)).to include(league)
    end
  end

  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'creates a new league and redirects' do
      expect {
        post :create, params: { league: { name: 'Test League', description: 'desc', season_year: 2025 } }
      }.to change(League, :count).by(1)
      expect(response).to redirect_to(League.last)
    end
  end

  describe 'GET #show' do
    it 'renders the show template' do
      get :show, params: { id: league.id }
      expect(response).to be_successful
    end
  end

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit, params: { id: league.id }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    it 'updates the league and redirects' do
      patch :update, params: { id: league.id, league: { name: 'Updated' } }
      expect(response).to redirect_to(league)
      expect(league.reload.name).to eq('Updated')
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the league and redirects' do
      expect {
        delete :destroy, params: { id: league.id }
      }.to change(League, :count).by(-1)
      expect(response).to redirect_to(leagues_path)
    end
  end

  describe 'GET #dashboard' do
    it 'renders the dashboard template' do
      get :dashboard, params: { id: league.id }
      expect(response).to be_successful
    end
  end
end 