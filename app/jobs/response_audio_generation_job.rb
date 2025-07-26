# Generates audio for press conference responses using the team member's cloned voice
class ResponseAudioGenerationJob < ApplicationJob
  queue_as :default

  def perform(press_conference_response_id)
    response = PressConferenceResponse.find(press_conference_response_id)

    # Skip if audio already exists
    return if response.response_audio.attached?

    Rails.logger.info "Generating audio for response: #{response.id}"

    # Get the target manager and their voice clone
    press_conference = response.press_conference
    target_manager = press_conference.target_manager
    voice_clone = target_manager.voice_clone

    # Check if voice clone exists and is ready
    unless voice_clone&.playht_voice_id.present?
      Rails.logger.error "No voice clone available for user #{target_manager.user.id}"
      return
    end

    # Initialize PlayHT client
    client = PlayhtApiClient.new(
      user_id: ENV['PLAYHT_USER_ID'],
      api_key: ENV['PLAYHT_API_KEY']
    )

    # Generate audio using the cloned voice
    audio_data = client.generate_speech(
      text: response.response_text,
      voice: voice_clone.playht_voice_id,
      voice_engine: "Play3.0-mini", # Good balance of quality and speed for cloned voices
      output_format: "mp3",
      speed: 1.0,
      sample_rate: 24000
    )

    # Save audio to Active Storage
    save_audio_to_storage(response, audio_data)

    Rails.logger.info "Successfully generated audio for response: #{response.id}"

    # Check if all responses have audio and trigger final audio generation
    check_and_trigger_final_audio(press_conference)
  rescue StandardError => e
    Rails.logger.error "Failed to generate audio for response #{press_conference_response_id}: #{e.message}"
    raise # Re-raise to trigger retry
  end

  private

  def save_audio_to_storage(response, audio_data)
    # Create a temporary file
    temp_file = Tempfile.new(['response_audio', '.mp3'])
    temp_file.binmode
    temp_file.write(audio_data)
    temp_file.rewind

    # Attach to Active Storage
    response.response_audio.attach(
      io: temp_file,
      filename: "response_#{response.id}_audio.mp3",
      content_type: 'audio/mpeg'
    )

    # Store the URL for quick access (skip in development to avoid URL generation issues)
    unless Rails.env.development?
      response.update!(response_audio_url: response.response_audio.url)
    end
  ensure
    temp_file&.close
    temp_file&.unlink
  end

  def check_and_trigger_final_audio(press_conference)
    # Check if all questions and responses have audio
    all_questions_have_audio = press_conference.press_conference_questions.all? do |q|
      q.question_audio.attached?
    end

    all_responses_have_audio = press_conference.press_conference_questions.all? do |q|
      q.press_conference_response&.response_audio&.attached?
    end

    if all_questions_have_audio && all_responses_have_audio
      Rails.logger.info "All audio generated for press conference #{press_conference.id}, triggering final assembly"
      AudioStitchingJob.perform_later(press_conference.id)
    end
  end
end
