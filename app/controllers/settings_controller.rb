# frozen_string_literal: true

class SettingsController < ApplicationController
  include ProfileSectionTurboStreams
  include NewsletterParamParser

  before_action :require_authentication

  def show
    @user = current_user
  end

  def update
    @user = current_user
    profile_context = params[:ui_context] == "profile"

    if email_change_flow?
      return handle_email_change(profile_context)
    end

    user_only_params = user_params.slice(:email_address)
    person_params = user_params.except(:email_address)
    newsletter_subscribed_value = extract_newsletter_subscribed!(
      source_params: user_params,
      person_params: person_params
    )

    updater = UserManagement::UserUpdater.new(
      user_id: @user.id,
      email_address: user_only_params[:email_address],
      person_attributes: person_params,
      newsletter_subscribed: newsletter_subscribed_value,
      updated_by_id: @user.id
    )

    result = updater.call

    return render_profile_section_success(t(".saved_notice"), profile_context) if result.success?

    render_profile_section_error(result.message, profile_context)
  end

  private

  def user_params
    params.expect(
      user: %i[email_address image_rights
               newsletter_subscribed get_involved
               dyslexic_font]
    )
  end

  def email_change_flow?
    params.key?(:email_confirm) || params.key?(:email_verification_code)
  end

  def handle_email_change(profile_context)
    new_email = params.dig(:user, :email_address).to_s.strip.downcase
    email_confirm = params[:email_confirm].to_s.strip.downcase
    verification_code = params[:email_verification_code].to_s.strip

    if verification_code.present?
      confirm_email_change!(new_email:, email_confirm:, verification_code:, profile_context:)
    else
      request_email_change_code!(new_email:, email_confirm:, profile_context:)
    end
  end

  def request_email_change_code!(new_email:, email_confirm:, profile_context:)
    return render_email_change_error(t("settings.update.email_change_error_blank"), profile_context) if new_email.blank? || email_confirm.blank?
    return render_email_change_error(t("settings.update.email_change_error_mismatch"), profile_context) if new_email != email_confirm
    return render_email_change_error(t("settings.update.email_change_error_unchanged"), profile_context) if new_email == @user.email_address.to_s.downcase
    return render_email_change_error(t("settings.update.email_change_error_taken"), profile_context) if User.where.not(id: @user.id).exists?(email_address: new_email)

    code = format("%06d", SecureRandom.random_number(1_000_000))
    @user.store_email_change_request!(new_email:, code:)
    UserMailer.email_change_verification(@user, new_email, code).deliver_now

    render_email_change_success(
      t("settings.update.email_change_code_sent_notice", email: new_email),
      profile_context
    )
  rescue StandardError => e
    Rails.logger.error("[SettingsController] email change code request failed: #{e.message}")
    render_email_change_error(t("settings.update.email_change_error_send_failed"), profile_context)
  end

  def confirm_email_change!(new_email:, email_confirm:, verification_code:, profile_context:)
    return render_email_change_error(t("settings.update.email_change_error_no_request"), profile_context) if @user.pending_email_address.blank?
    return render_email_change_error(t("settings.update.email_change_error_expired"), profile_context) if @user.email_change_code_expired?
    return render_email_change_error(t("settings.update.email_change_error_mismatch"), profile_context) if new_email.blank? || email_confirm.blank? || new_email != email_confirm
    return render_email_change_error(t("settings.update.email_change_error_pending_mismatch"), profile_context) if @user.pending_email_address != new_email
    return render_email_change_error(t("settings.update.email_change_error_invalid_code"), profile_context) unless @user.email_change_code_valid?(verification_code)

    @user.update!(email_address: @user.pending_email_address)
    @user.clear_email_change_request!

    render_email_change_success(t("settings.update.email_change_success_notice"), profile_context)
  rescue ActiveRecord::RecordInvalid => e
    render_email_change_error(e.record.errors.full_messages.to_sentence, profile_context)
  rescue StandardError => e
    Rails.logger.error("[SettingsController] email change confirmation failed: #{e.message}")
    render_email_change_error(t("settings.update.email_change_error_confirm_failed"), profile_context)
  end

  def render_email_change_success(message, profile_context)
    render_profile_section_success(message, profile_context, reload_user: true)
  end

  def render_email_change_error(message, profile_context)
    render_profile_section_error(message, profile_context)
  end

  def render_profile_section_success(message, profile_context, reload_user: false)
    account_user = reload_user ? @user.reload : @user

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = message
        render turbo_stream: profile_account_section_update_streams(
          account_user,
          embedded: profile_context,
          compact: profile_context
        )
      end
      format.html { redirect_to settings_path, notice: message, status: :see_other }
    end
  end

  def render_profile_section_error(message, profile_context)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        render turbo_stream: profile_account_section_update_streams(
          @user,
          embedded: profile_context,
          compact: profile_context
        ), status: :unprocessable_content
      end
      format.html do
        flash.now[:alert] = message
        render :show, status: :unprocessable_content
      end
    end
  end
end
