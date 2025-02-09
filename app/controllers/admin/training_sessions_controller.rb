class Admin::TrainingSessionsController < Admin::BaseController
  include ActionController::MimeResponds
  include ActionController::Live
  
  before_action :set_training_session, only: [:show]

  def show
    @training_session = TrainingSession.find_or_create_by(date: Date.current) do |session|
      session.status = :open
      session.recorded_by = current_user
    end
    @attendees = @training_session.training_attendees.includes(:user, :user_membership)
    @search_results = [] # Sera rempli par la recherche
  end

  def search_users
    query = params[:query].to_s.strip
    @users = User.where("LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query OR LOWER(email_address) LIKE :query", 
                       query: "%#{query.downcase}%")
                 .includes(:user_memberships)
                 .limit(10)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("search_results", partial: "search_results", locals: { users: @users }) }
      format.html { redirect_to admin_training_session_path(@training_session) }
    end
  end

  def add_attendance
    @user = User.find(params[:user_id])
    @training_session = TrainingSession.today

    # Trouver l'adhésion active appropriée
    @membership = if params[:is_visitor] == "true"
      @user.user_memberships.active.joins(:subscription_type)
           .where(subscription_types: { category: [:basic_membership, :circus_membership] })
           .first
    else
      @user.user_memberships.active.joins(:subscription_type)
           .where(subscription_types: { category: [:ten_sessions, :quarterly, :yearly] })
           .first
    end

    if @membership.nil?
      path = if params[:is_visitor] == "true"
        new_admin_member_path(user_id: @user.id)
      else
        membership_register_admin_members_path(user_id: @user.id)
      end
      
      render turbo_stream: turbo_stream.append("flash_messages", 
        partial: "shared/flash",
        locals: { type: :error, message: "Adhésion requise", redirect_path: path })
      return
    end

    @attendance = TrainingAttendee.new(
      user: @user,
      training_session: @training_session,
      user_membership: @membership,
      checked_by: current_user,
      check_in_time: Time.current,
      is_visitor: params[:is_visitor] == "true"
    )

    if @attendance.save
      render turbo_stream: [
        turbo_stream.append("attendees_list", 
          partial: "admin/training_sessions/attendee", 
          locals: { attendee: @attendance }),
        turbo_stream.update("search_results", ""),
        turbo_stream.append("flash_messages",
          partial: "shared/flash",
          locals: { type: :success, message: "Présence enregistrée" })
      ]
    else
      render turbo_stream: turbo_stream.append("flash_messages",
        partial: "shared/flash",
        locals: { type: :error, message: @attendance.errors.full_messages.join(", ") })
    end
  end

  private

  def set_training_session
    @training_session = TrainingSession.find(params[:id])
  end
end 