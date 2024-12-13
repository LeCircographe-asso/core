class PagesController < ApplicationController
  skip_before_action :require_authentication
  include NotepadHelper
  include OpeningHoursHelper

  def show
    @opening_hours = Rails.cache.fetch("opening_hours") || default_opening_hours
    @notepad = Rails.cache.fetch("notepad") || default_notepad
    render template: "pages/#{params[:id]}"
  end
end
