# frozen_string_literal: true

module Admin
  module Users
    class PersonRouteKey
      PREFIX = "person_"

      def self.call(person_or_id)
        id = person_or_id.respond_to?(:id) ? person_or_id.id : person_or_id
        "#{PREFIX}#{id}"
      end

      def self.person_identifier?(raw_id)
        raw_id.to_s.start_with?(PREFIX)
      end

      def self.extract(raw_id)
        raw_id.to_s.delete_prefix(PREFIX)
      end
    end
  end
end
