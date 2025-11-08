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
      creator = EventManagement::EventCreator.new(
        name: event_params[:title],
        upper_description: event_params[:upper_description],
        middle_description: event_params[:middle_description],
        bottom_description: event_params[:bottom_description],
        date: event_params[:date],
        location: event_params[:location],
        creator_id: current_user.id,
        category: "other" # Default category, can be enhanced later
      )

      result = creator.call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_events_path, notice: "Événement créé avec succès" }
        else
          @event = Event.new(event_params)
          format.html { render :new, alert: result.message }
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

      updater = EventManagement::EventUpdater.new(
        event_id: @event.id,
        name: event_params[:title],
        upper_description: event_params[:upper_description],
        middle_description: event_params[:middle_description],
        bottom_description: event_params[:bottom_description],
        date: event_params[:date],
        location: event_params[:location],
        updated_by_id: current_user.id
      )

      result = updater.call

      if result.success?
        redirect_to event_path(@event), notice: "Événement modifié avec succès"
      else
        redirect_to edit_admin_event_path(@event), alert: result.message
      end
    end
    def destroy
      deleter = EventManagement::EventDeleter.new(
        event_id: params.expect(:id),
        deleted_by_id: current_user.id,
        reason: event_deletion_reason
      )

      result = deleter.call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_events_path, notice: "Événement supprimé avec succès" }
        else
          format.html { redirect_to admin_events_path, alert: result.message }
        end
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
    def event_deletion_reason
      params[:reason].presence || "Deleted from admin dashboard"
    end
  end
end
