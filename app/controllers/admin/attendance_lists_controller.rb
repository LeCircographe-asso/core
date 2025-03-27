module Admin
  class AttendanceListsController < BaseController
    before_action :set_attendance_list, only: [ :show, :edit, :update ]

    def index
      @attendance_list = AttendanceList.all.order(created_at: :desc)
    end

    def new
    end

    def show
    end

    def edit
    end

    def create
      attendance_list = AttendanceList.new(attendance_list_params)
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

    private

    def set_attendance_list
      @attendance_list = AttendanceList.find(params[:id])
    end

    def attendance_list_params
      params.require(:attendance_list).permit(:list_type, :start_date, :status)
    end
  end
end
