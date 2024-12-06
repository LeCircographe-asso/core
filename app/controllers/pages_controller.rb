class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    render params[:id]
  end

end
