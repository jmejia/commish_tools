FactoryBot.define do
  factory :press_conference_question do
    press_conference { nil }
    question_text { "MyText" }
    question_audio_url { "MyString" }
    playht_question_voice_id { "MyString" }
    order_index { 1 }
  end
end
