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
    frame_id = request.headers["Turbo-Frame"].presence

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          partial_path, partial_locals =
            case frame_id
            when "activities-upcoming"
              [ "pages/news/events_grid", { events: @events } ]
            else
              [ "home/upcoming_events", { events: @events } ]
            end

          render partial: "shared/turbo_frame_wrapper",
                 locals: {
                   frame_id: frame_id || "events_upcoming",
                   partial_path: partial_path,
                   partial_locals: partial_locals
                 }
        else
          render :upcoming
        end
      end
    end
  end

  def past
    @events = Event.past.order(date: :desc).limit(9)
    frame_id = request.headers["Turbo-Frame"].presence
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "shared/turbo_frame_wrapper",
                 locals: {
                   frame_id: frame_id || "events_past",
                   partial_path: "pages/news/events_grid",
                   partial_locals: { events: @events }
                 }
        else
    render partial: "pages/news/events_grid", locals: { events: @events }
        end
      end
    end
  end
end
