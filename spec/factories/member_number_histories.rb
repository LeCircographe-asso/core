FactoryBot.define do
  factory :member_number_history do
    association :person
    member_number { "25U001" }
    membership_type { "Basique" }
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
      member_number { "25C001" }
      membership_type { "Cirque" }
    end

    trait :basic do
      member_number { "25U001" }
      membership_type { "Basique" }
    end
  end
end
