FactoryBot.define do
  factory :press_conference_question do
    association :press_conference
    sequence(:question_text) { |n| "What do you think about question #{n}?" }
    question_audio_url { nil }
    playht_question_voice_id { nil }
    sequence(:order_index) { |n| n }

    trait :with_response do
      after(:create) do |question|
        create(:press_conference_response, press_conference_question: question)
      end
    end
  end
end
