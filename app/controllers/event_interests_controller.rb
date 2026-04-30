# frozen_string_literal: true

class EventInterestsController < ApplicationController
  before_action :set_event

  def create
    # Utiliser le nouveau système Person-Based
    if current_user.person.nil?
      redirect_to @event, alert: t(".profile_incomplete")
      return
    end

    @attendance = current_user.person.attendances.build(event: @event, date: Date.current)

    if @attendance.save
      redirect_to @event, notice: t(".interest_added")
    else
      redirect_to @event, alert: t(".interest_error")
    end
  end

  def destroy
    @attendance = current_user.person.attendances.find_by(event: @event)

    if @attendance&.destroy
      redirect_to @event, notice: t(".interest_removed")
    else
      redirect_to @event, alert: t(".interest_remove_error")
    end
  end

  private

  def set_event
    @event = Event.find(params[:id] || params[:event_id])
  end
end
