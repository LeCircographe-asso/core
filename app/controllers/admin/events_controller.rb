# frozen_string_literal: true

module Admin
  class EventsController < BaseController
    include ActionView::RecordIdentifier

    before_action :set_breadcrumbs

    def index
      @events = Event.all
      add_breadcrumb I18n.t("breadcrumbs.admin.events.events"), nil
    end

    def new
      @event = Event.new
      add_breadcrumb I18n.t("breadcrumbs.admin.events.events"), admin_events_path
      add_breadcrumb I18n.t("breadcrumbs.admin.events.new_event"), nil
    end

    def edit
      @event = Event.find params.expect(:id)
      add_breadcrumb I18n.t("breadcrumbs.admin.events.events"), admin_events_path
      add_breadcrumb @event.title, event_path(@event)
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    def create
      attrs = {
        title: event_params[:title],
        upper_description: event_params[:upper_description],
        middle_description: event_params[:middle_description],
        bottom_description: event_params[:bottom_description],
        date: event_params[:date],
        location: event_params[:location],
        fictif: event_params[:fictif],
        status: event_params[:status]
      }.compact_blank
      # fictif/status ont un défaut DB (draft/fictif=true) : on ne les passe
      # que si le formulaire les a explicitement envoyés, sinon compact_blank
      # les retire et Event.new laisse le défaut de colonne s'appliquer.
      @event = Event.new(attrs.merge(category: "other"))
      @event.creator = current_user if @event.respond_to?(:creator=)

      if @event.save
        redirect_to admin_events_path, notice: t(".created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @event = Event.find params.expect(:id)
      attrs = {
        title: event_params[:title],
        upper_description: event_params[:upper_description],
        middle_description: event_params[:middle_description],
        bottom_description: event_params[:bottom_description],
        date: event_params[:date],
        location: event_params[:location],
        fictif: event_params[:fictif],
        status: event_params[:status]
      }.compact_blank
      if @event.update(attrs)
        redirect_to event_path(@event), notice: t(".updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      event = Event.find(params.expect(:id))
      if event.destroy
        respond_to do |format|
          format.html { redirect_to admin_events_path, notice: t(".destroyed_notice") }
          format.turbo_stream do
            flash.now[:notice] = t(".destroyed_notice")
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
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
    end

    def event_params
      params.expect(event: %i[title upper_description middle_description bottom_description location date fictif status])
    end

    def event_deletion_reason
      params[:reason].presence || "Deleted from admin dashboard"
    end
  end
end
