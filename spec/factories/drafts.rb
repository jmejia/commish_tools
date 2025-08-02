FactoryBot.define do
  factory :draft do
    association :league
    
    sleeper_draft_id { "draft_#{SecureRandom.hex(8)}" }
    status { 'completed' }
    season_year { Date.current.year }
    draft_type { 'snake' }
    league_size { 12 }
    settings { {} }
    started_at { 1.week.ago }
    completed_at { 1.week.ago + 3.hours }
  end
end