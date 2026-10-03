# frozen_string_literal: true

class AccountClaimMailer < ApplicationMailer
  def confirmation_email(claim)
    @claim = claim
    @person = claim.person
    @confirmation_url = confirm_account_claims_url(token: claim.confirmation_token)

    mail(
      to: @person.email,
      subject: I18n.t("mailers.account_claim_mailer.confirmation_email.subject")
    )
  end
end
