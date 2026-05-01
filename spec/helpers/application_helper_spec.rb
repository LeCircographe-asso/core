# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#news_carousel_image_sources" do
    it "returns sorted unique filenames capped by limit" do
      allow(helper).to receive(:hero_image_pool).and_return(%w[hero_03.webp hero_01.webp hero_02.webp hero_01.webp])
      expect(helper.news_carousel_image_sources(limit: 2)).to eq(%w[hero_01.webp hero_02.webp])
    end

    it "uses limit 1 when limit is below 1" do
      allow(helper).to receive(:hero_image_pool).and_return(%w[b.webp a.webp])
      expect(helper.news_carousel_image_sources(limit: -5)).to eq(%w[a.webp])
    end

    it "caps at 24 slides" do
      pool = (1..30).map { |i| format("hero_%02d.webp", i) }
      allow(helper).to receive(:hero_image_pool).and_return(pool)
      expect(helper.news_carousel_image_sources(limit: 100).size).to eq(24)
    end
  end
end
