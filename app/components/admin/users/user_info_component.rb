class Admin::Users::UserInfoComponent < ViewComponent::Base
  def initialize(user:, person:, is_person_without_user: false)
    @user = user
    @person = person
    @is_person_without_user = is_person_without_user
  end

  private

  attr_reader :user, :person, :is_person_without_user

  def display_value(value)
    value.presence || content_tag(:span, 'Non renseigné', class: 'text-gray-400 italic')
  end

  def display_date(date)
    return content_tag(:span, 'Non renseigné', class: 'text-gray-400 italic') if date.blank?

    if date.is_a?(String)
      Date.parse(date).strftime('%d/%m/%Y')
    else
      date.strftime('%d/%m/%Y')
    end
  rescue StandardError
    content_tag(:span, 'Date invalide', class: 'text-gray-400 italic')
  end

  def display_address
    return display_value(nil) unless user.address.present?

    address_parts = [user.address, user.zip_code, user.town, user.country].compact.reject(&:blank?)

    # Format sur 3 lignes : Adresse, Code Postal + Ville, Pays
    if address_parts.length >= 3
      address_line = address_parts[0]
      city_line = "#{address_parts[1]} #{address_parts[2]}"
      country_line = address_parts[3] if address_parts[3]

      content = content_tag(:div, address_line, class: 'block')
      content += content_tag(:div, city_line, class: 'block')
      content += content_tag(:div, country_line, class: 'block') if country_line
      content.html_safe
    else
      address_parts.join(', ')
    end
  end

  def preference_status(enabled)
    enabled ? 'bg-[#1F5C55]' : 'bg-gray-200'
  end

  def display_role
    if user.system_role.present?
      user.role_humanized
    else
      'Aucun compte'
    end
  end
end
