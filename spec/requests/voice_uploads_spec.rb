require 'rails_helper'

RSpec.describe "VoiceUploads", type: :request do
  let(:user) { create(:user) }
  let(:league_membership) { create(:league_membership, user: user) }
  let(:voice_clone) { create(:voice_clone, league_membership: league_membership) }
  let!(:link) { create(:voice_upload_link, voice_clone: voice_clone) }

  describe "GET /voice_uploads/:token" do
    it "renders the upload form" do
      get voice_upload_path(token: link.public_token)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /voice_uploads/:token" do
    let(:file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'large_sample.wav'), 'audio/wav') }

    it "updates the existing voice clone with the uploaded file" do
      expect do
        post voice_upload_path(token: link.public_token), params: { voice_clone: { audio_file: file } }
      end.not_to change(VoiceClone, :count)

      expect(voice_clone.reload.audio_file).to be_attached
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include("Voice sample uploaded successfully. Thank you!")
      expect(link.reload.upload_count).to eq(1)
    end
  end
end
