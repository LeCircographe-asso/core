module Admin
  class AttendancesController < BaseController
    before_action :set_attendance_list, only: [ :index, :new, :create ]

    def index
      @users = @attendance_list.users
    end

    def new
      @users_not_in_list = User.where.not(id: @attendance_list.users.select(:id))
    end

    def create
      attendance = Attendance.new
      attendance.attendance_list = @attendance_list
      attendance.user = User.find(params[:user_id])
      attendance.arrival_time = Time.current

      if attendance.save
        redirect_to admin_attendance_list_attendances_path(@attendance_list),
          notice: "#{attendance.user.first_name} #{attendance.user.last_name} a été ajouté(e) avec succès."
      else
        flash[:error] = "Une erreur est survenue lors de l'ajout du participant : #{attendance.errors.full_messages.join(', ')}"
        redirect_to new_admin_attendance_list_attendance_path(@attendance_list)
      end
    end

    private

    def set_attendance_list
      @attendance_list = AttendanceList.find(params[:attendance_list_id])
    end
  end
end
