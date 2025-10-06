class HomeController < ApplicationController
  include OpeningHoursHelper
  allow_unauthenticated_access only: %i[index font_examples]


  def index
    @events = Event.all
  end

  def dashboard
  end

  def font_examples
    # This is just a view-only action
  end
end
