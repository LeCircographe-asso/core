# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EventInterests", type: :request do
  let(:person) { create(:person) }
  let(:user)   { create(:user, person: person) }
  let(:event)  { create(:event) }

  before { login_as(user) }

  describe "POST /event_interests" do
    it "enregistre un like et redirige vers l'événement" do
      expect do
        post event_interests_path, params: { id: event.id }
      end.to change(person.event_interests, :count).by(1)
      expect(response).to redirect_to(event)
    end

    it "ne crée aucune présence" do
      expect do
        post event_interests_path, params: { id: event.id }
      end.not_to change(Attendance, :count)
    end

    it "fonctionne même si la personne s'est entraînée le jour même" do
      create(:attendance, person: person, date: Date.current)

      post event_interests_path, params: { id: event.id }

      expect(flash[:notice]).to be_present
      expect(user.is_interested_in?(event.id)).to be(true)
    end

    it "n'envoie pas d'email (un like ne mérite pas un courrier)" do
      expect do
        post event_interests_path, params: { id: event.id }
      end.not_to have_enqueued_mail(UserMailer)
    end
  end

  describe "DELETE /event_interests/:id" do
    context "avec un like existant" do
      before { create(:event_interest, person: person, event: event) }

      it "supprime le like et redirige vers l'événement" do
        expect { delete event_interest_path(event.id) }.to change(EventInterest, :count).by(-1)
        expect(response).to redirect_to(event)
        expect(flash[:notice]).to be_present
      end
    end

    context "sans like mais avec une présence du jour" do
      before { create(:attendance, person: person, date: Date.current) }

      it "ne supprime pas la présence" do
        expect { delete event_interest_path(event.id) }.not_to change(Attendance, :count)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
