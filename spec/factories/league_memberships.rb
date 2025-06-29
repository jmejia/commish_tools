FactoryBot.define do
  factory :league_membership do
    association :league
    association :user
    sleeper_user_id { "782008200219205632" }
    team_name { "Test Team" }
    role { :manager }
    
    trait :owner do
      role { :owner }
    end
    
    trait :manager do
      role { :manager }
    end
  end
end
