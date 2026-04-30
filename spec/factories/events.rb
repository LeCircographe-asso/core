FactoryBot.define do
  factory :event do
    association :creator, factory: :user
    name { Faker::Lorem.words(number: 3).join(' ').titleize }
    category { %i[show workshop volunteering other].sample }
    date { Faker::Date.forward(days: 30) }
    description { Faker::Lorem.paragraph }

    trait :show do
      category { :show }
      name { "Spectacle #{Faker::Lorem.word.titleize}" }
    end

    trait :workshop do
      category { :workshop }
      name { "Atelier #{Faker::Lorem.word.titleize}" }
    end

    trait :volunteering do
      category { :volunteering }
      name { "Bénévolat #{Faker::Lorem.word.titleize}" }
    end

    trait :other do
      category { :other }
      name { "Événement #{Faker::Lorem.word.titleize}" }
    end

    trait :upcoming do
      date { Faker::Date.forward(days: 30) }
    end

    trait :past do
      date { Faker::Date.backward(days: 30) }
    end
  end
end
