FactoryBot.define do
  factory :press_conference do
    league { nil }
    target_manager { nil }
    week_number { 1 }
    season_year { Date.current.year }
    status { 1 }
    context_data { "" }
  end
end
