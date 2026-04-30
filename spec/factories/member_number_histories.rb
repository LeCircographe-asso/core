FactoryBot.define do
  factory :member_number_history do
    association :person
    sequence(:member_number) { |n| format('%02dU%03d', Date.current.year % 100, n) }
    membership_type { 'Basique' }
    year { Date.current.year }
    notes { "Numéro d'adhérent initial" }
    assigned_at { Time.current }

    trait :current do
      # No status field in the model
    end

    trait :replaced do
      replaced_at { Time.current }
    end

    trait :historical do
      replaced_at { Time.current }
    end

    trait :circus do
      sequence(:member_number) { |n| format('%02dC%03d', Date.current.year % 100, n) }
      membership_type { 'Cirque' }
    end

    trait :basic do
      sequence(:member_number) { |n| format('%02dU%03d', Date.current.year % 100, n + 500) }
      membership_type { 'Basique' }
    end
  end
end
