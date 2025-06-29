FactoryBot.define do
  factory :league do
    sequence(:sleeper_league_id) { |n| "league_id_#{n}" }
    sequence(:name) { |n| "Test League #{n}" }
    season_year { Date.current.year }
    settings { { scoring_settings: { pass_td: 4, rush_td: 6 } } }
    association :owner, factory: :user
    
    trait :with_sleeper_id do
      sleeper_league_id { "1243642178488520704" }
    end
    
    trait :current_season do
      season_year { Date.current.year }
    end
    
    trait :last_season do
      season_year { Date.current.year - 1 }
    end
  end
end
