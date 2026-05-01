# frozen_string_literal: true

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
  before_action :require_authentication, except: %i[change_newsletter_status newsletter_signup]
  before_action :set_user, only: %i[show edit update change_newsletter_status destroy]

  # User profile view
  def show; end

  # User profile edit form — unified on users#show (#contact)
  def edit
    redirect_to user_path(@user, anchor: "contact"), status: :see_other
  end

  # User profile update (postal / phone coordinates only; account email & prefs → Settings)
  def update
    updater = UserManagement::UserUpdater.new(
      user_id: @user.id,
      person_attributes: coordinate_params,
      updated_by_id: @user.id
    )

    result = updater.call

    if result.success?
      redirect_to user_path(@user, anchor: "contact"), notice: t(".coordinates_updated")
    else
      flash.now[:alert] = result.message
      render :show, status: :unprocessable_content
    end
  end

  # Account deletion
  def destroy
    # Delete the user and transfer payments to admin
    if @user.destroy
      # End the user's session
      reset_session
      redirect_to root_path, notice: t(".deleted_notice")
    else
      redirect_to user_path(@user, anchor: "account"), alert: t(".destroy_failed_alert")
    end
  end

  # Newsletter subscription management (legacy, redirect to settings)
  def change_newsletter_status
      redirect_to user_path(Current.user, anchor: "account"), alert: t(".redirect_manage_in_settings_alert")
  end

  # Handle newsletter signup from footer
  def newsletter_signup
    # Extract from UsersHelper (anti-pattern: helpers shouldn't redirect)
    # Check honeypot - if filled, it's likely a bot
    if params[:user][:website].present?
      # Don't show an error, just silently redirect to avoid tipping off bots
      redirect_back_or_to(root_path, notice: t(".honeypot_thanks_notice"))
      return
    end

    email = params[:user][:email_address]

    if email.blank?
      flash[:alert] = t(".email_blank_alert")
      redirect_back_or_to(root_path)
      return
    end

    # If authenticated, redirect to settings (no form for connected users)
    if authenticated? && Current.user.present?
      redirect_to user_path(Current.user, anchor: "account"), notice: t(".manage_newsletter_notice")
      return
    end

    result = People::NewsletterSignup.new(email: email, source: "web").call

    if result.redirect_to
      redirect_to new_session_path, alert: result.message
    elsif result.success?
      flash[:notice] = result.message
      redirect_back_or_to(root_path)
    else
      flash[:alert] = result.message
      redirect_back_or_to(root_path)
    end
  end

  # Handle token-based unsubscription (public access from emails)
  def unsubscribe_by_token
    subscriber = NewsletterSubscriber.find_by(unsubscribe_token: params[:token])
    if subscriber
      subscriber.unsubscribe!
      redirect_to page_path("newsletter_unsubscribe_success")
    else
      redirect_to root_path, alert: t(".invalid_token_alert")
    end
  end

  private

  # Set user to current user for profile actions
  def set_user
    @user = Current.user
  end

  # Postal / phone fields only (email & preference toggles use SettingsController)
  def coordinate_params
    params.expect(
      user: %i[phone address zip_code town country]
    )
  end
end
