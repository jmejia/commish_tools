FactoryBot.define do
  factory :league_membership do
    association :league
    association :user
    sleeper_user_id { "MyString" }
    team_name { "MyString" }
    role { 1 }
  end
end
