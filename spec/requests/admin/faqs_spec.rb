# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Faqs", type: :request do
  let(:admin) { create(:user, :admin) }
  before { login_as(admin) }

  describe "GET /admin/faq/edit" do
    it "retourne 200 et charge les données FAQ" do
      get edit_admin_faq_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/faq" do
    let(:params) do
      {
        faq: {
          hero: "Nouveau titre hero",
          cta_label: "Nouveau label",
          entries: [
            { question: "Question 1", answer: "Réponse 1" },
            { question: "Question 2", answer: "Réponse 2" }
          ]
        }
      }
    end

    it "invalide le cache et redirige" do
      patch admin_faq_path, params: params
      expect(Rails.cache.read(FaqRepository::CACHE_KEY)).to be_nil
      expect(response).to redirect_to(edit_admin_faq_path)
    end

    it "persiste le nouveau titre dans le fichier" do
      patch admin_faq_path, params: params
      data = FaqRepository.load
      expect(data[:hero]).to eq("Nouveau titre hero")
    end

    it "persiste le nouveau label dans le fichier" do
      patch admin_faq_path, params: params
      data = FaqRepository.load
      expect(data[:cta_label]).to eq("Nouveau label")
    end

    it "persiste les nouvelles entrées dans le fichier" do
      patch admin_faq_path, params: params
      data = FaqRepository.load
      expect(data[:entries].first[:question]).to eq("Question 1")
    end

    after do
      # Restaure le fichier original après chaque test d'écriture
      original = {
        "hero" => "Tu as une question ? On y répond ici avant ta venue au Circographe.",
        "cta_label" => "Contacter l’équipe",
        "entries" => [
          { "question" => "Pourquoi adhérer ?", "answer" => "Parce que le lieu est privé et associatif. L'adhésion couvre l'assurance et soutient le fonctionnement." }
        ]
      }
      File.write(FaqRepository::CONFIG_PATH, YAML.dump(original))
      Rails.cache.delete(FaqRepository::CACHE_KEY)
    end
  end
end
