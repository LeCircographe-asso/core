# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Payments::PaymentDisplayComponent, type: :component do
  let(:person)  { create(:person) }
  let(:user)    { create(:user, person: person) }
  let(:payment) { create(:payment, person: person, recorded_by: user, total_cents: 2500, payment_method: :cash) }
  let(:component) { described_class.new(payment: payment) }

  describe "#display_date" do
    it "formate la date de création" do
      expect(component.display_date).to eq(payment.created_at.strftime("%d/%m/%Y"))
    end

    it "retourne '-' si created_at est absent" do
      allow(payment).to receive(:created_at).and_return(nil)
      expect(component.display_date).to eq("-")
    end
  end

  describe "#display_person" do
    it "retourne le nom complet de la personne" do
      expect(component.display_person).to include(person.first_name).or include(person.last_name)
    end

    it "retourne un fallback si la personne est absente" do
      allow(payment).to receive(:person).and_return(nil)
      expect(component.display_person).to eq("Personne inconnue")
    end
  end

  describe "#display_amount" do
    it "formate le montant en euros" do
      expect(component.display_amount).to include("25")
    end

    it "retourne '-' si total_cents est absent" do
      allow(payment).to receive(:total_cents).and_return(nil)
      expect(component.display_amount).to eq("-")
    end
  end

  describe "#display_recorded_by" do
    it "retourne l'email de l'utilisateur enregistreur" do
      expect(component.display_recorded_by).to eq(user.email_address)
    end

    it "retourne un fallback si recorded_by est absent" do
      allow(payment).to receive(:recorded_by).and_return(nil)
      expect(component.display_recorded_by).to eq("Inconnu")
    end
  end

  describe "#format_currency" do
    it "formate un montant en centimes" do
      expect(component.format_currency(1000)).to include("10")
    end

    it "retourne '-' si le montant est nil" do
      expect(component.format_currency(nil)).to eq("-")
    end
  end

  describe "#display_payment_lines" do
    context "sans lignes de paiement" do
      it "retourne un span vide" do
        expect(component.display_payment_lines).to include("text-gray-400")
      end
    end
  end
end
