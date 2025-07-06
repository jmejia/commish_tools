require 'rails_helper'

RSpec.describe VoiceProcessingJob, type: :job do
  let(:league_membership) { create(:league_membership) }
  let(:voice_clone) { create(:voice_clone, :with_audio_file, league_membership: league_membership, status: :pending) }

  describe '#perform' do
    subject { described_class.new.perform(voice_clone.id) }

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'with successful processing' do
      before do
        allow_any_instance_of(described_class).to receive(:upload_to_playht).and_return('playht_voice_123')
        allow_any_instance_of(described_class).to receive(:rails_blob_url).and_return('https://example.com/audio.mp3')
      end

      it 'updates voice clone status to processing then ready' do
        expect { subject }.to change { voice_clone.reload.status }.from('pending').to('ready')
      end

      it 'sets playht_voice_id and original_audio_url' do
        subject
        voice_clone.reload
        expect(voice_clone.playht_voice_id).to eq('playht_voice_123')
        expect(voice_clone.original_audio_url).to eq('https://example.com/audio.mp3')
      end

      it 'sets status to processing during execution' do
        allow_any_instance_of(described_class).to receive(:process_audio_file) do
          expect(voice_clone.reload.status).to eq('processing')
        end
        subject
      end
    end

    context 'with processing failure' do
      let(:error_message) { 'PlayHT API error' }

      before do
        allow_any_instance_of(described_class).to receive(:process_audio_file).and_raise(StandardError.new(error_message))
      end

      it 'updates status to failed' do
        expect do
          subject
        rescue
          nil
        end.to change { voice_clone.reload.status }.from('pending').to('failed')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Voice processing failed for VoiceClone #{voice_clone.id}/)
        expect { subject }.to raise_error(StandardError, error_message)
      end

      it 're-raises the error' do
        expect { subject }.to raise_error(StandardError, error_message)
      end
    end

    context 'without attached audio file' do
      let(:voice_clone) { create(:voice_clone, league_membership: league_membership, status: :pending) }

      before do
        allow_any_instance_of(described_class).to receive(:upload_to_playht).and_return('playht_voice_123')
      end

      it 'completes successfully without processing' do
        expect { subject }.to change { voice_clone.reload.status }.from('pending').to('ready')
      end

      it 'does not call upload_to_playht' do
        expect_any_instance_of(described_class).not_to receive(:upload_to_playht)
        subject
      end
    end
  end

  describe '#process_audio_file' do
    let(:job) { described_class.new }
    let(:temp_file) { double('temp_file') }

    before do
      allow(job).to receive(:download_to_temp_file).and_return(temp_file)
      allow(job).to receive(:upload_to_playht).and_return('playht_voice_456')
      allow(job).to receive(:rails_blob_url).and_return('https://example.com/blob.mp3')
      allow(temp_file).to receive(:close)
      allow(temp_file).to receive(:unlink)
    end

    it 'downloads file to temp location' do
      expect(job).to receive(:download_to_temp_file).with(voice_clone.audio_file)
      job.send(:process_audio_file, voice_clone)
    end

    it 'uploads to PlayHT' do
      expect(job).to receive(:upload_to_playht).with(temp_file, voice_clone)
      job.send(:process_audio_file, voice_clone)
    end

    it 'updates voice clone with PlayHT data' do
      job.send(:process_audio_file, voice_clone)
      voice_clone.reload
      expect(voice_clone.playht_voice_id).to eq('playht_voice_456')
      expect(voice_clone.original_audio_url).to eq('https://example.com/blob.mp3')
    end

    it 'cleans up temp file' do
      expect(temp_file).to receive(:close)
      expect(temp_file).to receive(:unlink)
      job.send(:process_audio_file, voice_clone)
    end

    it 'cleans up temp file even on error' do
      allow(job).to receive(:upload_to_playht).and_raise(StandardError.new('API error'))
      expect(temp_file).to receive(:close)
      expect(temp_file).to receive(:unlink)

      expect { job.send(:process_audio_file, voice_clone) }.to raise_error(StandardError)
    end
  end

  describe '#download_to_temp_file' do
    let(:job) { described_class.new }
    let(:audio_file) { voice_clone.audio_file }
    let(:temp_file) { job.send(:download_to_temp_file, audio_file) }

    after do
      temp_file&.close
      temp_file&.unlink
    end

    it 'creates a temporary file with correct extension' do
      expect(temp_file.path).to end_with('.mp3')
    end

    it 'sets binary mode' do
      expect(temp_file.binmode?).to be true
    end

    it 'downloads file content' do
      content = temp_file.read
      expect(content).to eq('fake audio content' * 100000)
    end

    it 'rewinds file pointer' do
      expect(temp_file.pos).to eq(0)
    end
  end

  describe '#upload_to_playht' do
    let(:job) { described_class.new }
    let(:temp_file) { double('temp_file', path: '/tmp/fake_file.mp3') }
    let(:api_client) { instance_double(PlayhtApiClient) }

    before do
      # Stub the PlayhtApiClient to avoid actual API calls
      allow(PlayhtApiClient).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:create_voice_clone_from_upload).and_return({ "id" => "playht_voice_123" })
    end

    it 'calls the api client with the correct parameters' do
      expect(api_client).to receive(:create_voice_clone_from_upload).with(
        hash_including(file_path: '/tmp/fake_file.mp3')
      )
      job.send(:upload_to_playht, temp_file, voice_clone)
    end

    it 'returns the voice id' do
      voice_id = job.send(:upload_to_playht, temp_file, voice_clone)
      expect(voice_id).to eq('playht_voice_123')
    end

    context 'when api returns an error' do
      before do
        allow(api_client).to receive(:create_voice_clone_from_upload).and_raise(PlayhtApiClient::Error.new("some error"))
      end

      it 'raises a runtime error with a specific message' do
        expect do
          job.send(:upload_to_playht, temp_file, voice_clone)
        end.to raise_error(RuntimeError, "PlayHT API error: some error")
      end
    end

    context 'when the response does not contain an id' do
      before do
        allow(api_client).to receive(:create_voice_clone_from_upload).and_return({ "error" => "something bad" })
      end

      it 'raises a runtime error' do
        expect do
          job.send(:upload_to_playht, temp_file, voice_clone)
        end.to raise_error(RuntimeError, "Failed to create PlayHT voice clone.")
      end
    end
  end

  describe '#rails_blob_url' do
    let(:job) { described_class.new }
    let(:attachment) { voice_clone.audio_file }

    before do
      allow(Rails.application.routes.url_helpers).to receive(:rails_blob_url).and_return('https://example.com/blob/123')
      allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return({ host: 'example.com' })
    end

    it 'generates blob URL with correct host' do
      url = job.send(:rails_blob_url, attachment)
      expect(url).to eq('https://example.com/blob/123')
    end

    it 'passes attachment and host to url helper' do
      expect(Rails.application.routes.url_helpers).to receive(:rails_blob_url).
        with(attachment, host: 'example.com')
      job.send(:rails_blob_url, attachment)
    end
  end

  describe 'job queue' do
    it 'is queued on default queue' do
      expect(described_class.queue_name).to eq('default')
    end
  end
end
