# frozen_string_literal: true

# Bouton « Je suis intéressé » : un like par compte web, rien de plus.
class EventInterestsController < ApplicationController
  before_action :set_event

  def create
    @interest = current_user.event_interests.build(event: @event)

    if @interest.save
      redirect_to @event, notice: t(".interest_added")
    else
      redirect_to @event, alert: t(".interest_error")
    end
  end

  def destroy
    @interest = current_user.event_interests.find_by(event: @event)

    if @interest&.destroy
      redirect_to @event, notice: t(".interest_removed")
    else
      redirect_to @event, alert: t(".interest_remove_error")
    end
  end

  private

  # Même règle que EventsController#show : un brouillon n'existe pas pour le public.
  def set_event
    @event = Event.find(params[:id] || params[:event_id])
    raise ActiveRecord::RecordNotFound if @event.draft? && !current_user&.can_access_admin_zone?
  end
end
