# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sessions", type: :request do
  let(:person) { create(:person) }
  let(:admin)  { create(:user, :admin, person: person, password: "password123") }

  describe "GET /admin/session/new" do
    context "non authentifié" do
      it "redirige vers la page de connexion publique" do
        get new_admin_session_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "déjà authentifié" do
      before { login_as(admin) }

      it "redirige vers la racine" do
        get new_admin_session_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /admin/session" do
    context "avec des identifiants valides" do
      it "connecte l'utilisateur et redirige vers le dashboard admin" do
        post admin_session_path, params: { email_address: admin.email_address, password: "password123" }
        expect(response).to redirect_to(admin_root_path)
      end
    end

    context "avec des identifiants invalides" do
      it "redirige vers la page de connexion avec une alerte" do
        post admin_session_path, params: { email_address: admin.email_address, password: "wrong" }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /admin/session" do
    before { login_as(admin) }

    it "déconnecte et redirige vers la racine" do
      delete admin_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
