require 'rails_helper'

RSpec.describe VoiceClone, type: :model do
  let(:league_membership) { create(:league_membership) }
  let(:voice_clone) { build(:voice_clone, league_membership: league_membership) }

  describe 'associations' do
    it 'belongs to league_membership' do
      expect(voice_clone).to respond_to(:league_membership)
    end

    it 'has user through league_membership' do
      expect(voice_clone).to respond_to(:user)
    end

    it 'has league through league_membership' do
      expect(voice_clone).to respond_to(:league)
    end

    it 'has one attached audio_file' do
      expect(voice_clone).to respond_to(:audio_file)
    end
  end

  describe 'validations' do
    it 'requires status' do
      voice_clone.status = nil
      expect(voice_clone).not_to be_valid
      expect(voice_clone.errors[:status]).to include("can't be blank")
    end

    it 'requires upload_token' do
      voice_clone.upload_token = nil
      expect(voice_clone).not_to be_valid
      expect(voice_clone.errors[:upload_token]).to include("can't be blank")
    end

    it 'requires unique upload_token' do
      existing = create(:voice_clone, :with_audio_file, league_membership: create(:league_membership))
      voice_clone.upload_token = existing.upload_token
      expect(voice_clone).not_to be_valid
      expect(voice_clone.errors[:upload_token]).to include("has already been taken")
    end

    it 'requires unique league_membership_id' do
      existing = create(:voice_clone, :with_audio_file, league_membership: league_membership)
      new_clone = build(:voice_clone, league_membership: league_membership)
      expect(new_clone).not_to be_valid
      expect(new_clone.errors[:league_membership_id]).to include("has already been taken")
    end

    context 'with audio file' do
      let(:voice_clone) { build(:voice_clone, :with_audio_file, league_membership: league_membership) }

      it 'is valid with a valid audio file' do
        expect(voice_clone).to be_valid
      end

      it 'validates content type' do
        voice_clone.audio_file.attach(
          io: StringIO.new("fake content"),
          filename: "test.txt",
          content_type: "text/plain"
        )
        expect(voice_clone).not_to be_valid
        expect(voice_clone.errors[:audio_file]).to include(/must be an audio file/)
      end

      it 'validates file size' do
        # Test file too small
        voice_clone.audio_file.attach(
          io: StringIO.new("small"),
          filename: "small.mp3",
          content_type: "audio/mpeg"
        )
        expect(voice_clone).not_to be_valid
        expect(voice_clone.errors[:audio_file]).to include(/must be at least 1MB/)
      end
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(VoiceClone.statuses).to eq({
        'pending' => 0,
        'processing' => 1,
        'ready' => 2,
        'failed' => 3
      })
    end
  end

  describe 'scopes' do
    let!(:pending_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }
    let!(:ready_clone) { create(:voice_clone, :ready, :with_audio_file, league_membership: create(:league_membership)) }
    let!(:failed_clone) { create(:voice_clone, :failed, :with_audio_file, league_membership: create(:league_membership)) }

    describe '.ready_for_use' do
      it 'returns only ready voice clones' do
        expect(VoiceClone.ready_for_use).to contain_exactly(ready_clone)
      end
    end

    describe '.for_league' do
      it 'returns voice clones for a specific league' do
        league = league_membership.league
        expect(VoiceClone.for_league(league)).to contain_exactly(pending_clone)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_create :generate_upload_token' do
      it 'generates an upload token before creation' do
        voice_clone = build(:voice_clone, league_membership: league_membership)
        voice_clone.upload_token = nil  # Set after build to bypass factory default
        voice_clone.save!(validate: false)  # Skip validation to test callback
        voice_clone.reload
        expect(voice_clone.upload_token).to be_present
        expect(voice_clone.upload_token.length).to be >= 32
      end

      it 'does not override existing upload token' do
        existing_token = 'existing_token_123'
        voice_clone = build(:voice_clone, league_membership: league_membership, upload_token: existing_token)
        voice_clone.save!
        expect(voice_clone.upload_token).to eq(existing_token)
      end
    end
  end

  describe '#ready_for_playht?' do
    context 'when ready and has playht_voice_id' do
      let(:voice_clone) { create(:voice_clone, :ready, :with_audio_file, league_membership: league_membership) }

      it 'returns true' do
        expect(voice_clone.ready_for_playht?).to be true
      end
    end

    context 'when ready but no playht_voice_id' do
      let(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }

      before { voice_clone.update!(status: :ready, playht_voice_id: nil) }

      it 'returns false' do
        expect(voice_clone.ready_for_playht?).to be false
      end
    end

    context 'when not ready' do
      let(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }

      it 'returns false' do
        expect(voice_clone.ready_for_playht?).to be false
      end
    end
  end

  describe '#audio_file_name' do
    context 'with attached audio file' do
      let(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership) }

      it 'returns the filename' do
        expect(voice_clone.audio_file_name).to eq('sample.mp3')
      end
    end

    context 'with original_audio_url' do
      let(:voice_clone) { create(:voice_clone, league_membership: league_membership, original_audio_url: 'https://example.com/path/audio.wav') }

      it 'returns the basename from URL' do
        expect(voice_clone.audio_file_name).to eq('audio.wav')
      end
    end

    context 'without audio file or URL' do
      let(:voice_clone) { build(:voice_clone, :without_audio_file, league_membership: league_membership, original_audio_url: nil) }

      it 'returns nil' do
        expect(voice_clone.audio_file_name).to be_nil
      end
    end
  end

  describe '#user_display_name' do
    it 'delegates to league_membership display_name' do
      expect(voice_clone.user_display_name).to eq(league_membership.display_name)
    end
  end
end
