FactoryBot.define do
  factory :league_context do
    association :league

    # Set up basic structured content
    after(:build) do |league_context|
      league_context.nature = "Fantasy football league with competitive friends"
      league_context.tone = "Humorous but competitive, with light trash talk"
      league_context.rivalries = "Team Awesome vs The Destroyers - bitter rivalry"
      league_context.history = "5th year running league with the same core group"
      league_context.response_style = "Confident, slightly cocky, but good-natured"
    end

    trait :empty do
      after(:build) do |league_context|
        league_context.nature = ""
        league_context.tone = ""
        league_context.rivalries = ""
        league_context.history = ""
        league_context.response_style = ""
      end
    end

    trait :long_content do
      after(:build) do |league_context|
        league_context.history = "A" * 1000
      end
    end

    trait :max_length do
      after(:build) do |league_context|
        league_context.history = "A" * 1000
        league_context.nature = "A" * 1000
        league_context.tone = "A" * 1000
        league_context.rivalries = "A" * 1000
        league_context.response_style = "A" * 1000
      end
    end

    trait :over_limit do
      after(:build) do |league_context|
        league_context.history = "A" * 1001
      end
    end
  end
end
