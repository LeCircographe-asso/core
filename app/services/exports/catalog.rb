# frozen_string_literal: true

module Exports
  module Catalog
    ALL = [ PaymentLines, Memberships, Contributions, Attendances, Donations ].freeze

    def self.fetch(key)
      ALL.find { |export| export.key == key.to_s } || raise(ActiveRecord::RecordNotFound, "Unknown export: #{key}")
    end
  end
end
