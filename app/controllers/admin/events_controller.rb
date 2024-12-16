module Admin
  class EventsController < BaseController

    def index
      @events = Event.all
    end
    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)
      @event.creator = current_user
      respond_to do |format|
        if @event.save!
          format.html { redirect_to admin_events_path, notice: "Evenement créé avec succès"}
        else
          format.html { render :new, alert: @event.errors.full_messages}
        end
      end
    end
    def edit
      @event = Event.find params[:id]
      if !Current.user.has_privileges?
        redirect_to root_path, alert: "Réservé aux administrateurs"
      end
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
      params.require(:event).permit(:title, :upper_description, :middle_description, :bottom_description, :location, :date)
    end
  end
end
