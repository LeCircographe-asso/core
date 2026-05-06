# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Notepads", type: :request do
  let(:admin) { create(:user, :admin) }
  before { login_as(admin) }

  describe "GET /admin/notepad/edit" do
    it "retourne 200" do
      get edit_admin_notepad_path
      expect(response).to have_http_status(:ok)
    end

    it "affiche le contenu du cache si présent" do
      Rails.cache.write("notepad", "Contenu de test")
      get edit_admin_notepad_path
      expect(response.body).to include("Contenu de test")
    end
  end

  describe "PATCH /admin/notepad" do
    it "écrit dans le cache et redirige vers le dashboard" do
      patch admin_notepad_path, params: { notepad: "Nouveau contenu" }
      expect(Rails.cache.read("notepad")).to eq("Nouveau contenu")
      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end
end
