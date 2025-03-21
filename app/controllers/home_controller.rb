class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[index]

  def index
    @events = Event.all
  end

  def dashboard
  end
end
