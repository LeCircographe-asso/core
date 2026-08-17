# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersonNameSearch do
  describe ".call" do
    it "finds people whose first or last name matches the query" do
      match = create(:person, first_name: "Camille", last_name: "Durand")
      create(:person, first_name: "Someone", last_name: "Else")

      expect(described_class.call(query: "Camille")).to include(match)
    end

    it "matches on last_name too" do
      match = create(:person, first_name: "Jean", last_name: "Camille")

      expect(described_class.call(query: "Camille")).to include(match)
    end

    it "excludes the given ids" do
      match = create(:person, first_name: "Camille")

      expect(described_class.call(query: "Camille", exclude_ids: [ match.id ])).to be_empty
    end

    it "returns none for a query shorter than the minimum length" do
      create(:person, first_name: "A")

      expect(described_class.call(query: "a")).to be_empty
    end

    it "returns none for a blank query" do
      expect(described_class.call(query: nil)).to be_empty
    end

    it "respects the limit" do
      3.times { |n| create(:person, first_name: "Camille#{n}") }

      expect(described_class.call(query: "Camille", limit: 2).count).to eq(2)
    end
  end
end
