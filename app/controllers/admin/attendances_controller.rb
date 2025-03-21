module Admin
  class AttendancesController < BaseController
    def index
       @users = AttendanceList.find(params[:attendance_list_id]).users
       p 
    end
    def new
      @me_attendance_list = AttendanceList.find_by(id: params[:attendance_list_id])
      @users_not_in_list = User.where.not(id: @me_attendance_list.users.select(:id))
      
    end

    def create
      attendance = Attendance.new
      attendance.attendance_list = AttendanceList.find(params[:attendance_list_id])
      attendance.user = User.find(params[:user_id])
      attendance.arrival_time = Time.current

      if attendance.save
        redirect_to admin_attendance_list_attendances_path(params[:attendance_list_id]), notice: "Utilisateur ajouté avec succès."
      else 
        render :new, alert: "Une erreur est survenue. Veuillez réessayer."
      end
    end
  end
end