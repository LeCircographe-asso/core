class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[index]

  def index
  end

  def dashboard
  end
end
