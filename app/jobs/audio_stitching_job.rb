# Stitches together question and response audio files for press conferences
# Creates a single final audio file using FFmpeg concatenation
class AudioStitchingJob < ApplicationJob
  queue_as :default

  def perform(press_conference_id)
    press_conference = PressConference.find(press_conference_id)

    Rails.logger.info "Starting audio stitching for press conference: #{press_conference.id}"

    # Validate all audio files are present
    unless all_audio_files_ready?(press_conference)
      Rails.logger.warn "Not all audio files ready for press conference #{press_conference.id}, skipping stitching"
      return
    end

    # Skip if final audio already exists and status is complete
    if press_conference.final_audio.attached? && press_conference.audio_complete?
      Rails.logger.info "Final audio already exists for press conference #{press_conference.id}"
      return
    end

    # If final audio exists but status isn't complete, update the status
    if press_conference.final_audio.attached? && !press_conference.audio_complete?
      Rails.logger.info "Final audio exists but status was #{press_conference.status}, updating to audio_complete"
      press_conference.update!(status: 'audio_complete')
      return
    end

    # Process audio stitching
    final_audio_path = AudioProcessor.stitch_press_conference(press_conference)

    # Save final audio to Active Storage
    save_final_audio(press_conference, final_audio_path)

    # Update press conference status
    press_conference.update!(status: 'audio_complete')

    Rails.logger.info "Successfully stitched audio for press conference: #{press_conference.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to stitch audio for press conference #{press_conference_id}: #{e.message}"
    press_conference&.update!(status: 'audio_failed')
    raise # Re-raise to trigger retry
  end

  private

  def all_audio_files_ready?(press_conference)
    questions_ready = press_conference.press_conference_questions.all? do |question|
      question.question_audio.attached?
    end

    responses_ready = press_conference.press_conference_questions.all? do |question|
      question.press_conference_response&.response_audio&.attached?
    end

    questions_ready && responses_ready
  end

  def save_final_audio(press_conference, audio_file_path)
    # Create filename for final audio
    filename = "press_conference_#{press_conference.id}_final_audio.mp3"

    # Attach to Active Storage
    File.open(audio_file_path, 'rb') do |file|
      press_conference.final_audio.attach(
        io: file,
        filename: filename,
        content_type: 'audio/mpeg'
      )
    end

    # Store the URL for quick access (skip in development to avoid URL generation issues)
    unless Rails.env.development?
      press_conference.update!(final_audio_url: press_conference.final_audio.url)
    end

    Rails.logger.info "Saved final audio: #{filename} (#{File.size(audio_file_path)} bytes)"
  ensure
    # Clean up temporary file
    File.unlink(audio_file_path) if audio_file_path && File.exist?(audio_file_path)
  end
end
