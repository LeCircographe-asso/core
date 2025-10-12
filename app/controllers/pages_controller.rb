class PagesController < ApplicationController
  skip_before_action :require_authentication
  include NotepadHelper
  include OpeningHoursHelper
  layout "application"


  def show
    @opening_hours = Rails.cache.fetch("opening_hours") || default_opening_hours
    @notepad = Rails.cache.fetch("notepad") || default_notepad
    @blogs = Blog.order(created_at: :desc).limit(3)
    render template: "pages/#{params[:id]}"
  end
end
