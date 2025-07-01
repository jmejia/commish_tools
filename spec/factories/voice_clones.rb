FactoryBot.define do
  factory :voice_clone do
    association :league_membership
    playht_voice_id { "playht_#{SecureRandom.hex(8)}" }
    original_audio_url { "https://example.com/audio/sample.mp3" }
    status { :pending }
    upload_token { SecureRandom.urlsafe_base64(32) }

    trait :with_audio_file do
      after(:build) do |voice_clone|
        # Create a file that's at least 1MB for validation
        audio_content = "fake audio content" * 100000  # Approximately 1.9MB
        voice_clone.audio_file.attach(
          io: StringIO.new(audio_content),
          filename: "sample.mp3",
          content_type: "audio/mpeg"
        )
      end
    end

    trait :processing do
      status { :processing }
    end

    trait :ready do
      status { :ready }
      playht_voice_id { "playht_ready_#{SecureRandom.hex(8)}" }
    end

    trait :failed do
      status { :failed }
    end

    trait :without_audio_file do
      after(:build) do |voice_clone|
        voice_clone.audio_file.purge if voice_clone.audio_file.attached?
      end
    end
  end
end
