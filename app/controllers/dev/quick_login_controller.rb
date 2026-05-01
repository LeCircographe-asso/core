# frozen_string_literal: true

module Dev
  class QuickLoginController < ApplicationController
    # Clé session Rails : super-admin qui a autorisé l’usage de l’outil (persiste après impersonation).
    GRANTER_SESSION_KEY = :dev_quick_login_granter_id

    before_action :ensure_development!
    before_action :ensure_quick_login_allowed!

    def show
      @dev_quick_login_delegate = delegate_quick_login_session? && !Current.user.super_admin?
      @seed_emails = %w[
        super-admin@rails.com
        admin@rails.com
        volunteer@rails.com
        diana.prospect@example.com
        emma.complexe@example.com
        frank.newcomer@example.com
      ].freeze

      @highlight_users = User.includes(:person).where(email_address: @seed_emails).order(:email_address)
      highlighted_emails = @highlight_users.pluck(:email_address)
      @other_users = User.includes(:person).order(:email_address).limit(80)
      @other_users = @other_users.where.not(email_address: highlighted_emails) if highlighted_emails.any?
    end

    def create
      user_id = params.expect(:user_id)
      user = User.find(user_id)

      # Mémoriser le super-admin qui lance la première impersonation ; les visites suivantes
      # restent autorisées tant que la session Rails existe (sinon « une seule fois » bloquait au retour).
      session[GRANTER_SESSION_KEY] = Current.user.id if Current.user&.super_admin?

      start_new_session_for(user)
      redirect_to user_path(user),
                  notice: "[Dev] Connecté comme #{user.email_address} — voir la carte profil ci-dessous.",
                  status: :see_other
    end

    private

    def ensure_development!
      raise ActionController::RoutingError, "Not found" unless Rails.env.development?
    end

    def ensure_quick_login_allowed!
      return if Current.user&.super_admin?
      return if delegate_quick_login_session?

      redirect_to root_path, alert: I18n.t("dev.quick_login.forbidden")
    end

    def delegate_quick_login_session?
      gid = session[GRANTER_SESSION_KEY]
      return false if gid.blank?

      User.exists?(id: gid, system_role: User.system_roles[:super_admin])
    end
  end
end
