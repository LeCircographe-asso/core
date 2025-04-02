class EventAttendeesController < ApplicationController
  before_action :require_authentication

  def create
    event_id = params[:id]
    EventAttendee.create!(user_id: Current.user.id, event_id: event_id)
    redirect_to event_path(event_id)
  end

  def destroy
    event_id = params[:id]
    attendee = EventAttendee.find_by(user_id: Current.user.id, event_id: event_id)
    attendee&.destroy
    redirect_to event_path(event_id)
  end
end
