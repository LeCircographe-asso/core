class EventAttendeesController < ApplicationController
  def create
    event_id = params[:id]
    if authenticated?
      EventAttendee.create!(user_id: Current.user.id, event_id: event_id, payment_id: 1)  # placeholder value for payment_id
    end
    redirect_to event_path(event_id)
  end

  def destroy
    if authenticated?
      event_id = params[:id]
      eattendee = EventAttendee.where("user_id = #{Current.user.id} AND event_id = #{event_id}")
      EventAttendee.destroy eattendee
    end
    redirect_to event_path(event_id)
  end
end
