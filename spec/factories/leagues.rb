FactoryBot.define do
  factory :league do
    sleeper_league_id { "MyString" }
    name { "MyString" }
    season_year { 2025 }
    settings { "" }
    association :owner, factory: :user
  end
end
