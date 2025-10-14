FactoryBot.define do
  factory :membership_type do
    name { Faker::Company.name + " Membership" }
    category { [:basic, :circus_full, :circus_reduced].sample }
    price_cents { [1500, 2000, 2500].sample }
    description { Faker::Lorem.paragraph }

    trait :basic do
      category { :basic }
      name { "Adhésion Basique" }
      price_cents { 1500 }
    end

    trait :circus_full do
      category { :circus_full }
      name { "Adhésion Cirque Complète" }
      price_cents { 2500 }
    end

    trait :circus_reduced do
      category { :circus_reduced }
      name { "Adhésion Cirque Réduite" }
      price_cents { 2000 }
    end
  end
end
