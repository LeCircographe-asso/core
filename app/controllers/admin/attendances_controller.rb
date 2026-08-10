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
      @pagy, @attendances = pagy(@attendances.order(date: :desc), items: 20)

      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.management"), nil
    end

    def show
      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.management"), admin_attendances_path
      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.attendance_number", id: @attendance.id), nil
    end

    def new
      @attendance_list = AttendanceList.find(params[:attendance_list_id]) if params[:attendance_list_id]

      already_added_person_ids = @attendance_list ? @attendance_list.attendances.pluck(:person_id) : []
      @people_available = Person.order(:first_name, :last_name).where.not(id: already_added_person_ids)

      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.management"), admin_attendances_path
      add_breadcrumb I18n.t("breadcrumbs.admin.attendances.new_attendance"), nil
    end

    def create
      attendance_list_id = attendance_params[:attendance_list_id].presence || params[:attendance_list_id]

      creator = AttendanceManagement::AttendanceCreator.new(
        person_id: attendance_params[:person_id],
        event_id: attendance_params[:event_id],
        attendance_list_id: attendance_list_id,
        contribution_id: attendance_params[:contribution_id],
        date: attendance_params[:date]
      )

      result = creator.call

      if result.success?
        redirect_to after_attendance_create_path(attendance_list_id, result.attendance), notice: t(".success")
      else
        redirect_to after_attendance_create_path(attendance_list_id), alert: "Erreur: #{result.message}"
      end
    rescue StandardError => e
      redirect_to after_attendance_create_path(attendance_list_id), alert: "Erreur: #{e.message}"
    end

    def destroy
      redirect_target = @attendance.attendance_list_id ? admin_attendance_list_path(@attendance.attendance_list_id) : admin_attendances_path

      result = AttendanceManagement::AttendanceRemover.new(
        attendance_id: @attendance.id,
        deleted_by_id: Current.user.id
      ).call

      if result.success?
        redirect_to redirect_target, notice: t(".destroyed")
      else
        redirect_to redirect_target, alert: result.message
      end
    end

    private

    def after_attendance_create_path(attendance_list_id, attendance = nil)
      return admin_attendance_list_path(attendance_list_id) if attendance_list_id.present?

      attendance ? admin_attendance_path(attendance) : admin_attendances_path
    end

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.expect(attendance: %i[person_id event_id date contribution_id attendance_list_id notes])
    end
  end
end
