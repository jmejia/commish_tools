class VoiceProcessingJob < ApplicationJob
  queue_as :default

  def perform(voice_clone_id)
    voice_clone = VoiceClone.find(voice_clone_id)
    voice_clone.update!(status: :processing)

    begin
      # Process the audio file and upload to PlayHT
      process_audio_file(voice_clone)

      # Update status to ready once successful
      voice_clone.update!(status: :ready)

      # TODO: Send notification email to user
      # VoiceProcessingMailer.processing_complete(voice_clone).deliver_now

    rescue StandardError => e
      Rails.logger.error "Voice processing failed for VoiceClone #{voice_clone_id}: #{e.message}"
      voice_clone.update!(status: :failed)

      # TODO: Send failure notification email
      # VoiceProcessingMailer.processing_failed(voice_clone, e.message).deliver_now

      raise e
    end
  end

  private

  def process_audio_file(voice_clone)
    return unless voice_clone.audio_file.attached?

    # Download the audio file to a temporary location for processing
    audio_file = voice_clone.audio_file
    temp_file = download_to_temp_file(audio_file)

    begin
      # TODO: Implement PlayHT API integration
      # This will be extracted to a gem similar to sleeper_ff pattern
      playht_voice_id = upload_to_playht(temp_file, voice_clone)

      # Store the PlayHT voice ID and original audio URL
      voice_clone.update!(
        playht_voice_id: playht_voice_id,
        original_audio_url: rails_blob_url(audio_file)
      )

    ensure
      # Clean up temporary file
      temp_file.close
      temp_file.unlink
    end
  end

  def download_to_temp_file(audio_file)
    temp_file = Tempfile.new(['voice_sample', File.extname(audio_file.filename.to_s)])
    temp_file.binmode

    audio_file.download do |chunk|
      temp_file.write(chunk)
    end

    temp_file.rewind
    temp_file
  end

  def upload_to_playht(temp_file, voice_clone)
    api_client = PlayhtApiClient.new(
      user_id: ENV['PLAYHT_USER_ID'],
      api_key: ENV['PLAYHT_API_KEY']
    )

    response = api_client.create_voice_clone_from_upload(
      file_path: temp_file.path,
      voice_name: "voice_clone_#{voice_clone.id}_#{Time.now.to_i}"
    )

    if response && response["id"]
      response["id"]
    else
      Rails.logger.error "Failed to get PlayHT voice ID from response: #{response.inspect}"
      raise "Failed to create PlayHT voice clone."
    end
  rescue PlayhtApiClient::Error => e
    Rails.logger.error "PlayHT API error for VoiceClone #{voice_clone.id}: #{e.message}"
    raise "PlayHT API error: #{e.message}"
  end

  def rails_blob_url(attachment)
    Rails.application.routes.url_helpers.rails_blob_url(attachment,
      host: Rails.application.config.action_mailer.default_url_options[:host])
  end
end
