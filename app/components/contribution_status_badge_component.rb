# frozen_string_literal: true

class ContributionStatusBadgeComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  def badge_class
    if has_active_contributions?
      'px-2 py-1 inline-block text-xs leading-tight font-semibold rounded-full bg-indigo-100 text-indigo-800 cursor-help text-center'
    else
      'px-2 py-1 inline-block text-xs leading-tight font-semibold rounded-full bg-gray-100 text-gray-800 text-center'
    end
  end

  def badge_text
    if has_active_contributions?
      contribution = active_contribution
      case contribution.contribution_formula.duration
      when 'pack10'
        sessions_remaining = contribution.sessions_remaining
        plural_s = sessions_remaining > 1 ? 's' : ''
        "<div class='block'>#{sessions_remaining} séance#{plural_s}</div><div class='text-xs opacity-75'>restante#{plural_s}</div>".html_safe
      when 'day'
        'Journée'
      when 'trimester'
        'Trimestriel'
      when 'annual'
        'Annuel'
      else
        "#{total_sessions} séances"
      end
    else
      'Aucune'
    end
  end

  def tooltip_text
    if has_active_contributions?
      contribution = active_contribution
      case contribution.contribution_formula.duration
      when 'pack10'
        'Carnet de 10 séances'
      when 'day'
        'Cotisation journée'
      when 'trimester'
        "Cotisation trimestrielle - Expire le #{contribution.expires_at.strftime('%d/%m/%Y')}"
      when 'annual'
        "Cotisation annuelle - Expire le #{contribution.expires_at.strftime('%d/%m/%Y')}"
      else
        "#{total_sessions} séances restantes"
      end
    else
      ''
    end
  end

  def tooltip_data
    if has_active_contributions?
      {
        controller: 'tooltip',
        'tooltip-content-value': tooltip_text
      }
    else
      {}
    end
  end

  def has_active_contributions?
    person.contributions.active.any?
  end

  def total_sessions
    person.contributions.active.sum(&:sessions_remaining)
  end

  private

  attr_reader :person

  def active_contribution
    person.contributions.active.first
  end
end
