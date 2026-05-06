# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnersCatalog do
  describe ".public_partners" do
    subject(:partners) { described_class.public_partners }

    it "retourne une liste non vide" do
      expect(partners).not_to be_empty
    end

    it "chaque partenaire a un nom, une description et un lien" do
      partners.each do |partner|
        expect(partner.name).to be_present
        expect(partner.description).to be_present
        expect(partner.link).to be_present
      end
    end

    it "retourne des objets Partner" do
      expect(partners).to all(be_a(PartnersCatalog::Partner))
    end
  end
end
