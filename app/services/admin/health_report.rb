# frozen_string_literal: true

module Admin
  class HealthReport
    MAX_LIST = 50
    DUPLICATE_FIELDS = %i[email phone].freeze

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
      people_without_user = PersonQuery.active.where.missing(:user).order(:created_at)
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
      raise ArgumentError, "unsupported field" unless DUPLICATE_FIELDS.include?(field)

      t = scope.klass.arel_table
      col = t[field]
      expr = normalize ? Arel::Nodes::NamedFunction.new("LOWER", [ col ]) : col

      scope.where.not(field => [ nil, "" ])
           .group(expr)
           .having("COUNT(*) > 1")
           .pluck(expr)
    end

    def people_by_keys(scope, field, keys, normalize: true)
      return scope.none if keys.empty?

      raise ArgumentError, "unsupported field" unless DUPLICATE_FIELDS.include?(field)

      t = scope.klass.arel_table
      col = t[field]

      if normalize
        lowered = Arel::Nodes::NamedFunction.new("LOWER", [ col ])
        scope.where(lowered.in(keys))
             .order(lowered, t[:last_name], t[:first_name])
      else
        scope.where(field => keys)
             .order(t[field], t[:last_name], t[:first_name])
      end
    end
  end
end
