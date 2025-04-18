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
      attendance_list = AttendanceList.new(attendance_list_params)

      # Set default start date to current time if not provided
      attendance_list.start_date = Time.current if attendance_list.start_date.blank?

      # Set end date to end of the day
      attendance_list.end_date = attendance_list.start_date.change(hour: 23, min: 59, sec: 59)

      if attendance_list.save
        redirect_to admin_attendance_lists_path, notice: "Liste de présence créée avec succès !"
      else
        flash.now[:error] = "Erreur lors de la création de la liste : #{attendance_list.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @attendance_list.update(attendance_list_params)
        redirect_to admin_attendance_lists_path, notice: "Liste de présence mise à jour avec succès !"
      else
        flash.now[:error] = "Erreur lors de la mise à jour de la liste : #{@attendance_list.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @attendance_list.destroy
      redirect_to admin_attendance_lists_path, notice: "La liste a été supprimée avec succès."
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
