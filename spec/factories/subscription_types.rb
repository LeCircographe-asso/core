FactoryBot.define do
  factory :subscription_type do
    sequence(:name) { |n| "subscription_#{n}" }
    price { 10.0 }
    duration { 30 }
    description { "Description de l'abonnement" }

    trait :daily do
      name { "daily" }
      price { 4 }
      duration { 1 }
    end
    
    trait :booklet do
      name { "booklet" }
      price { 30 }
      duration { -1 } # Indique un carnet
    end
    
    trait :trimestrial do
      name { "trimestrial" }
      price { 65 }
      duration { 90 }
    end
    
    trait :annual do
      name { "annual" }
      price { 150 }
      duration { 365 }
    end
  end
end 