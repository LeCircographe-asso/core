class PagesController < ApplicationController
  allow_unauthenticated_access # Si cette méthode est requise pour autoriser l'accès

  def show
    render template: "pages/#{params[:id]}"
  end
end
