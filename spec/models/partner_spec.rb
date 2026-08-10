# frozen_string_literal: true

require "rails_helper"

RSpec.describe Partner, type: :model do
  let(:image_path) { Rails.root.join("app/assets/images/lelieu1.webp") }

  it "is invalid without a name" do
    partner = Partner.new
    expect(partner).not_to be_valid
    expect(partner.errors[:name]).to be_present
  end

  it "is valid with a name only, logo optional" do
    partner = Partner.new(name: "La Grainerie")
    expect(partner).to be_valid
  end

  it "assigns the next display_order automatically" do
    first = create(:partner)
    second = create(:partner)

    expect(second.display_order).to eq(first.display_order + 1)
  end

  it "orders by display_order then created_at" do
    second = create(:partner, display_order: 2)
    first = create(:partner, display_order: 1)

    expect(Partner.ordered).to eq([ first, second ])
  end

  it "rejects a non-image logo content type" do
    partner = Partner.new(name: "La Grainerie")
    partner.logo.attach(io: File.open(image_path), filename: "notes.txt", content_type: "text/plain", identify: false)

    expect(partner).not_to be_valid
    expect(partner.errors[:logo]).to be_present
  end

  describe "#initials_label" do
    it "uses the explicit initials when present" do
      partner = build(:partner, name: "Notre crêpier·e partenaire", initials: "Cr")

      expect(partner.initials_label).to eq("CR")
    end

    it "falls back to the first two letters of the name" do
      partner = build(:partner, name: "Le Zmam", initials: nil)

      expect(partner.initials_label).to eq("LE")
    end
  end
end
