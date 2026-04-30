class MembershipTypeBadgeComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  def badge_class
    if person.has_active_membership?
      current_membership = person.current_membership
      type_class = case current_membership.membership_type.name.downcase
                   when 'basique', 'basic'
                     'bg-blue-100 text-blue-800'
                   when 'cirque', 'circus'
                     'bg-purple-100 text-purple-800'
                   else
                     'bg-gray-100 text-gray-800'
                   end

      "membership-badge px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{type_class}"
    else
      'px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800'
    end
  end

  def badge_text
    if person.has_active_membership?
      simplified_membership_name(person.current_membership.membership_type.name)
    else
      'Aucune'
    end
  end

  private

  attr_reader :person

  # Simplified membership name for admin dashboard - just the base type
  def simplified_membership_name(raw_name)
    name = raw_name.to_s.strip
    return 'Adhésion' if name.blank?

    # Extract base type by removing common suffixes
    simplified = name.gsub(/\s+(complète|complete|standard|basique|basic)$/i, '')

    # Add "Adhésion" prefix if not already present
    if simplified.downcase.start_with?('adhesion') || simplified.downcase.start_with?('adhésion')
      simplified
    else
      "Adhésion #{simplified}"
    end
  end
end
