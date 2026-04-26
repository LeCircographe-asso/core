module Admin
  class HealthReport
    MAX_LIST = 50

    Result = Struct.new(
      :users_without_person,
      :users_without_person_count,
      :people_without_user,
      :people_without_user_count,
      :duplicate_people_by_email,
      :duplicate_people_by_email_count,
      :duplicate_people_by_phone,
      :duplicate_people_by_phone_count,
      :payments_without_person,
      :payments_without_person_count,
      keyword_init: true
    )

    def call
      users_without_person = User.left_joins(:person).where(people: { id: nil }).order(:created_at)
      people_without_user = PersonQuery.active.left_joins(:user).where(users: { id: nil }).order(:created_at)
      payments_without_person = Payment.where(person_id: nil).order(:created_at)

      email_keys = duplicate_keys(PersonQuery.active, :email, normalize: true)
      phone_keys = duplicate_keys(PersonQuery.active, :phone, normalize: false)

      Result.new(
        users_without_person: users_without_person.limit(MAX_LIST),
        users_without_person_count: users_without_person.count,
        people_without_user: people_without_user.limit(MAX_LIST),
        people_without_user_count: people_without_user.count,
        duplicate_people_by_email: people_by_keys(PersonQuery.active, :email, email_keys, normalize: true).limit(MAX_LIST),
        duplicate_people_by_email_count: email_keys.size,
        duplicate_people_by_phone: people_by_keys(PersonQuery.active, :phone, phone_keys, normalize: false).limit(MAX_LIST),
        duplicate_people_by_phone_count: phone_keys.size,
        payments_without_person: payments_without_person.limit(MAX_LIST),
        payments_without_person_count: payments_without_person.count
      )
    end

    private

    def duplicate_keys(scope, field, normalize: true)
      column = normalize ? "LOWER(#{field})" : field.to_s

      scope.where.not(field => [ nil, "" ])
           .group(Arel.sql(column))
           .having("COUNT(*) > 1")
           .pluck(Arel.sql(column))
    end

    def people_by_keys(scope, field, keys, normalize: true)
      return scope.none if keys.empty?

      if normalize
        scope.where("LOWER(#{field}) IN (?)", keys)
             .order(Arel.sql("LOWER(#{field}), last_name, first_name"))
      else
        scope.where(field => keys)
             .order(Arel.sql("#{field}, last_name, first_name"))
      end
    end
  end
end
