module Admin
  class AttendancesController < BaseController
    before_action :set_attendance_list, only: [ :index, :new, :create ]
    before_action :set_breadcrumbs

    def index
      @users = @attendance_list.users
      add_breadcrumb "Listes de présence", admin_attendance_lists_path
      add_breadcrumb @attendance_list.name, admin_attendance_list_path(@attendance_list)
      add_breadcrumb "Participants", nil
    end

    def new
      @users_not_in_list = User.where.not(id: @attendance_list.users.select(:id))
      add_breadcrumb "Listes de présence", admin_attendance_lists_path
      add_breadcrumb @attendance_list.name, admin_attendance_list_path(@attendance_list)
      add_breadcrumb "Participants", admin_attendance_list_attendances_path(@attendance_list)
      add_breadcrumb "Ajouter un participant", nil
    end

    def create
      @user = User.find(params[:user_id])

      @has_valid_membership = @user.user_memberships.joins(:membership)
      .where(user_memberships: { status: "active" })
      .where(memberships: { type_name: [ "Circus", "Basic" ] })
      .exists?

      attendance = Attendance.new
      attendance.attendance_list = @attendance_list
      attendance.user = User.find(params[:user_id])
      attendance.arrival_time = Time.current
      puts "################################################"
      puts "#{attendance.user.book_of_entries.first}" "*********************************************************************"
      book_of_entry = attendance.user.book_of_entries.first

      if book_of_entry
        attendance.book_of_entry = book_of_entry
      end

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

    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end
  end
end
