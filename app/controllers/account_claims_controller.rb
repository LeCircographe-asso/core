class AccountClaimsController < ApplicationController
  before_action :require_authentication, only: [ :create ]

  def new
    @claim = AccountClaim.new
  end

  def create
    result = People::AccountClaimer.new(
      email: params[:email]
    ).call

    if result.success?
      redirect_to root_path, notice: result.message
    else
      flash[:alert] = result.message
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    claim = AccountClaim.find_by!(confirmation_token: params[:token])

    if claim.expired?
      redirect_to root_path, alert: "Lien expiré (24h)"
      return
    end

    # Fusionner Person admin → User actuel
    result = People::Merger.new(
      source: claim.person,
      target: claim.user.person,
      actor: claim.user
    ).call

    if result.success?
      claim.update!(status: :confirmed)
      redirect_to user_path(claim.user), notice: "✅ Compte revendiqué ! Votre historique est maintenant disponible."
    else
      redirect_to root_path, alert: result.errors.join(", ")
    end
  end
end
