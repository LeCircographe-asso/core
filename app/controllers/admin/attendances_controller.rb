module Admin
  class AttendancesController < BaseController
    before_action :set_attendance, only: [ :show, :destroy ]

    def index
      @attendances = Attendance.includes(:person, :event)

      # Filtres
      if params[:person_id].present?
        @attendances = @attendances.where(person_id: params[:person_id])
      end

      if params[:event_id].present?
        @attendances = @attendances.where(event_id: params[:event_id])
      end

      if params[:date].present?
        @attendances = @attendances.where(date: params[:date])
      end

      if params[:today].present?
        @attendances = @attendances.today
      end

      # Pagination
      @attendances = @attendances.order(date: :desc).page(params[:page]).per(20)

      add_breadcrumb "Gestion des présences", nil
    end

    def show
      add_breadcrumb "Gestion des présences", admin_attendances_path
      add_breadcrumb "Présence ##{@attendance.id}", nil
    end

    def new
      @attendance = Attendance.new
      @people = Person.order(:first_name, :last_name)
      @events = Event.upcoming.order(:date)

      add_breadcrumb "Gestion des présences", admin_attendances_path
      add_breadcrumb "Nouvelle présence", nil
    end

    def create
      begin
        # Créer la présence directement
        attendance = Attendance.create!(
          person_id: attendance_params[:person_id],
          event_id: attendance_params[:event_id],
          attended_at: attendance_params[:attended_at] || Time.current,
          notes: attendance_params[:notes]
        )

        redirect_to admin_attendance_path(attendance), notice: "Présence enregistrée avec succès"
      rescue => e
        @attendance = Attendance.new(attendance_params)
        @people = Person.order(:first_name, :last_name)
        @events = Event.upcoming.order(:date)
        flash.now[:alert] = "Erreur: #{e.message}"
        render :new
      end
    end

    def destroy
      if @attendance.destroy
        redirect_to admin_attendances_path, notice: "Présence supprimée avec succès"
      else
        redirect_to admin_attendances_path, alert: "Erreur lors de la suppression"
      end
    end

    private

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.require(:attendance).permit(:person_id, :event_id, :date, :book_of_entry_id)
    end
  end
end
