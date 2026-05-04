# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::UserAccountCreator do
  describe "#call" do
    it "sends welcome flow explicitly when creating a user" do
      person = create(:person, email: "creator.flow@example.com")
      service = described_class.new(
        person: person,
        email_address: "creator.flow@example.com",
        system_role: "admin",
        created_by_admin: true
      )

      expect_any_instance_of(User).to receive(:welcome_send).once.and_call_original

      result = service.call

      expect(result.success?).to be(true)
      expect(result.created).to be(true)
      expect(result.user).to be_present
    end
  end
end
