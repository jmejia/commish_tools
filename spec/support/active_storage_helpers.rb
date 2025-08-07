module ActiveStorageHelpers
  def attach_test_audio(record, attachment_name, filename)
    # Create a minimal MP3 file for testing
    audio_content = Rails.root.join('spec', 'fixtures', 'sample.mp3').read

    record.public_send(attachment_name).attach(
      io: StringIO.new(audio_content),
      filename: filename,
      content_type: 'audio/mpeg'
    )
  end
end

RSpec.configure do |config|
  # Include Active Storage URL helpers in feature tests
  config.before(:each, type: :feature) do
    # Ensure Active Storage URL helpers are available
    ActiveStorage::Current.url_options = {
      host: 'localhost',
      port: 3000,
      protocol: 'http',
    }
  end

  # Include Active Storage URL helpers in views
  config.include ActiveStorage::Engine.routes.url_helpers, type: :feature

  # Include our custom helpers
  config.include ActiveStorageHelpers, type: :feature
end
