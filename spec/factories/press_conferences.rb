FactoryBot.define do
  factory :press_conference do
    association :league
    association :target_manager, factory: :league_membership
    week_number { 1 }
    season_year { Date.current.year }
    status { :draft }
    context_data { nil }

    trait :with_questions do
      after(:create) do |press_conference|
        create_list(:press_conference_question, 3, press_conference: press_conference)
      end
    end

    trait :with_audio do
      status { :audio_complete }
      after(:create) do |press_conference|
        # Final audio will be attached in the test
      end
    end
  end
end
