FactoryBot.define do
  factory :draft_pick do
    association :draft
    association :user
    
    sleeper_player_id { "player_#{SecureRandom.hex(6)}" }
    sleeper_user_id { "user_#{SecureRandom.hex(6)}" }
    round { 1 }
    pick_number { 1 }
    overall_pick { 1 }
    player_name { "Test Player" }
    position { %w[QB RB WR TE DST K].sample }
    adp { rand(1.0..200.0).round(1) }
    projected_points { rand(50.0..350.0).round(1) }
    value_over_replacement { rand(-50.0..150.0).round(1) }
    metadata { {} }
  end
end