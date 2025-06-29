FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    first_name { "Test" }
    last_name { "User" }
    role { :league_owner }

    trait :with_sleeper do
      sleeper_username { "testuser123" }
      sleeper_id { "782008200219205632" }
    end

    trait :with_google_oauth do
      provider { "google_oauth2" }
      uid { "123456789" }
    end
  end
end
