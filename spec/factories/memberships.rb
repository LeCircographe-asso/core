FactoryBot.define do
  factory :membership do
    type_name { :Basic }

    trait :no_member do
      type_name { :No_Member }
    end

    trait :basic do
      type_name { :Basic }
    end

    trait :circus do
      type_name { :Circus }
    end
  end
end
