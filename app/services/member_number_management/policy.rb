# frozen_string_literal: true

module MemberNumberManagement
  class Policy
    TYPE_CODE_BY_INPUT = {
      "CIRQUE" => "C",
      "C" => "C",
      "BASIQUE" => "U",
      "BASIC" => "U",
      "U" => "U"
    }.freeze

    TYPE_LABEL_BY_CODE = {
      "C" => "Cirque",
      "U" => "Basique"
    }.freeze

    def self.type_code_for(membership_type)
      TYPE_CODE_BY_INPUT.fetch(membership_type.to_s.upcase, "U")
    end

    def self.type_label_for(membership_type)
      TYPE_LABEL_BY_CODE.fetch(type_code_for(membership_type), "Basique")
    end

    def self.parse(member_number)
      return nil if member_number.blank?

      match = member_number.match(/^(\d{2})([CU])(\d+)$/)
      return nil unless match

      {
        year: "20#{match[1]}",
        type: type_label_for(match[2]),
        number: match[3].to_i,
        full_year: match[1],
        type_code: match[2]
      }
    end

    def self.valid_format?(member_number)
      return false if member_number.blank?

      member_number.match?(/^\d{2}[CU]\d{3,5}$/)
    end
  end
end
