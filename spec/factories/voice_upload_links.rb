FactoryBot.define do
  factory :voice_upload_link do
    association :voice_clone, factory: :voice_clone
    title { "Upload for John Doe" }
    instructions { "Please upload a clear audio sample." }
    public_token { SecureRandom.uuid }
    active { true }
    max_uploads { 1 }
    upload_count { 0 }
  end
end
