# frozen_string_literal: true

module People
  class OfferPolicy
    def self.validate!(recorded_by:, person:, offer_type:, offer_reason:, contribution_formula: nil)
      new(
        recorded_by: recorded_by,
        person: person,
        offer_type: offer_type,
        offer_reason: offer_reason,
        contribution_formula: contribution_formula
      ).validate!
    end

    def initialize(recorded_by:, person:, offer_type:, offer_reason:, contribution_formula: nil)
      @recorded_by = recorded_by
      @person = person
      @offer_type = offer_type
      @offer_reason = offer_reason
      @contribution_formula = contribution_formula
    end

    def validate!
      raise "Seuls les admins et super-admins peuvent offrir des #{offer_type}s" unless allowed_actor?
      raise "Une raison doit être fournie pour offrir une #{offer_type}" if offer_reason.blank?

      audit!
      true
    end

    private

    attr_reader :recorded_by, :person, :offer_type, :offer_reason, :contribution_formula

    def allowed_actor?
      recorded_by.can_offer_items?
    end

    def audit!
      Rails.logger.info "OFFER AUDIT: #{recorded_by.email} offered #{offer_type} to #{person.full_name} (#{person.id}) - Reason: #{offer_reason}"
    end
  end
end
