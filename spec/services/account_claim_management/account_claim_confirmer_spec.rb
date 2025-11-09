require 'rails_helper'

RSpec.describe AccountClaimManagement::AccountClaimConfirmer do
  let(:user) { create(:user) }
  let(:admin_person) { create(:person, email: "admin@example.com") }
  let(:claim) do
    create(:account_claim,
      person: admin_person,
      user: user,
      status: :pending,
      expires_at: 24.hours.from_now
    )
  end

  describe "#call" do
    context "with valid token" do
      it "confirms account claim successfully" do
        confirmer = described_class.new(confirmation_token: claim.confirmation_token)
        result = confirmer.call

        if !result.success?
          puts "Result message: #{result.message}"
          puts "Result errors: #{result.errors.inspect}"
        end
        expect(result.success?).to be true
        expect(result.claim.reload.status).to eq("confirmed")
        expect(result.user_person).to be_present
      end

      it "copies person data to user person" do
        confirmer = described_class.new(confirmation_token: claim.confirmation_token)
        result = confirmer.call

        expect(result.user_person.first_name).to eq(admin_person.first_name)
        expect(result.user_person.last_name).to eq(admin_person.last_name)
        expect(result.user_person.email).to eq(admin_person.email)
      end

      it "transfers relations from admin person to user person" do
        membership = create(:membership, person: admin_person)
        payment = create(:payment, person: admin_person)

        confirmer = described_class.new(confirmation_token: claim.confirmation_token)
        result = confirmer.call

        expect(membership.reload.person_id).to eq(result.user_person.id)
        expect(payment.reload.person_id).to eq(result.user_person.id)
      end

      it "transfers admin person to user or merges it" do
        confirmer = described_class.new(confirmation_token: claim.confirmation_token)
        result = confirmer.call

        expect(result.success?).to be true
        # Admin person is either transferred to user (if user has no person) or merged
        # In either case, user should have a person with the data
        expect(result.user.person).to be_present
        expect(result.user_person.first_name).to eq(admin_person.first_name)
      end
    end

    context "with expired claim" do
      it "returns failure when claim is expired" do
        expired_claim = create(:account_claim,
          person: admin_person,
          user: user,
          expires_at: 1.day.ago
        )

        confirmer = described_class.new(confirmation_token: expired_claim.confirmation_token)
        result = confirmer.call

        expect(result.success?).to be false
        expect(result.message).to include("Lien expiré")
      end
    end

    context "with already confirmed claim" do
      it "returns failure when claim is already confirmed" do
        confirmed_claim = create(:account_claim,
          person: admin_person,
          user: user,
          status: :confirmed
        )

        confirmer = described_class.new(confirmation_token: confirmed_claim.confirmation_token)
        result = confirmer.call

        expect(result.success?).to be false
        expect(result.message).to include("déjà été confirmée")
      end
    end

    context "with invalid token" do
      it "returns failure when token is invalid" do
        confirmer = described_class.new(confirmation_token: "invalid-token")
        result = confirmer.call

        expect(result.success?).to be false
        expect(result.message).to include("not found")
      end
    end

    context "instrumentation" do
      it "fires account_claim.confirmed notification" do
        expect {
          confirmer = described_class.new(confirmation_token: claim.confirmation_token)
          confirmer.call
        }.to instrument("account_claim.confirmed")
      end
    end
  end
end
