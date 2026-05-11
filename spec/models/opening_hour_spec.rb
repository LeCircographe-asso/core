# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpeningHour, type: :model do
  describe ".schedule_hash" do
    it "returns all weekdays and marks missing rows as closed" do
      create(:opening_hour, day: :mardi, open_at: "14:00", close_at: "22:00")

      schedule = described_class.schedule_hash

      expect(schedule["lundi"]).to eq("Fermé")
      expect(schedule["mardi"]).to eq("14:00 - 22:00")
      expect(schedule.keys).to eq(%w[lundi mardi mercredi jeudi vendredi samedi dimanche])
    end
  end

  describe ".replace_schedule!" do
    let(:admin) { create(:user, :admin) }

    it "persists one row per weekday and tracks the updater" do
      described_class.replace_schedule!(
        schedule_hash: {
          "lundi" => "Fermé",
          "mardi" => "14:00 - 22:00",
          "mercredi" => "14:00 - 22:00",
          "jeudi" => "14:00 - 22:00",
          "vendredi" => "14:00 - 22:00",
          "samedi" => "10:00 - 18:00",
          "dimanche" => "Fermé"
        },
        updated_by_user: admin
      )

      expect(described_class.count).to eq(7)
      expect(described_class.find_by(day: :lundi)).to be_closed
      expect(described_class.find_by(day: :samedi).formatted_range).to eq("10:00 - 18:00")
      expect(described_class.latest_update_entry.updated_by_user).to eq(admin)
    end
  end
end
