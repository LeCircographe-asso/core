FactoryBot.define do
  factory :membership do
    association :person
    association :membership_type
    started_at { Date.current }
    ended_at { Date.current + 1.year }
    status { :active }
    first_joined_at { Date.current }

    trait :active do
      status { :active }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :expired do
      status { :expired }
      ended_at { 1.day.ago }
    end

    trait :basic do
      association :membership_type, factory: [:membership_type, :basic]
    end

    trait :circus_full do
      association :membership_type, factory: [:membership_type, :circus_full]
    end

    trait :circus_reduced do
      association :membership_type, factory: [:membership_type, :circus_reduced]
    end
  end
end