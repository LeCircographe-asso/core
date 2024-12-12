module UsersHelper
    def newsletter_signup(email)

    if email.blank?
      flash[:alert] = "Veuillez entrer une adresse email valide."
      redirect_back fallback_location: root_path
      return
    end

    result = NewsletterSignupService.new(email, authenticated? ? Current.user : nil).call_newsletter

    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:alert] = result[:message]
    end

    redirect_back fallback_location: root_path
  end
end
