# frozen_string_literal: true

class SettingsController < ApplicationController
  include ProfileSectionTurboStreams

  before_action :require_authentication

  def show
    @user = current_user
  end

  def update
    @user = current_user
    profile_context = params[:ui_context] == "profile"

    user_only_params = user_params.slice(:email_address)
    person_params = user_params.except(:email_address)
    newsletter_flag = person_params.delete(:newsletter_subscribed)

    updater = UserManagement::UserUpdater.new(
      user_id: @user.id,
      email_address: user_only_params[:email_address],
      person_attributes: person_params,
      newsletter_subscribed: [ "1", true, 1 ].include?(newsletter_flag),
      updated_by_id: @user.id
    )

    result = updater.call

    if result.success?
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = t(".saved_notice")
          render turbo_stream: profile_account_section_update_streams(
            @user,
            embedded: profile_context,
            compact: profile_context
          )
        end
        format.html { redirect_to settings_path, notice: t(".saved_notice"), status: :see_other }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = result.message
          render turbo_stream: profile_account_section_update_streams(
            @user,
            embedded: profile_context,
            compact: profile_context
          ), status: :unprocessable_content
        end
        format.html do
          flash.now[:alert] = result.message
          render :show, status: :unprocessable_content
        end
      end
    end
  end

  private

  def user_params
    params.expect(
      user: %i[email_address image_rights
               newsletter_subscribed get_involved
               dyslexic_font]
    )
  end
end
