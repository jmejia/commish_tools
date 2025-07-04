require 'rails_helper'

RSpec.describe VoiceClonesController, type: :controller do
  let(:user) { create(:user) }
  let(:league) { create(:league, owner: user) }
  let(:league_membership) { create(:league_membership, league: league, user: user) }
  let(:other_user) { create(:user) }
  let(:other_league_membership) { create(:league_membership, league: league, user: other_user) }

  before do
    sign_in user
  end

  describe 'GET #show' do
    context 'with existing voice clone' do
      let!(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }

      it 'returns success' do
        get :show, params: { league_id: league.id, league_membership_id: league_membership.id, id: voice_clone.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:voice_clone)).to eq(voice_clone)
      end
    end

    context 'without existing voice clone' do
      it 'builds a new voice clone' do
        get :show, params: { league_id: league.id, league_membership_id: league_membership.id, id: 'new' }
        expect(response).to have_http_status(:success)
        expect(assigns(:voice_clone)).to be_a_new(VoiceClone)
      end
    end
  end

  describe 'GET #new' do
    context 'as league owner' do
      it 'returns success and builds voice clone' do
        get :new, params: { league_id: league.id, league_membership_id: league_membership.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:voice_clone)).to be_a_new(VoiceClone)
        expect(assigns(:voice_clone).league_membership).to eq(league_membership)
      end
    end

    context 'as non-league owner' do
      before do
        sign_in other_user
      end

      it 'redirects with error' do
        get :new, params: { league_id: league.id, league_membership_id: league_membership.id }
        expect(response).to redirect_to(league_path(league))
        expect(flash[:alert]).to include('Only the league owner')
      end
    end
  end

  describe 'POST #create' do
    let(:audio_file) { fixture_file_upload('spec/fixtures/sample.mp3', 'audio/mpeg') }
    let(:valid_params) do
      {
        league_id: league.id,
        league_membership_id: league_membership.id,
        voice_clone: { audio_file: audio_file }
      }
    end

    context 'as league owner with valid params' do
      it 'creates voice clone and enqueues job' do
        expect {
          post :create, params: valid_params
        }.to change(VoiceClone, :count).by(1)
          .and have_enqueued_job(VoiceProcessingJob)

        voice_clone = VoiceClone.last
        expect(voice_clone.league_membership).to eq(league_membership)
        expect(voice_clone.audio_file).to be_attached

        expect(response).to redirect_to(
          league_league_membership_voice_clone_path(league, league_membership, voice_clone)
        )
        expect(flash[:notice]).to include('uploaded successfully')
      end
    end

    context 'as league owner with invalid params' do
      let(:invalid_params) do
        {
          league_id: league.id,
          league_membership_id: league_membership.id,
          voice_clone: { audio_file: nil }
        }
      end

      it 'does not create voice clone' do
        expect {
          post :create, params: invalid_params
        }.not_to change(VoiceClone, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end

    context 'as non-league owner' do
      before do
        sign_in other_user
      end

      it 'redirects with error' do
        post :create, params: valid_params
        expect(response).to redirect_to(league_path(league))
        expect(flash[:alert]).to include('Only the league owner')
      end
    end
  end

  describe 'GET #edit' do
    let!(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }

    context 'as league owner' do
      it 'returns success' do
        get :edit, params: { league_id: league.id, league_membership_id: league_membership.id, id: voice_clone.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:voice_clone)).to eq(voice_clone)
      end
    end

    context 'as non-league owner' do
      before do
        sign_in other_user
      end

      it 'redirects with error' do
        get :edit, params: { league_id: league.id, league_membership_id: league_membership.id, id: voice_clone.id }
        expect(response).to redirect_to(league_path(league))
        expect(flash[:alert]).to include('Only the league owner')
      end
    end
  end

  describe 'PATCH #update' do
    let!(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }
    let(:new_audio_file) { fixture_file_upload('spec/fixtures/new_sample.wav', 'audio/wav') }
    let(:valid_params) do
      {
        league_id: league.id,
        league_membership_id: league_membership.id,
        id: voice_clone.id,
        voice_clone: { audio_file: new_audio_file }
      }
    end

    context 'as league owner with valid params' do
      it 'updates voice clone and enqueues job' do
        expect {
          patch :update, params: valid_params
        }.to have_enqueued_job(VoiceProcessingJob)

        voice_clone.reload
        expect(voice_clone.audio_file).to be_attached
        expect(voice_clone.audio_file.filename.to_s).to eq('new_sample.wav')

        expect(response).to redirect_to(
          league_league_membership_voice_clone_path(league, league_membership, voice_clone)
        )
        expect(flash[:notice]).to include('updated successfully')
      end
    end

    context 'as league owner with invalid params' do
      let(:invalid_params) do
        {
          league_id: league.id,
          league_membership_id: league_membership.id,
          id: voice_clone.id,
          voice_clone: { audio_file: fixture_file_upload('spec/fixtures/invalid.txt', 'text/plain') }
        }
      end

      it 'does not update voice clone' do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
      end
    end

    context 'as non-league owner' do
      before do
        sign_in other_user
      end

      it 'redirects with error' do
        patch :update, params: valid_params
        expect(response).to redirect_to(league_path(league))
        expect(flash[:alert]).to include('Only the league owner')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }

    context 'as league owner' do
      it 'destroys voice clone' do
        expect {
          delete :destroy, params: { league_id: league.id, league_membership_id: league_membership.id, id: voice_clone.id }
        }.to change(VoiceClone, :count).by(-1)

        expect(response).to redirect_to(league_path(league))
        expect(flash[:notice]).to include('deleted successfully')
      end
    end

    context 'as non-league owner' do
      before do
        sign_in other_user
      end

      it 'redirects with error' do
        delete :destroy, params: { league_id: league.id, league_membership_id: league_membership.id, id: voice_clone.id }
        expect(response).to redirect_to(league_path(league))
        expect(flash[:alert]).to include('Only the league owner')
      end
    end
  end

  describe 'authorization' do
    let(:unauthorized_user) { create(:user) }

    before do
      sign_in unauthorized_user
    end

    it 'prevents access to league membership not owned by user' do
      get :new, params: { league_id: league.id, league_membership_id: league_membership.id }
      expect(response).to redirect_to(league_path(league))
      expect(flash[:alert]).to include('Only the league owner')
    end
  end
end