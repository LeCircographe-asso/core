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
    # Utiliser le service UserManagement::UserUpdater
    updater = UserManagement::UserUpdater.new(
      user_id: @user.id,
      person_attributes: person_params,
      updated_by_id: @user.id
    )

    result = updater.call

    if result.success?
      redirect_to @user, notice: "Votre profil a été mis à jour avec succès."
    else
      flash.now[:alert] = result.message
      render :edit, status: :unprocessable_content
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

  # Newsletter subscription management (legacy, redirect to settings)
  def change_newsletter_status
    redirect_to settings_path, alert: "Gérez votre newsletter depuis vos paramètres."
  end

  # Handle newsletter signup from footer
  def newsletter_signup
    # Extract from UsersHelper (anti-pattern: helpers shouldn't redirect)
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

    # If authenticated, redirect to settings (no form for connected users)
    if authenticated? && Current.user.present?
      redirect_to settings_path, notice: "Gérez votre newsletter depuis vos paramètres en cochant/décochant la case."
      return
    end

    result = People::NewsletterSignup.new(email: email, source: "web").call

    if result.redirect_to
      redirect_to new_session_path, alert: result.message
    elsif result.success?
      flash[:notice] = result.message
      redirect_back fallback_location: root_path
    else
      flash[:alert] = result.message
      redirect_back fallback_location: root_path
    end
  end

  # Handle token-based unsubscription (public access from emails)
  def unsubscribe_by_token
    subscriber = NewsletterSubscriber.find_by(unsubscribe_token: params[:token])
    if subscriber
      subscriber.unsubscribe!
      redirect_to page_path("newsletter_unsubscribe_success")
    else
      redirect_to root_path, alert: "Token de désinscription invalide."
    end
  end

  private

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
end
