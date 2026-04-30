# frozen_string_literal: true

module MemberNumberManagement
  class MemberNumberSuggester < BaseService
    attribute :membership_type, :string, default: "BASIQUE"

    def call
      suggested_number = MemberManagementService.generate_member_number(membership_type)

      success(
        suggested_number: suggested_number,
        membership_type: membership_type,
        message: "Suggested member number successfully"
      )
    rescue StandardError => e
      Rails.logger.error "[MemberNumberSuggester] Error: #{e.message}"
      failure("Error generating member number: #{e.message}")
    end

    # success et failure hérités de BaseService
  end
end
