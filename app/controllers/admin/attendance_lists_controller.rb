module Admin
  class AttendanceListsController < BaseController
    def new
    end
    
    
    def index
      @attendance_list = AttendanceList.all
    end

    def create
    
      attendance_list = AttendanceList.new(attendance_list_params)
      attendance_list.end_date = attendance_list.start_date.change(hour: 23, min: 59, sec: 0)
      if attendance_list.save
        redirect_to admin_attendance_lists_path, motice: "Liste créée avec succé."
      else
        render :new, notice: "erreur veuillez recomencer"
      end

    end

    private

    def attendance_list_params
      params.require(:attendance_list).permit(:list_type, :start_date)
    end 
      

  end
end