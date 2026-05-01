# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipCardHelper, type: :helper do
  describe "#membership_card_role_badge_classes" do
    it "returns a class for known roles" do
      expect(helper.membership_card_role_badge_classes("admin")).to eq("bg-[#1F5C55]/90")
    end

    it "falls back for unknown roles" do
      expect(helper.membership_card_role_badge_classes(:unknown)).to eq("bg-[#1F5C55]/70")
    end
  end

  describe "#membership_card_avatar_source_and_alt" do  
    it "returns configured avatar for web_visitor" do
      user = build(:user, system_role: :web_visitor)
      expect(helper.membership_card_avatar_source_and_alt(user)).to eq([ "users.png", "Avatar Visiteur web" ])
    end
  end

  describe "#membership_card_display_name" do
    it "uses full name when present" do
      user = build(:user)
      allow(user).to receive(:full_name).and_return("Ada Lovelace")
      expect(helper.membership_card_display_name(user)).to eq("Ada Lovelace")
    end

    it "falls back to member id" do
      user = build(:user, id: 42)
      allow(user).to receive(:full_name).and_return("")
      expect(helper.membership_card_display_name(user)).to eq("Membre 42")
    end
  end
end
