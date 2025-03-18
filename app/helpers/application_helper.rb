module ApplicationHelper
  def current_user
    if authenticated?
      Current.user
    end
  end

  def authorized_roles
  end

  def admin_view?
  authenticated? && authorized_roles.include?(Current.user.role)
  end

  def render_card_component(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: 'shared/card', 
          locals: { title: title, 
                    description: description, 
                    image: image, 
                    alt_text: alt_text, 
                    link: link, 
                    button_text: button_text }
  end

  def render_card_component_reverse(title:, description:, image:, alt_text:, link:, button_text:)
    render partial: 'shared/card_reverse', 
          locals: { title: title, 
                    description: description, 
                    image: image, 
                    alt_text: alt_text, 
                    link: link, 
                    button_text: button_text }
  end

end
