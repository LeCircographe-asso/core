class EventsController < ApplicationController
  skip_before_action :require_authentication, only: %i[index show]
  def index
    @events = Event.all
  end

  def show
    @event = Event.find params[:id]
  end
end