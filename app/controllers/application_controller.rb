class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from ActiveRecord::RecordNotFound, with: :url_not_found
  rescue_from ActionController::RoutingError, with: :url_not_found

  def url_not_found
    case controller_name
    when 'users'
      redirect_to root_path, alert: "L'utilisateur n'existe pas."
    else
      redirect_to root_path, alert: "La page que vous cherchez n'existe pas."
    end
  end

end
