# frozen_string_literal: true

module Admin
  class AttendancesController < BaseController
    before_action :set_attendance, only: %i[show destroy]

    def index
      @attendances = Attendance.includes(:person, :event)

      # Filtres
      @attendances = @attendances.where(person_id: params[:person_id]) if params[:person_id].present?

      @attendances = @attendances.where(event_id: params[:event_id]) if params[:event_id].present?

      @attendances = @attendances.where(date: params[:date]) if params[:date].present?

      @attendances = @attendances.today if params[:today].present?

      # Pagination
      @attendances = @attendances.order(date: :desc).page(params[:page]).per(20)

      add_breadcrumb 'Gestion des présences', nil
    end

    def show
      add_breadcrumb 'Gestion des présences', admin_attendances_path
      add_breadcrumb "Présence ##{@attendance.id}", nil
    end

    def new
      @attendance = Attendance.new
      @people = Person.order(:first_name, :last_name)
      @events = Event.upcoming.order(:date)

      add_breadcrumb 'Gestion des présences', admin_attendances_path
      add_breadcrumb 'Nouvelle présence', nil
    end

    def create
      creator = AttendanceManagement::AttendanceCreator.new(
        person_id: attendance_params[:person_id],
        event_id: attendance_params[:event_id],
        attendance_list_id: attendance_params[:attendance_list_id],
        contribution_id: attendance_params[:contribution_id],
        date: attendance_params[:date]
      )

      result = creator.call

      if result.success?
        redirect_to admin_attendance_path(result.attendance), notice: 'Présence enregistrée avec succès'
      else
        @attendance = Attendance.new(attendance_params)
        @people = Person.order(:first_name, :last_name)
        @events = Event.upcoming.order(:date)
        flash.now[:alert] = "Erreur: #{result.message}"
        render :new
      end
    rescue StandardError => e
      @attendance = Attendance.new(attendance_params)
      @people = Person.order(:first_name, :last_name)
      @events = Event.upcoming.order(:date)
      flash.now[:alert] = "Erreur: #{e.message}"
      render :new
    end

    def destroy
      if @attendance.destroy
        redirect_to admin_attendances_path, notice: 'Présence supprimée avec succès'
      else
        redirect_to admin_attendances_path, alert: 'Erreur lors de la suppression'
      end
    end

    private

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.expect(attendance: %i[person_id event_id date contribution_id attendance_list_id notes]).tap do |permitted|
        legacy = params[:attendance][:book_of_entry_id]
        permitted[:contribution_id] ||= legacy if legacy.present?
      end
    end
  end
end
