require 'rails_helper'

RSpec.describe AccountClaimManagement::AccountClaimCreator do
  let(:user) { create(:user) }
  let!(:person) { create(:person, email: "test@example.com") }

  describe "#call" do
    context "with valid attributes" do
      it "creates account claim successfully" do
        creator = described_class.new(
          email: "test@example.com",
          user_id: user.id
        )

        result = creator.call

        expect(result.success?).to be true
        expect(result.claim).to be_present
        expect(result.claim.person).to eq(person)
        expect(result.claim.user).to eq(user)
        expect(result.claim.status).to eq("pending")
      end

      it "generates confirmation token" do
        creator = described_class.new(
          email: "test@example.com",
          user_id: user.id
        )

        result = creator.call

        expect(result.claim.confirmation_token).to be_present
      end

      it "sets expires_at to 24 hours from now" do
        creator = described_class.new(
          email: "test@example.com",
          user_id: user.id
        )

        result = creator.call

        expect(result.claim.expires_at).to be_within(1.minute).of(24.hours.from_now)
      end
    end

    context "with invalid attributes" do
      it "returns failure when email is missing" do
        creator = described_class.new(user_id: user.id)

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Invalid data")
      end

      it "returns failure when user_id is missing" do
        creator = described_class.new(email: "test@example.com")

        result = creator.call
        expect(result.success?).to be false
      end

      it "returns failure when email is invalid" do
        creator = described_class.new(
          email: "invalid-email",
          user_id: user.id
        )

        result = creator.call
        expect(result.success?).to be false
      end
    end

    context "with person that cannot be claimed" do
      it "returns failure when person has user" do
        person_with_user = create(:person, email: "claimed@example.com")
        create(:user, person: person_with_user)

        creator = described_class.new(
          email: "claimed@example.com",
          user_id: user.id
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("déjà lié")
      end

      it "returns failure when person not found" do
        creator = described_class.new(
          email: "notfound@example.com",
          user_id: user.id
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include("Aucun compte trouvé")
      end
    end

    context "instrumentation" do
      it "fires account_claim.created notification" do
        expect {
          creator = described_class.new(
            email: "test@example.com",
            user_id: user.id
          )
          creator.call
        }.to instrument("account_claim.created")
      end
    end
  end
end
