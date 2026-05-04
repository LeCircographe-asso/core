# frozen_string_literal: true

module Admin
  module Users
    class ViewUserAdapter
      def self.from_person(person)
        user = User.new(
          id: "temp_#{person.id}",
          email_address: person.email,
          system_role: nil
        )

        user.association(:person).target = person
        user.association(:person).loaded!
        user
      end
    end
  end
end
