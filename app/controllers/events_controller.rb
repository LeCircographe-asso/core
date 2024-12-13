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
      creator: params[:creator]
    )
    redirect_to root_path, notice: "Evenement créé avec succès"
  end

  def show
    @event = Event.find params[:id]
  end

  def index
    @events = Event.all
  end

  def edit
    @event = Event.find params[:id]
  end

  def update
    @event = Event.find params[:id]
    if @event.update(event_params)
      redirect_to event_path, notice: "Evenement modifié avec succès"
    end
  end

  private
  def event_params
      params.fetch(:event, {})
      params.require(:event).permit(:title, :upper_description, :middle_description, :bottom_description, :location, :date, :creator)
  end
end
