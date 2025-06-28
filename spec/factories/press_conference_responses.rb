FactoryBot.define do
  factory :press_conference_response do
    press_conference_question { nil }
    response_text { "MyText" }
    response_audio_url { "MyString" }
    generation_prompt { "MyText" }
  end
end
