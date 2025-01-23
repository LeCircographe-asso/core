module Admin
  class TrainingDashboardController < BaseController
    def index
      @current_session = TrainingSession.current_or_create(recorded_by: current_user)
      @stats = TrainingSessionReportService.calculate_attendance_stats(Date.current)
      @attendees = @current_session.training_attendees
                    .includes(:user, :user_membership)
                    .order(created_at: :desc)
      
      # Recherche d'utilisateurs
      @query = params[:query]
      @users = User.search(@query) if @query.present?
    end

    def check_in
      @session = TrainingSession.current_or_create(recorded_by: current_user)
      @attendee = @session.add_attendee!(params[:user_id], recorded_by: current_user)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_training_dashboard_path }
      end
    end

    def check_out
      @session = TrainingSession.current_or_create(recorded_by: current_user)
      @attendee = @session.training_attendees.find_by(user_id: params[:user_id])
      @attendee.destroy

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_training_dashboard_path }
      end
    end

    def add_attendee
      @session = TrainingSession.current_or_create(recorded_by: current_user)
      @user = User.find(params[:user_id])

      if @user.can_train_today?
        @attendee = @session.add_attendee!(@user)
        flash[:notice] = "#{@user.full_name} ajouté à la session"
      else
        if !@user.current_subscription
          redirect_to new_admin_member_path(user_id: @user.id), 
                      notice: "L'utilisateur doit d'abord avoir une adhésion valide"
          return
        else
          flash[:alert] = "L'utilisateur ne peut pas s'entraîner aujourd'hui"
        end
      end

      redirect_to admin_training_dashboard_path
    end
  end
end 