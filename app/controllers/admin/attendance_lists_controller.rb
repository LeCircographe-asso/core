module Admin
  class AttendanceListsController < BaseController
    before_action :set_attendance_list, only: [ :show, :edit, :update, :destroy ]
    before_action :set_breadcrumbs

    def index
      @attendance_list = AttendanceList.all.order(created_at: :desc)
      add_breadcrumb "Listes de présence", nil
    end

    def new
      add_breadcrumb "Listes de présence", admin_attendance_lists_path
      add_breadcrumb "Nouvelle liste", nil
    end

    def show
      add_breadcrumb "Listes de présence", admin_attendance_lists_path
      add_breadcrumb @attendance_list.name, nil
    end

    def edit
      add_breadcrumb "Listes de présence", admin_attendance_lists_path
      add_breadcrumb @attendance_list.name, admin_attendance_list_path(@attendance_list)
      add_breadcrumb "Modifier", nil
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
      @attendance_list = AttendanceList.find(params[:id])
    end

    def attendance_list_params
      params.require(:attendance_list).permit(:name, :status, :list_type, :start_date)
    end

    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end
  end
end
