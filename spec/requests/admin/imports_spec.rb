# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Imports", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:token) { SecureRandom.uuid }

  before { Rails.cache.clear }

  describe "GET /admin/imports/progress" do
    it "returns the progress of the admin's own import" do
      login_as(admin)
      Imports::Progress.new(user: admin, token:).update(10, 42)

      get progress_admin_imports_path(token:)

      expect(response.parsed_body).to eq("processed" => 10, "total" => 42)
    end

    it "is refused to volunteers" do
      login_as(create(:user, :volunteer))

      get progress_admin_imports_path(token:)

      expect(response).to redirect_to(admin_dashboard_index_path)
    end
  end

  describe "POST /admin/imports" do
    it "records progress under the submitted token" do
      login_as(admin)
      create(:membership_type, category: :circus, price_cents: 1000, effective_until: nil)
      csv = "N°,N° adhérent,Nom,Prénom,Naissance,Adresse,CP,Ville,Téléphone,Email,Profession,Spécialité,Droit image,Newsletter,Implication,Montant,Méthode,Date paiement\n" \
            "1,25C001,Dupont,Alice,01/01/1990,1 rue Test,31000,Toulouse,0600000000,alice@example.test,,,non,non,non,10,Espèces,10/08/2025"
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "members.csv")

      post admin_imports_path, params: { csv_file: file, import_token: token }

      expect(response).to have_http_status(:success)
      expect(Imports::Progress.new(user: admin, token:).read).to eq(processed: 1, total: 1)
    end
  end
end
