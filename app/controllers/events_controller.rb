class EventsController < ApplicationController
  skip_before_action :require_authentication, only: %i[index show upcoming]


  def index
    @events = Event.all
  end

  def show
    @event = Event.find params[:id]
  end

  def upcoming
    @events = Event.upcoming.by_date.limit(6)
    render partial: "home/upcoming_events", locals: { events: @events }
  end

  def past
    @events = Event.past.order(date: :desc).limit(9)
    render partial: "pages/news/events_grid", locals: { events: @events }
  end
end
