module UsersHelper
  def newsletter_signup(email)
    if email.blank?
      flash[:alert] = "Veuillez entrer une adresse email valide."
      redirect_back fallback_location: root_path
      return
    end

    result = NewsletterSignupService.new(email, authenticated? ? Current.user : nil).call_newsletter

    if result[:redirect_to]
      redirect_to new_registration_path
      session[:newsletter_email] = email
    elsif result[:success]
      flash[:notice] = result[:message]
      redirect_back fallback_location: root_path
    else
      flash[:alert] = result[:message]
      redirect_back fallback_location: root_path
    end
  end
end
