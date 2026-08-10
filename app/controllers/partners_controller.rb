# frozen_string_literal: true

class PartnersController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @partners = Partner.ordered

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "partners",
          partial: "shared/partners",
          locals: { partners: @partners }
        )
      end
      format.html do
        redirect_back_or_to(page_path("about"))
      end
    end
  end
end
