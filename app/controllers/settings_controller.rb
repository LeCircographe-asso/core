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

    # Mettre à jour User et Person séparément
    user_updated = @user.update(user_only_params)

    # Pour les comptes web, désactiver temporairement la validation d'adhésion
    person_updated = if @user.person.present?
      @user.person.skip_membership_validation = true
      @user.person.update(person_params)
    else
      true # Pas de Person à mettre à jour
    end

    # Gérer newsletter via NewsletterSubscriber
    if person_updated && @user.person.present?
      handle_newsletter_update(@user.person, newsletter_flag)
    end

    if user_updated && (person_params.empty? || person_updated)
      flash[:notice] = "Vos modifications ont été enregistrées avec succès"
      redirect_to user_path(@user), status: :see_other
    else
      # Collecter les erreurs
      errors = []
      errors.concat(@user.errors.full_messages) if @user.errors.any?
      errors.concat(@user.person.errors.full_messages) if @user.person&.errors&.any?
      flash.now[:alert] = errors.join(", ")
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email_address, :image_rights,
      :newsletter_subscribed, :get_involved,
      :dyslexic_font
    )
  end

  def handle_newsletter_update(person, newsletter_flag)
    return unless person.email.present?

    subscriber = NewsletterSubscriber.find_or_initialize_by(email: person.email)

    if newsletter_flag == "1" || newsletter_flag == true || newsletter_flag == 1
      subscriber.update!(
        person: person,
        source: "authenticated",
        subscribed: true
      )
    else
      subscriber.update!(
        subscribed: false
      )
    end
  end
end
