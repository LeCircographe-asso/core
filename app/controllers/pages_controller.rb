class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    render template: "pages/#{params[:id]}"
  end
end
