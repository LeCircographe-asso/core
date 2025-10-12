module ApplicationHelper
  include RoleHelper
  include MembershipHelper

  def current_user
    if authenticated?
      Current.user
    end
  end

  def authorized_roles
    %i[admin super_admin]
  end

  def admin_view?
    authenticated? && authorized_roles.include?(Current.user.system_role)
  end

  def render_card_component(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: "shared/card",
          locals: { title: title,
                    description: description,
                    image: image,
                    alt_text: alt_text,
                    link: link,
                    button_text: button_text }
  end

  def render_card_component_reverse(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: "shared/card_reverse",
          locals: { title: title,
                    description: description,
                    image: image,
                    alt_text: alt_text,
                    link: link,
                    button_text: button_text }
  end

  def flash_class(level)
    case level.to_sym
    when :notice, :success
      "bg-green-100 border-green-400 text-green-700"
    when :alert, :error
      "bg-red-100 border-red-400 text-red-700"
    when :warning
      "bg-yellow-100 border-yellow-400 text-yellow-700"
    else
      "bg-blue-100 border-blue-400 text-blue-700"
    end
  end

  def active_class(path)
    current_page?(path) ? "bg-gray-900 text-white" : "text-gray-300 hover:bg-gray-700 hover:text-white"
  end

  def format_phone_number(phone)
    return "Non renseigné" if phone.blank?

    # Format: +33 6 12 34 56 78
    phone.gsub(/(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/, '\1 \2 \3 \4 \5')
  end
end
