require 'rails_helper'

RSpec.describe 'Voice Clone Management', type: :feature, js: true do
  include Rails.application.routes.url_helpers
  let(:user) { create(:user) }
  let(:league) { create(:league, owner: user) }
  let!(:membership) { create(:league_membership, user: user, league: league, role: :owner) }

  before do
    login_as user, scope: :user
  end

  describe 'Creating a new voice clone' do
    it 'allows a league owner to upload a voice sample' do # , :pending, "Fails due to ActiveStorage URL helper issue in show view" do
      visit dashboard_league_path(league)

      click_link '🎤 Voice Clone Settings'

      expect(page).to have_current_path(new_league_league_membership_voice_clone_path(league, membership))
      expect(page).to have_content('Upload Voice Sample')

      expect do
        attach_file('audio-file-input', Rails.root.join('spec/fixtures/sample_large.mp3'), make_visible: true)
        page.execute_script("document.getElementById('voice-upload-form').submit()")

        # Wait for the page to process the submission
        expect(page).to have_content('Voice sample uploaded successfully and is being processed.')
      end.to change(VoiceClone, :count).by(1).and have_enqueued_job(VoiceProcessingJob)

      voice_clone = VoiceClone.last
      expect(voice_clone.league_membership).to eq(membership)
      expect(page).to have_current_path(league_league_membership_voice_clone_path(league, membership, voice_clone))
      expect(page).to have_content('Processing')
    end
  end

  describe 'Editing an existing voice clone' do
    let!(:voice_clone) { create(:voice_clone, league_membership: membership) }

    xit 'allows a league owner to upload a new voice sample' do
      visit edit_league_league_membership_voice_clone_path(league, membership, voice_clone)

      attach_file('voice_clone[audio_file]', Rails.root.join('spec/fixtures/sample_large.mp3'), make_visible: true)

      expect do
        click_button 'Update Voice Sample'
      end.to have_enqueued_job(VoiceProcessingJob)

      expect(page).to have_current_path(league_league_membership_voice_clone_path(league, membership, voice_clone))
      expect(page).to have_content('Voice sample updated successfully and is being processed.')
    end
  end
end
