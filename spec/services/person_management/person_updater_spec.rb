require "rails_helper"

RSpec.describe PersonManagement::PersonUpdater do
  let(:admin) { create(:user, :admin) }
  let(:person) { create(:person, email: "person@example.com", phone: "0600000000") }

  describe "#call" do
    it "updates basic attributes and logs instrumentation" do
      updater = described_class.new(
        person_id: person.id,
        attributes: { first_name: "Updated", phone: "0611111111" },
        newsletter_subscribed: nil,
        updated_by_id: admin.id
      )

      expect do
        expect(updater.call.success?).to be(true)
      end.to instrument("person.updated")

      person.reload
      expect(person.first_name).to eq("Updated")
      expect(person.phone).to eq("0611111111")
    end

    it "syncs newsletter subscription when email present" do
      subscriber = create(:newsletter_subscriber, person: person, email: person.email, subscribed: false)

      updater = described_class.new(
        person_id: person.id,
        attributes: { phone: "0612345678" },
        newsletter_subscribed: true,
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(true)
      expect(subscriber.reload.subscribed?).to be(true)
    end

    it "returns validation errors if person update fails" do
      person.update!(email: nil) # keep existing email nil so validation fails when blank first name

      updater = described_class.new(
        person_id: person.id,
        attributes: { first_name: "" },
        updated_by_id: admin.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include("Validation errors")
    end

    it "fails when permissions are insufficient" do
      volunteer = create(:user, :volunteer)
      create(:person, user: volunteer)

      updater = described_class.new(
        person_id: person.id,
        attributes: { first_name: "Should Not Update" },
        updated_by_id: volunteer.id
      )

      result = updater.call

      expect(result.success?).to be(false)
      expect(result.message).to include("Insufficient permissions")
      expect(person.reload.first_name).not_to eq("Should Not Update")
    end
  end
end
