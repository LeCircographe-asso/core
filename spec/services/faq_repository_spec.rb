# frozen_string_literal: true

require "rails_helper"

RSpec.describe FaqRepository do
  describe ".load" do
    it "retourne un hero, un cta_label et des entries" do
      result = described_class.load

      expect(result).to include(:hero, :cta_label, :entries)
      expect(result[:hero]).to be_a(String)
      expect(result[:entries]).to be_an(Array)
    end

    it "normalise chaque entry avec question et answer" do
      entries = described_class.load[:entries]

      entries.each do |entry|
        expect(entry).to include(:question, :answer)
        expect(entry[:question]).to be_a(String)
        expect(entry[:answer]).to be_a(String)
      end
    end

    it "utilise le cta_label du fichier ou le fallback" do
      result = described_class.load
      expect(result[:cta_label]).to be_present
    end

    context "quand le fichier YAML est absent" do
      it "retourne une structure vide sans lever d'exception" do
        allow(described_class).to receive(:read_yaml).and_return({})
        result = described_class.load

        expect(result[:entries]).to eq([])
        expect(result[:cta_label]).to be_present
      end
    end
  end
end
