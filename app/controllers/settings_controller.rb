# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :require_authentication
  def show
    @user = current_user
  end

  def update
    @user = current_user

    # Séparer les paramètres User des paramètres Person
    user_only_params = user_params.slice(:email_address)
    person_params = user_params.except(:email_address)
    newsletter_flag = person_params.delete(:newsletter_subscribed)

    # Utiliser le service UserManagement::UserUpdater
    updater = UserManagement::UserUpdater.new(
      user_id: @user.id,
      email_address: user_only_params[:email_address],
      person_attributes: person_params,
      newsletter_subscribed: [ "1", true, 1 ].include?(newsletter_flag),
      updated_by_id: @user.id
    )

    result = updater.call

    if result.success?
      flash[:notice] = "Vos modifications ont été enregistrées avec succès"
      redirect_to user_path(@user), status: :see_other
    else
      flash.now[:alert] = result.message
      render :show, status: :unprocessable_content
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
