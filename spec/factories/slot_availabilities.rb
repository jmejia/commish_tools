FactoryBot.define do
  factory :slot_availability do
    association :scheduling_response
    association :event_time_slot
    availability { 2 } # available_ideal by default

    trait :available_ideal do
      availability { 2 }
    end

    trait :available_not_ideal do
      availability { 1 }
    end

    trait :unavailable do
      availability { 0 }
    end
  end
end
