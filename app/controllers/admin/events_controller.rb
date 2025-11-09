module Admin
  class EventsController < BaseController
    include ActionView::RecordIdentifier
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
      @event = Event.new(
        title: event_params[:title],
        upper_description: event_params[:upper_description],
        middle_description: event_params[:middle_description],
        bottom_description: event_params[:bottom_description],
        date: event_params[:date],
        location: event_params[:location],
        category: "other"
      )

      if @event.save
        redirect_to admin_events_path, notice: "Événement créé avec succès"
      else
        render :new, status: :unprocessable_content
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
      if @event.update(
        title: event_params[:title],
        upper_description: event_params[:upper_description],
        middle_description: event_params[:middle_description],
        bottom_description: event_params[:bottom_description],
        date: event_params[:date],
        location: event_params[:location]
      )
        redirect_to event_path(@event), notice: "Événement modifié avec succès"
      else
        render :edit, status: :unprocessable_content
      end
    end
    def destroy
      event = Event.find(params.expect(:id))
      if event.destroy
        respond_to do |format|
          format.html { redirect_to admin_events_path, notice: "Événement supprimé avec succès" }
          format.turbo_stream do
            flash.now[:notice] = "Événement supprimé avec succès"
            render turbo_stream: [
              turbo_stream.remove(dom_id(event)),
              turbo_stream.replace("flash", partial: "shared/flash")
            ]
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_events_path, alert: event.errors.full_messages.to_sentence }
          format.turbo_stream do
            flash.now[:alert] = event.errors.full_messages.to_sentence
            render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
          end
        end
      end
    end
    private
    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end
    def event_params
      params.expect(event: %i[title upper_description middle_description bottom_description location date])
    end
    def event_deletion_reason
      params[:reason].presence || "Deleted from admin dashboard"
    end
  end
end
