# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seeds::Profile do
  def env(name) = ActiveSupport::EnvironmentInquirer.new(name)

  describe ".demo?" do
    it "defaults to demo data in development and test" do
      expect(described_class.demo?(env: env("development"), flag: nil)).to be(true)
      expect(described_class.demo?(env: env("test"), flag: nil)).to be(true)
    end

    it "defaults to content-only in staging and production" do
      expect(described_class.demo?(env: env("staging"), flag: nil)).to be(false)
      expect(described_class.demo?(env: env("production"), flag: nil)).to be(false)
    end

    it "treats a blank flag like an unset one" do
      expect(described_class.demo?(env: env("staging"), flag: "")).to be(false)
    end

    it "lets staging opt in to demo data explicitly" do
      expect(described_class.demo?(env: env("staging"), flag: "true")).to be(true)
    end

    it "lets development opt out of demo data explicitly" do
      expect(described_class.demo?(env: env("development"), flag: "false")).to be(false)
    end

    it "refuses demo data in production, even when explicitly requested" do
      expect { described_class.demo?(env: env("production"), flag: "true") }
        .to raise_error(Seeds::Profile::DemoSeedInProductionError, /production/)
    end

    it "accepts an explicit false in production" do
      expect(described_class.demo?(env: env("production"), flag: "false")).to be(false)
    end
  end

  describe "CONTENT_SEEDS" do
    it "only lists content seeds, never accounts or the catalogue" do
      expect(described_class::CONTENT_SEEDS.keys).to eq(%w[faq.rb board_members.rb partners.rb])
    end

    it "points every seed file to an existing model and file" do
      described_class::CONTENT_SEEDS.each do |filename, model_name|
        expect(Rails.root.join("db/seeds", filename)).to exist
        expect(model_name.constantize).to be < ApplicationRecord
      end
    end
  end
end
