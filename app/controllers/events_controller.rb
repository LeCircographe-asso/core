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
      upper_description: Faker::TvShows::BigBangTheory.quote,
      middle_description: "",
      bottom_description: "",
      location: Faker::Address.city,
      date: Faker::Date.forward(days: 1),
      creator: User.find(rand(20))
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
