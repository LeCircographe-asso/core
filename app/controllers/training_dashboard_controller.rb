class TrainingDashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @current_session = TrainingSession.current_or_create(recorded_by: current_user)
    @stats = TrainingSessionReportService.calculate_attendance_stats(Date.current)
    
    # Pour Turbo Streams
    @attendees = @current_session.training_attendees.includes(:user)
  end

  def check_in
    @session = TrainingSession.current_or_create(recorded_by: current_user)
    @attendee = @session.add_attendee!(params[:user_id], recorded_by: current_user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to training_dashboard_path }
    end
  end

  def check_out
    @session = TrainingSession.current_or_create(recorded_by: current_user)
    @attendee = @session.training_attendees.find_by(user_id: params[:user_id])
    @attendee.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to training_dashboard_path }
    end
  end
end 