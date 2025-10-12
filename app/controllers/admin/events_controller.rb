module Admin
  class EventsController < BaseController
    before_action :set_breadcrumbs

    def index
      @events = Event.all
      add_breadcrumb "Événements", nil
    end
    def new
      @event = Event.new
      add_breadcrumb "Événements", admin_events_path
      add_breadcrumb "Nouvel événement", nil
    end

    def create
      @event = Event.new(event_params)
      @event.creator = current_user
      respond_to do |format|
        if @event.save!
          format.html { redirect_to admin_events_path, notice: "Evenement créé avec succès" }
        else
          format.html { render :new, alert: @event.errors.full_messages }
        end
      end
    end
    def edit
      @event = Event.find params[:id]
      add_breadcrumb "Événements", admin_events_path
      add_breadcrumb @event.title, event_path(@event)
      add_breadcrumb "Modifier", nil
    end
    def update
      @event = Event.find params[:id]
      if @event.update(event_params)
        redirect_to event_path, notice: "Evenement modifié avec succès"
      end
    end
    private
    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end
    def event_params
      params.fetch(:event, {})
      params.require(:event).permit(:title, :upper_description, :middle_description, :bottom_description, :location, :date)
    end
  end
end
