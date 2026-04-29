class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbsHelper
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def navigation_streams
    [
      turbo_stream.replace('navigation', render_to_string(partial: 'shared/navbar')),
      turbo_stream.replace('flash', render_to_string(partial: 'shared/flash'))
    ]
  end
end
