# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::OpeningHours", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/opening_hours" do
    it "renders hours from the database" do
      create(:opening_hour, day: :mardi, open_at: "14:00", close_at: "22:00", updated_by_user: admin)

      get admin_opening_hours_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Horaires d'ouverture")
      expect(response.body).to include("14:00 - 22:00")
    end
  end

  describe "PATCH /admin/opening_hours" do
    it "persists the weekly schedule and records the updater" do
      patch admin_opening_hours_path, params: {
        open_hour_lundi: "9", open_minute_lundi: "0", close_hour_lundi: "17", close_minute_lundi: "0",
        open_hour_mardi: "14", open_minute_mardi: "0", close_hour_mardi: "22", close_minute_mardi: "0",
        open_hour_mercredi: "14", open_minute_mercredi: "0", close_hour_mercredi: "22", close_minute_mercredi: "0",
        open_hour_jeudi: "14", open_minute_jeudi: "0", close_hour_jeudi: "22", close_minute_jeudi: "0",
        open_hour_vendredi: "14", open_minute_vendredi: "0", close_hour_vendredi: "22", close_minute_vendredi: "0",
        open_hour_samedi: "14", open_minute_samedi: "0", close_hour_samedi: "22", close_minute_samedi: "0",
        open_hour_dimanche: "14", open_minute_dimanche: "0", close_hour_dimanche: "22", close_minute_dimanche: "0"
      }

      expect(response).to redirect_to(admin_opening_hours_path)
      expect(OpeningHour.find_by(day: :lundi).formatted_range).to eq("09:00 - 17:00")
      expect(OpeningHour.latest_update_entry.updated_by_user).to eq(admin)
    end

    it "supports closed days" do
      patch admin_opening_hours_path, params: {
        closed_lundi: "1",
        open_hour_mardi: "14", open_minute_mardi: "0", close_hour_mardi: "22", close_minute_mardi: "0",
        open_hour_mercredi: "14", open_minute_mercredi: "0", close_hour_mercredi: "22", close_minute_mercredi: "0",
        open_hour_jeudi: "14", open_minute_jeudi: "0", close_hour_jeudi: "22", close_minute_jeudi: "0",
        open_hour_vendredi: "14", open_minute_vendredi: "0", close_hour_vendredi: "22", close_minute_vendredi: "0",
        open_hour_samedi: "14", open_minute_samedi: "0", close_hour_samedi: "22", close_minute_samedi: "0",
        open_hour_dimanche: "14", open_minute_dimanche: "0", close_hour_dimanche: "22", close_minute_dimanche: "0"
      }

      expect(response).to redirect_to(admin_opening_hours_path)
      expect(OpeningHour.find_by(day: :lundi)).to be_closed
    end
  end
end
