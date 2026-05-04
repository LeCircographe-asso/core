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

      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.management"), nil
    end

    def show
      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.management"), admin_attendances_path
      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.attendance_number", id: @attendance.id), nil
    end

    def new
      @attendance = Attendance.new
      @people = Person.order(:first_name, :last_name)
      @events = Event.upcoming.order(:date)

      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.management"), admin_attendances_path
      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.new_attendance"), nil
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
        redirect_to admin_attendance_path(result.attendance), notice: t(".success")
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
        redirect_to admin_attendances_path, notice: t(".destroyed")
      else
        redirect_to admin_attendances_path, alert: t(".failure")
      end
    end

    private

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.expect(attendance: %i[person_id event_id date contribution_id attendance_list_id notes])
    end
  end
end
