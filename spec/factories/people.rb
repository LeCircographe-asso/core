FactoryBot.define do
  factory :person do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    address { Faker::Address.full_address }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 80) }
    emergency_contact_name { Faker::Name.name }
    emergency_contact_phone { Faker::PhoneNumber.phone_number }
    notes { Faker::Lorem.paragraph }
    occupation { Faker::Job.title }
    specialty { Faker::Job.seniority }
    image_rights { [ true, false ].sample }
    get_involved { [ true, false ].sample }
    newsletter_subscribed { [ true, false ].sample }
    dyslexic_font { [ true, false ].sample }
  end
end
