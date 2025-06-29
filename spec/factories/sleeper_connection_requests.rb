FactoryBot.define do
  factory :sleeper_connection_request do
    user { nil }
    sleeper_username { "MyString" }
    sleeper_id { "MyString" }
    status { 1 }
    requested_at { "2025-06-29 14:02:07" }
    reviewed_at { "2025-06-29 14:02:07" }
    reviewed_by { nil }
    rejection_reason { "MyText" }
  end
end
