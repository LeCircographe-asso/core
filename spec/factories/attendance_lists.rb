FactoryBot.define do
  factory :attendance_list do
    name { "Liste de présence du #{Date.current.strftime('%d/%m/%Y')}" }
    list_type { :training }
    status { :open }
    start_date { Date.current }
    end_date { Date.current + 1.day }

    trait :event do
      list_type { :event }
      name { "Événement du #{start_date.strftime('%d/%m/%Y')}" }
    end

    trait :meeting do
      list_type { :meeting }
      name { "Réunion du #{start_date.strftime('%d/%m/%Y')}" }
    end

    trait :closed do
      status { :close }
    end

    trait :archived do
      status { :archived }
    end
  end
end
