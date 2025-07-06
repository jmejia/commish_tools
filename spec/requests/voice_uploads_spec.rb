require 'rails_helper'

RSpec.describe "VoiceUploads", type: :request do
  let(:user) { create(:user) }
  let(:league_membership) { create(:league_membership, user: user) }
  let(:voice_clone) { create(:voice_clone, league_membership: league_membership) }
  let!(:link) { create(:voice_upload_link, voice_clone: voice_clone) }

  describe "GET /voice_uploads/:public_token" do
    it "renders the upload form" do
      get voice_upload_path(link.public_token)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /voice_uploads/:public_token" do
    let(:file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'large_sample.wav'), 'audio/wav') }

    it "updates the existing voice clone with the uploaded file" do
      expect {
        post voice_upload_path(link.public_token), params: { voice_clone: { original_audio: file } }
      }.not_to change(VoiceClone, :count)

      expect(voice_clone.reload.original_audio).to be_attached
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include("Voice sample uploaded successfully. Thank you!")
      expect(link.reload.upload_count).to eq(1)
    end
  end
end 