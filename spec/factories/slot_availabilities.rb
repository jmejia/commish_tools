FactoryBot.define do
  factory :slot_availability do
    association :scheduling_response
    association :event_time_slot
    availability { 2 } # available by default

    trait :available do
      availability { 2 }
    end

    trait :maybe do
      availability { 1 }
    end

    trait :unavailable do
      availability { 0 }
    end
  end
end
