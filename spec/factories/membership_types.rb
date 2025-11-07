FactoryBot.define do
  factory :membership_type do
    name { Faker::Company.name + " Membership" }
    category { [ :basic, :circus, :event ].sample }
    price_cents { [ 1500, 2000, 2500 ].sample }
    description { Faker::Lorem.paragraph }
    version { 1 }
    effective_from { Date.current }
    effective_until { nil }

    trait :basic do
      category { :basic }
      name { "Adhésion Basique" }
      price_cents { 1500 }
    end

    trait :circus do
      category { :circus }
      name { "Adhésion Cirque Complète" }
      price_cents { 2500 }
    end

    trait :circus_reduced do
      category { :circus }
      name { "Adhésion Cirque Réduite" }
      price_cents { 2000 }
    end

    trait :with_membership do
      after(:create) do |membership_type|
        person = create(:person)
        create(:membership, person: person, membership_type: membership_type)
      end
    end
  end
end
