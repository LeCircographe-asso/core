class EventInterestsController < ApplicationController
  before_action :set_event

  def create
    # Utiliser le nouveau système Person-Based
    if current_user.person.nil?
      redirect_to @event, alert: "Votre profil n'est pas complet. Veuillez contacter l'administration."
      return
    end

    @attendance = current_user.person.attendances.build(event: @event, date: Date.current)

    if @attendance.save
      redirect_to @event, notice: "Vous êtes maintenant intéressé par cet événement !"
    else
      redirect_to @event, alert: "Erreur lors de l'inscription"
    end
  end

  def destroy
    @attendance = current_user.person.attendances.find_by(event: @event)

    if @attendance&.destroy
      redirect_to @event, notice: "Vous n'êtes plus intéressé par cet événement"
    else
      redirect_to @event, alert: "Erreur lors de la désinscription"
    end
  end

  private

  def set_event
    @event = Event.find(params[:id] || params[:event_id])
  end
end
