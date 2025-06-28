FactoryBot.define do
  factory :league_membership do
    league { nil }
    user { nil }
    sleeper_user_id { "MyString" }
    team_name { "MyString" }
    role { 1 }
  end
end
