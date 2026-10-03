# frozen_string_literal: true

module Admin
  module Roles
    class IndexQuery
      STAFF_ROLES = %w[super_admin admin volunteer].freeze
      SEARCH_MIN_LENGTH = 2
      SEARCH_LIMIT = 20

      def users_with_role
        active_users.where(system_role: STAFF_ROLES)
                    .order(:system_role, "people.last_name", "people.first_name")
      end

      # Comptes web_visitor correspondant à la recherche (nom, email ou téléphone
      # de la Person, ou email de connexion), pour leur attribuer un rôle.
      def search_web_visitors(term)
        return User.none if term.length < SEARCH_MIN_LENGTH

        matching_people = PersonQuery.active.search_by_contact(term).select(:id)
        active_users.web_visitor
                    .where(person_id: matching_people)
                    .or(active_users.web_visitor.where("users.email_address LIKE ?", "%#{term}%"))
                    .order("people.last_name", "people.first_name")
                    .limit(SEARCH_LIMIT)
      end

      private

      def active_users
        User.joins(:person)
            .includes(:person)
            .where(deleted: [ false, nil ], deleted_at: nil)
            .where(people: { deleted_at: nil })
      end
    end
  end
end
