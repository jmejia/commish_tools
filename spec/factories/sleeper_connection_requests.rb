FactoryBot.define do
  factory :sleeper_connection_request do
    association :user
    sleeper_username { "testuser#{rand(1000..9999)}" }
    sleeper_id { rand(100000000000000000..999999999999999999).to_s }
    status { :pending }
    requested_at { Time.current }
    reviewed_at { nil }
    reviewed_by { nil }
    rejection_reason { nil }

    trait :approved do
      status { :approved }
      reviewed_at { 1.hour.ago }
      association :reviewed_by, factory: :user
    end

    trait :rejected do
      status { :rejected }
      reviewed_at { 1.hour.ago }
      association :reviewed_by, factory: :user
      rejection_reason { "Invalid username provided" }
    end

    trait :with_reviewer do
      association :reviewed_by, factory: :user
      reviewed_at { 1.hour.ago }
    end
  end
end
