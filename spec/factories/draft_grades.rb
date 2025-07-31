FactoryBot.define do
  factory :draft_grade do
    association :league
    association :user
    
    grade { %w[A+ A A- B+ B B- C+ C C- D+ D D- F].sample }
    projected_rank { rand(1..12) }
    projected_points { rand(1200.0..1600.0).round(2) }
    projected_wins { rand(4.0..10.0).round(1) }
    playoff_probability { rand(0.2..0.9).round(2) }
    
    position_grades do
      {
        'QB' => %w[A B C D F].sample,
        'RB' => %w[A B C D F].sample,
        'WR' => %w[A B C D F].sample,
        'TE' => %w[A B C D F].sample
      }
    end
    
    best_picks do
      [
        {
          'player_name' => 'Justin Jefferson',
          'position' => 'WR',
          'round' => 2,
          'pick' => 3,
          'reach_value' => 15
        }
      ]
    end
    
    worst_picks do
      [
        {
          'player_name' => 'Some Reach',
          'position' => 'RB',
          'round' => 3,
          'pick' => 7,
          'reach_value' => -12
        }
      ]
    end
    
    analysis do
      {
        'summary' => 'Solid playoff team with good upside',
        'strengths' => ['Elite WR depth', 'Strong QB play'],
        'weaknesses' => ['Weak RB depth']
      }
    end
    
    draft_id { "draft_#{SecureRandom.hex(8)}" }
    calculated_at { 1.day.ago }
  end
end