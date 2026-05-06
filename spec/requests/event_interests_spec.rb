# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EventInterests", type: :request do
  let(:person) { create(:person) }
  let(:user)   { create(:user, person: person) }
  let(:event)  { create(:event) }

  before { login_as(user) }

  describe "POST /event_interests" do
    it "crée une présence et redirige vers l'événement" do
      post event_interests_path, params: { id: event.id }
      expect(response).to redirect_to(event)
    end

  end

  describe "DELETE /event_interests/:id" do
    context "avec une présence existante" do
      before { create(:attendance, person: person, event: event, date: Date.current) }

      it "supprime la présence et redirige vers l'événement" do
        delete event_interest_path(event.id)
        expect(response).to redirect_to(event)
        expect(flash[:notice]).to be_present
      end
    end

    context "sans présence existante" do
      it "redirige avec une alerte" do
        delete event_interest_path(event.id)
        expect(response).to redirect_to(event)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
