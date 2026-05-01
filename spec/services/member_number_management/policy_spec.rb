# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemberNumberManagement::Policy do
  describe ".type_code_for" do
    it "maps circus inputs to C" do
      expect(described_class.type_code_for("CIRQUE")).to eq("C")
      expect(described_class.type_code_for("C")).to eq("C")
    end

    it "maps basic inputs to U" do
      expect(described_class.type_code_for("BASIQUE")).to eq("U")
      expect(described_class.type_code_for("BASIC")).to eq("U")
      expect(described_class.type_code_for("U")).to eq("U")
    end
  end

  describe ".parse" do
    it "parses a valid member number" do
      expect(described_class.parse("25C001")).to eq(
        year: "2025",
        type: "Cirque",
        number: 1,
        full_year: "25",
        type_code: "C"
      )
    end

    it "returns nil for invalid input" do
      expect(described_class.parse("invalid")).to be_nil
    end
  end

  describe ".valid_format?" do
    it "accepts valid formats" do
      expect(described_class.valid_format?("25U001")).to be(true)
      expect(described_class.valid_format?("25C12345")).to be(true)
    end

    it "rejects invalid formats" do
      expect(described_class.valid_format?("25X001")).to be(false)
      expect(described_class.valid_format?("25U01")).to be(false)
    end
  end
end
