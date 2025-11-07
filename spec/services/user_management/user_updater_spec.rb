require "rails_helper"

RSpec.describe UserManagement::UserUpdater do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, email: "person@example.com", phone: "0700000000") }
  let(:user) { create(:user, person: person, system_role: :volunteer) }

  describe "#call" do
    it "updates user email and person attributes with instrumentation" do
      updater = described_class.new(
        user_id: user.id,
        email_address: "new.email@example.com",
        person_attributes: { phone: "0711111111" },
        updated_by_id: admin.id
      )

      expect do
        result = updater.call
        expect(result.success?).to be(true)
      end.to instrument("user.updated")

      expect(user.reload.email_address).to eq("new.email@example.com")
      expect(person.reload.phone).to eq("0711111111")
    end

    it "updates newsletter subscription when requested" do
      subscriber = create(:newsletter_subscriber, person: person, email: person.email, subscribed: false)

      updater = described_class.new(
        user_id: user.id,
        person_attributes: { phone: "0722222222" },
        newsletter_subscribed: true,
        updated_by_id: admin.id
      )

      result = updater.call
      expect(result.success?).to be(true)
      expect(subscriber.reload.subscribed?).to be(true)
    end

    it "returns validation errors when update fails" do
      updater = described_class.new(
        user_id: user.id,
        person_attributes: { first_name: "" },
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include("Validation errors")
    end

    it "fails when permissions are insufficient" do
      other_user = create(:user, system_role: :volunteer)

      updater = described_class.new(
        user_id: user.id,
        email_address: "unauthorized@example.com",
        updated_by_id: other_user.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include("Insufficient permissions")
      expect(user.reload.email_address).not_to eq("unauthorized@example.com")
    end
  end
end

