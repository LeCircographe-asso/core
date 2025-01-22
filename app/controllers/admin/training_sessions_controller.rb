class Admin::TrainingSessionsController < AdminController
  def index
    @session = TrainingSession.current_or_create(recorded_by: current_user)
    @recent_attendees = @session.training_attendees.includes(:user).order(created_at: :desc)
    
    if params[:search].present?
      @users = User.circus_membership
                   .where("first_name ILIKE :q OR last_name ILIKE :q", q: "%#{params[:search]}%")
                   .includes(:current_subscription)
    end
  end

  def add_attendee
    @session = TrainingSession.current_or_create(recorded_by: current_user)
    @user = User.find(params[:user_id])

    if @session.add_attendee!(@user)
      redirect_to admin_training_sessions_path, notice: "#{@user.first_name} ajouté à l'entraînement"
    else
      redirect_to admin_training_sessions_path, 
                  alert: "Impossible d'ajouter #{@user.first_name} (abonnement invalide)"
    end
  end
end 