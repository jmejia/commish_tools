FactoryBot.define do
  factory :scheduling_poll do
    association :league
    association :created_by, factory: :user
    event_type { 'draft' }
    title { "#{Date.current.year} Draft Scheduling" }
    description { "Let's find the best time for our draft!" }
    status { :active }

    trait :with_time_slots do
      after(:create) do |poll|
        create_list(:event_time_slot, 3, scheduling_poll: poll)
      end
    end

    trait :closed do
      status { :closed }
    end

    trait :with_responses do
      after(:create) do |poll|
        create_list(:event_time_slot, 3, scheduling_poll: poll)
        3.times do |i|
          response = create(:scheduling_response, 
                          scheduling_poll: poll,
                          respondent_name: "Member #{i + 1}")
          
          poll.event_time_slots.each do |slot|
            create(:slot_availability, 
                   scheduling_response: response,
                   event_time_slot: slot,
                   availability: [0, 1, 2].sample)
          end
        end
      end
    end
  end
end