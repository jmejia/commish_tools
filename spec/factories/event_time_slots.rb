FactoryBot.define do
  factory :event_time_slot do
    association :scheduling_poll
    starts_at { 3.days.from_now }
    duration_minutes { 180 } # 3 hours for draft
    order_index { 0 }
    slot_metadata { {} }

    trait :morning do
      starts_at { 3.days.from_now.change(hour: 10, min: 0) }
    end

    trait :afternoon do
      starts_at { 3.days.from_now.change(hour: 14, min: 0) }
    end

    trait :evening do
      starts_at { 3.days.from_now.change(hour: 19, min: 0) }
    end
  end
end
