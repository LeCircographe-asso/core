# frozen_string_literal: true

require "rails_helper"

RSpec.describe DevIncidentLogger do
  describe ".fingerprint_for" do
    it "retourne un hash de 12 caractères" do
      result = described_class.fingerprint_for(type: "test", details: { "email_address" => "a@b.com" })
      expect(result).to match(/\A[a-f0-9]{12}\z/)
    end

    it "produit le même fingerprint pour les mêmes inputs" do
      args = { type: "duplicate_email", details: { "email_address" => "x@y.com" } }
      expect(described_class.fingerprint_for(**args)).to eq(described_class.fingerprint_for(**args))
    end

    it "produit des fingerprints différents pour des types différents" do
      fp1 = described_class.fingerprint_for(type: "type_a", details: {})
      fp2 = described_class.fingerprint_for(type: "type_b", details: {})
      expect(fp1).not_to eq(fp2)
    end
  end

  describe ".log!" do
    context "en environnement development" do
      before { allow(Rails.env).to receive(:development?).and_return(true) }

      it "écrit dans le logger sans lever d'exception" do
        expect(Rails.logger).to receive(:warn).with(a_string_including("dev.incident"))
        expect { described_class.log!(type: "test_event", details: { "key" => "val" }) }.not_to raise_error
      end
    end

    context "hors environnement development" do
      before { allow(Rails.env).to receive(:development?).and_return(false) }

      it "ne logue rien" do
        expect(Rails.logger).not_to receive(:warn)
        described_class.log!(type: "test_event")
      end
    end
  end
end
