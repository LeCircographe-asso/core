# frozen_string_literal: true

require "rails_helper"

RSpec.describe People::BootstrapSuperAdmin do
  let(:valid_params) do
    {
      email: "presidente@lecircographe.fr",
      first_name: "Camille",
      last_name: "Durand",
      password: "un mot de passe robuste 42",
      password_confirmation: "un mot de passe robuste 42"
    }
  end

  describe "#call" do
    it "creates a Person and a super_admin User linked to it" do
      result = described_class.new(**valid_params).call

      expect(result.success?).to be(true)
      expect(result.user).to be_super_admin
      expect(result.user.person).to have_attributes(first_name: "Camille", last_name: "Durand")
      expect(result.user.authenticate("un mot de passe robuste 42")).to be_truthy
    end

    it "does not persist anything when the confirmation differs" do
      result = described_class.new(**valid_params, password_confirmation: "autre chose 4242").call

      expect(result.success?).to be(false)
      expect(User.count).to eq(0)
      expect(Person.count).to eq(0)
    end

    it "rejects a short password" do
      result = described_class.new(**valid_params, password: "court1", password_confirmation: "court1").call

      expect(result.success?).to be(false)
      expect(result.errors.join).to match(/mot de passe|password/i)
      expect(User.count).to eq(0)
    end

    it "requires email, first name and last name" do
      result = described_class.new(**valid_params, email: "", first_name: "", last_name: "").call

      expect(result.success?).to be(false)
      expect(User.count).to eq(0)
    end

    it "rejects an invalid email address" do
      result = described_class.new(**valid_params, email: "pas-un-email").call

      expect(result.success?).to be(false)
      expect(User.count).to eq(0)
    end

    it "refuses to create a second super_admin" do
      create(:user, system_role: :super_admin)

      result = described_class.new(**valid_params).call

      expect(result.success?).to be(false)
      expect(result.message).to eq(I18n.t("services.errors.super_admin_already_exists"))
      expect(User.super_admin.count).to eq(1)
    end

    it "still works when only non super_admin accounts exist" do
      create(:user, system_role: :admin)

      expect(described_class.new(**valid_params).call.success?).to be(true)
    end
  end
end
