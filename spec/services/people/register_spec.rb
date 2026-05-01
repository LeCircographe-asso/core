# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::Register do
  describe "#call" do
    it "creates person and web account" do
      result = described_class.new(
        person_params: {
          first_name: "Ada",
          last_name: "Lovelace",
          email: "ada.register@example.com",
          is_minor: false
        },
        create_user_account: true,
        user_params: {
          email_address: "ada.register@example.com",
          password: "password123",
          system_role: "web_visitor",
          created_by_admin: true
        }
      ).call

      expect(result.success?).to be(true)
      expect(result.person).to be_present
      expect(result.user).to be_present
      expect(result.person.user).to eq(result.user)
    end

    it "fails when asking user creation for a person that already has a user" do
      person = create(:person, email: "existing.person@example.com")
      create(:user, person: person, email_address: "existing.person@example.com")

      result = described_class.new(
        person_params: {
          first_name: person.first_name,
          last_name: person.last_name,
          email: person.email
        },
        existing_person: person,
        create_user_account: true,
        user_params: { email_address: person.email }
      ).call

      expect(result.success?).to be(false)
      expect(result.message).to include(I18n.t("services.errors.register_existing_web_account"))
    end
  end
end
