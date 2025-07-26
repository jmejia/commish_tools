FactoryBot.define do
  factory :scheduling_response do
    association :scheduling_poll
    sequence(:respondent_name) { |n| "League Member #{n}" }
    sequence(:respondent_identifier) { |n| "respondent_#{n}" }
    ip_address { "192.168.1.#{rand(1..254)}" }
    metadata { { user_agent: 'Mozilla/5.0' } }
  end
end
