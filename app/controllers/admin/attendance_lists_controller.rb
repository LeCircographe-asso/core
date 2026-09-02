# frozen_string_literal: true

module Admin
  class AttendanceListsController < BaseController
    before_action :set_attendance_list, only: %i[show edit update destroy]
    before_action :set_breadcrumbs

    def index
      scope = AttendanceList.all

      # Filter by list_type (training/event/meeting)
      scope = scope.where(list_type: params[:list_type]) if params[:list_type].present?

      # Search by name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        scope = scope.where("name LIKE ? COLLATE NOCASE", search_term)
      end

      # Filter by status
      scope = scope.where(status: params[:status]) if params[:status].present?

      # Filter by month (on start_date)
      if params[:month].present?
        begin
          month = Date.parse("#{params[:month]}-01")
          month_start = month.beginning_of_month
          month_end = month.end_of_month
          scope = scope.where(start_date: month_start..month_end)
        rescue StandardError
          # Invalid month format, skip filter
        end
      end

      # Sort by start_date (default desc = most recent first)
      sort = params[:sort] == "asc" ? :asc : :desc
      scope = scope.order(start_date: sort)

      # Pagination
      @pagy, @attendance_list = pagy(scope, items: 20)

      add_breadcrumb I18n.t("breadcrumbs.admin.attendance_lists.lists"), nil
    end

    def show
      add_breadcrumb I18n.t("breadcrumbs.admin.attendance_lists.lists"), admin_attendance_lists_path
      add_breadcrumb @attendance_list.name, nil
    end

    def new
      add_breadcrumb I18n.t("breadcrumbs.admin.attendance_lists.lists"), admin_attendance_lists_path
      add_breadcrumb I18n.t("breadcrumbs.admin.attendance_lists.new_list"), nil
    end

    def edit
      add_breadcrumb I18n.t("breadcrumbs.admin.attendance_lists.lists"), admin_attendance_lists_path
      add_breadcrumb @attendance_list.name, admin_attendance_list_path(@attendance_list)
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    def create
      creator = AttendanceListManagement::AttendanceListCreator.new(
        name: attendance_list_params[:name],
        status: attendance_list_params[:status],
        list_type: attendance_list_params[:list_type],
        start_date: attendance_list_params[:start_date],
        created_by_id: Current.user.id
      )

      result = creator.call

      if result.success?
        redirect_to admin_attendance_lists_path, notice: result.message
      else
        flash.now[:error] = result.message
        render :new, status: :unprocessable_content
      end
    end

    def update
      updater = AttendanceListManagement::AttendanceListUpdater.new(
        attendance_list_id: @attendance_list.id,
        name: attendance_list_params[:name],
        status: attendance_list_params[:status],
        list_type: attendance_list_params[:list_type],
        start_date: attendance_list_params[:start_date],
        updated_by_id: Current.user.id
      )

      result = updater.call

      if result.success?
        redirect_to admin_attendance_lists_path, notice: result.message
      else
        flash.now[:error] = result.message
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      deleter = AttendanceListManagement::AttendanceListDeleter.new(
        attendance_list_id: @attendance_list.id,
        deleted_by_id: Current.user.id
      )

      result = deleter.call

      if result.success?
        redirect_to admin_attendance_lists_path, notice: result.message
      else
        redirect_to admin_attendance_lists_path, alert: result.message
      end
    end

    private

    def set_attendance_list
      @attendance_list = AttendanceList.find(params.expect(:id))
    end

    def attendance_list_params
      params.expect(attendance_list: %i[name status list_type start_date])
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
    end
  end
end
