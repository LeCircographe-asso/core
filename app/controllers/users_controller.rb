class UsersController < ApplicationController
  # This controller handles user profile management for authenticated users.
  # It allows users to view and edit their profile information and
  # delete their account (GDPR compliance).
  #
  # Note: New user registration is handled by RegistrationsController.
  # This separation follows the principle of single responsibility:
  # - RegistrationsController: Creating new accounts
  # - UsersController: Managing existing accounts
  # - SessionsController: Handling login/logout
  include UsersHelper
  before_action :require_authentication, except: [ :change_newsletter_status, :newsletter_signup ]
  before_action :set_user, only: [ :show, :edit, :update, :change_newsletter_status, :destroy ]

  # User profile view
  def show
  end

  # User profile edit form
  def edit
  end

  # User profile update
  def update
    # Mettre à jour les données de la Person liée
    if @user.person&.update(person_params)
      redirect_to @user, notice: "Votre profil a été mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Account deletion
  def destroy
    # Delete the user and transfer payments to admin
    if @user.destroy
      # End the user's session
      reset_session
      redirect_to root_path, notice: "Votre compte a été supprimé avec succès."
    else
      redirect_to edit_user_path(@user), alert: "Impossible de supprimer votre compte. Veuillez contacter l'assistance."
    end
  end

  # Newsletter subscription management
  def change_newsletter_status
    if params[:token].present?
      unsubscribe_by_token
    else
      toggle_newsletter_status
    end
  end

  # Handle newsletter signup from footer
  def newsletter_signup
    # Check honeypot - if filled, it's likely a bot
    if params[:user][:website].present?
      # Don't show an error, just silently redirect to avoid tipping off bots
      redirect_back fallback_location: root_path, notice: "Merci pour votre inscription!"
      return
    end

    email = params[:user][:email_address]

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

  private

  # Handle token-based unsubscription (public access)
  def unsubscribe_by_token
    subscriber = NewsletterSubscriber.find_by(unsubscribe_token: params[:token])
    if subscriber
      subscriber.unsubscribe!
      redirect_to page_path("newsletter_unsubscribe_success")
    else
      redirect_to root_path, alert: "Token de désinscription invalide."
    end
  end

  # Toggle newsletter subscription status for authenticated user
  def toggle_newsletter_status
    return redirect_to root_path, alert: "Vous devez être connecté" unless @user

    # Use NewsletterSignupService to manage subscription via NewsletterSubscriber model
    result = NewsletterSignupService.new(@user.email_address, @user).call_newsletter
    
    if result[:success]
      message = result[:message]
    else
      message = "Erreur: #{result[:message]}"
    end
    
    redirect_to @user, notice: message
  end

  # Set user to current user for profile actions
  def set_user
    @user = Current.user
  end

  # Permitted parameters for person data (migrated from user)
  def person_params
    params.require(:user).permit(
      :phone,
      :address,
      :zip_code,
      :town,
      :country,
      :image_rights,
      :get_involved,
      :newsletter_subscribed,
      :dyslexic_font
    )
  end

  # Helper method renamed to avoid conflict
  def process_newsletter_signup(email)
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
