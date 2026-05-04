# frozen_string_literal: true

FactoryBot.define do
  factory :contribution do
    association :person
    association :contribution_formula, factory: %i[contribution_formula pack10]
    purchased_at { Time.current }
    sessions_remaining { People::ContributionPayloadBuilder.call(contribution_formula, reference_date: purchased_at&.to_date || Date.current)[:sessions_remaining] }
    status { :active }
    expires_at { People::ContributionPayloadBuilder.call(contribution_formula, reference_date: purchased_at&.to_date || Date.current)[:expires_at] }

    trait :active do
      status { :active }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :expired do
      status { :expired }
      purchased_at { 1.day.ago }
      expires_at do
        contribution_formula.duration == "day" ? purchased_at.end_of_day : 1.day.ago
      end
    end

    trait :consumed do
      status { :consumed }
      sessions_remaining { 0 }
    end

    trait :with_sessions do
      sessions_remaining { 5 }
    end

    trait :empty do
      sessions_remaining { 0 }
    end
  end
end
