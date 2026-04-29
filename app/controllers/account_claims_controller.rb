class AccountClaimsController < ApplicationController
  before_action :require_authentication, only: [:create]

  def new
    @claim = AccountClaim.new
  end

  def create
    creator = AccountClaimManagement::AccountClaimCreator.new(
      email: params[:email],
      user_id: Current.user.id
    )

    result = creator.call

    if result.success?
      redirect_to root_path, notice: 'Demande de réclamation envoyée. Vérifiez vos emails.'
    else
      redirect_to root_path, alert: result.message
    end
  rescue StandardError => e
    redirect_to root_path, alert: "Erreur: #{e.message}"
  end

  def confirm
    confirmer = AccountClaimManagement::AccountClaimConfirmer.new(
      confirmation_token: params[:token]
    )

    result = confirmer.call

    if result.success?
      redirect_to user_path(result.user), notice: '✅ Compte revendiqué ! Votre historique est maintenant disponible.'
    else
      redirect_to root_path, alert: result.message
    end
  rescue StandardError => e
    redirect_to root_path, alert: "Erreur lors de la réclamation: #{e.message}"
  end
end
