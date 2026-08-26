# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Faqs", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/faqs" do
    it "returns http success" do
      get admin_faqs_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/faqs/:id/edit" do
    it "returns http success" do
      faq = create(:faq)

      get edit_admin_faq_path(faq)

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/faqs" do
    it "creates a Faq" do
      expect do
        post admin_faqs_path, params: { faq: { question: "Comment adhérer ?", answer: "Sur place ou en ligne.", label: "adhesion" } }
      end.to change(Faq, :count).by(1)

      expect(response).to redirect_to(admin_faqs_path)
    end

    it "re-renders the form when invalid" do
      expect do
        post admin_faqs_path, params: { faq: { question: "", answer: "", label: "adhesion" } }
      end.not_to change(Faq, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/faqs/:id" do
    it "updates the Faq" do
      faq = create(:faq, question: "Ancienne question ?")

      patch admin_faq_path(faq), params: { faq: { question: "Ancienne question ?", answer: faq.answer, label: faq.label } }

      expect(response).to redirect_to(admin_faqs_path)
      expect(faq.reload.question).to eq("Ancienne question ?")
    end
  end

  describe "PATCH /admin/faqs/reorder" do
    it "updates position from the given ids order" do
      first = create(:faq, position: 1)
      second = create(:faq, position: 2)

      patch reorder_admin_faqs_path, params: { ids: [ second.id, first.id ] }

      expect(response).to have_http_status(:ok)
      expect(second.reload.position).to eq(1)
      expect(first.reload.position).to eq(2)
    end
  end

  describe "DELETE /admin/faqs/:id" do
    it "destroys the Faq" do
      faq = create(:faq)

      expect do
        delete admin_faq_path(faq)
      end.to change(Faq, :count).by(-1)

      expect(response).to redirect_to(admin_faqs_path)
    end
  end
end
