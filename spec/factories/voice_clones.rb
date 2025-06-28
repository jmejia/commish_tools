FactoryBot.define do
  factory :voice_clone do
    league_membership { nil }
    playht_voice_id { "MyString" }
    original_audio_url { "MyString" }
    status { 1 }
    upload_token { "MyString" }
  end
end
