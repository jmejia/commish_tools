# Generates audio for press conference questions using PlayHT's TTS API
# Uses a generic announcer voice for all questions
class QuestionAudioGenerationJob < ApplicationJob
  queue_as :default

  # Pre-selected PlayHT voices for different announcer styles
  ANNOUNCER_VOICES = {
    professional_male: "s3://voice-cloning-zero-shot/9f1ee23a-9108-4538-90be-8e62efc195b6/charlessaad/manifest.json", # Charles
    professional_female: "s3://voice-cloning-zero-shot/1afba232-fae0-4b69-9675-7f1aac69349f/delilahsaad/manifest.json", # Delilah
    energetic_male: "s3://voice-cloning-zero-shot/b41d1a8c-2c99-4403-8262-5808bc67c3e0/bentonsaad/manifest.json", # Benton
    news_anchor: "s3://voice-cloning-zero-shot/36e9c53d-ca4e-4815-b5ed-9732be3839b4/samuelsaad/manifest.json", # Samuel
  }.freeze

  def perform(press_conference_question_id)
    question = PressConferenceQuestion.find(press_conference_question_id)

    # Skip if audio already exists
    return if question.question_audio.attached?

    Rails.logger.info "Generating audio for question: #{question.id}"

    # Initialize PlayHT client
    client = PlayhtApiClient.new(
      user_id: ENV['PLAYHT_USER_ID'],
      api_key: ENV['PLAYHT_API_KEY']
    )

    # Generate audio using a professional announcer voice
    audio_data = client.generate_speech(
      text: question.question_text,
      voice: select_announcer_voice,
      voice_engine: "PlayDialog", # Higher quality for announcer
      output_format: "mp3",
      speed: 0.95, # Slightly slower for clarity
      sample_rate: 44100 # Higher quality
    )

    # Save audio to Active Storage
    save_audio_to_storage(question, audio_data)

    Rails.logger.info "Successfully generated audio for question: #{question.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to generate audio for question #{press_conference_question_id}: #{e.message}"
    raise # Re-raise to trigger retry
  end

  private

  def select_announcer_voice
    # Rotate through different voices or use a consistent one
    # For now, use the professional male voice
    ANNOUNCER_VOICES[:professional_male]
  end

  def save_audio_to_storage(question, audio_data)
    # Create a temporary file
    temp_file = Tempfile.new(['question_audio', '.mp3'])
    temp_file.binmode
    temp_file.write(audio_data)
    temp_file.rewind

    # Attach to Active Storage
    question.question_audio.attach(
      io: temp_file,
      filename: "question_#{question.id}_audio.mp3",
      content_type: 'audio/mpeg'
    )

    # Store the URL for quick access (skip in development to avoid URL generation issues)
    unless Rails.env.development?
      question.update!(question_audio_url: question.question_audio.url)
    end
  ensure
    temp_file&.close
    temp_file&.unlink
  end
end
