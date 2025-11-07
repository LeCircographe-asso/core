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
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "events/upcoming_frame", locals: { events: @events }
        else
          render :upcoming
        end
      end
    end
  end

  def past
    @events = Event.past.order(date: :desc).limit(9)
    render partial: "pages/news/events_grid", locals: { events: @events }
  end
end
