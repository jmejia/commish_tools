FactoryBot.define do
  factory :league do
    sleeper_league_id { "MyString" }
    name { "MyString" }
    season_year { 1 }
    settings { "" }
    owner { nil }
  end
end
