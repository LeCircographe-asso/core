class EventsController < ApplicationController
  def new
    @event = Event.new
    if !Current.user.has_privileges?
      redirect_to root_path, alert: "Réservé aux administrateurs"
    end
  end

  def create
    @event = Event.create!(
      title: params[:title],
      upper_description: params[:upper_description],
      middle_description: params[:middle_description],
      bottom_description: params[:bottom_description],
      location: params[:location],
      date: params[:date],
      creator: Current.user
    )
    redirect_to root_path, notice: "Evenement créé avec succès"
  end

  def show
    @event = Event.find params[:id]
  end

  def index
    @events = Event.all
  end
end
