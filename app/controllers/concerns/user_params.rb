module UserParams
  extend ActiveSupport::Concern

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
