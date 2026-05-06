# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:person)  { create(:person) }
  let(:user)    { create(:user, person: person) }
  let(:session) { create(:session, user: user) }

  context "avec une session valide" do
    before { allow(Session).to receive(:find_by).and_return(session) }

    it "identifie l'utilisateur courant" do
      connect "/cable"
      expect(connection.current_user).to eq(user)
    end
  end

  context "sans session (cookie absent ou invalide)" do
    before { allow(Session).to receive(:find_by).and_return(nil) }

    it "rejette la connexion" do
      expect { connect "/cable" }.to have_rejected_connection
    end
  end

  context "sans cookie de session" do
    it "rejette la connexion sans appeler Session.find_by" do
      expect { connect "/cable" }.to have_rejected_connection
    end
  end
end
