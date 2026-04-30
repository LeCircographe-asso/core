# frozen_string_literal: true

class MembershipStatusBadgeComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  def badge_class
    if person.has_active_membership?
      "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800 cursor-help"
    elsif person.memberships.exists?
      "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800 cursor-help"
    else
      "status-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800"
    end
  end

  def status_text
    if person.has_active_membership?
      "✓ Actif"
    elsif person.memberships.exists?
      "⚠ Expiré"
    else
      "✗ Aucune"
    end
  end

  def tooltip_text
    if person.has_active_membership?
      current_membership = person.current_membership
      "#{simplified_membership_name(current_membership.membership_type.name)} - Expire le #{current_membership.ended_at.strftime('%d/%m/%Y')}"
    elsif person.memberships.exists?
      last_membership = person.memberships.order(:created_at).last
      "#{simplified_membership_name(last_membership.membership_type.name)} expirée le #{last_membership.ended_at.strftime('%d/%m/%Y')}"
    else
      "Aucune adhésion"
    end
  end

  def tooltip_data
    if person.has_active_membership? || person.memberships.exists?
      {
        controller: "tooltip",
        'tooltip-content-value': tooltip_text
      }
    else
      {}
    end
  end

  private

  attr_reader :person

  # Simplified membership name for tooltip - just the base type
  def simplified_membership_name(raw_name)
    name = raw_name.to_s.strip
    return "Adhésion" if name.blank?

    # Extract base type by removing common suffixes
    simplified = name.gsub(/\s+(complète|complete|standard|basique|basic)$/i, "")

    # Add "Adhésion" prefix if not already present
    if simplified.downcase.start_with?("adhesion") || simplified.downcase.start_with?("adhésion")
      simplified
    else
      "Adhésion #{simplified}"
    end
  end

  # Normalize membership display to avoid duplicated prefix like "Adhésion Adhésion ..."
  def normalized_membership_name(raw_name)
    name = raw_name.to_s.strip
    return "Adhésion" if name.blank?

    downcased = name.downcase
    if downcased.start_with?("adhesion ") || downcased.start_with?("adhésion ")
      # Name already contains the word, keep it as-is capitalized
      name.gsub(/^adhesion\s+/i, "Adhésion ").gsub(/^adhésion\s+/i, "Adhésion ")
    else
      "Adhésion #{name}"
    end
  end
end
