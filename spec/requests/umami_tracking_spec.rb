# frozen_string_literal: true

require "rails_helper"

# Layout tag Umami (app/views/layouts/application.html.erb) : opt-in par environnement via
# ApplicationController#umami_website_id, limité au domaine public via data-domains.
RSpec.describe "Umami tracking script", type: :request do
  let(:website_id) { "6a944fd7-3168-4fdc-b1a9-735479b90af5" }

  it "is absent when no website is configured for the environment" do
    get root_path

    expect(response.body).not_to include("analytics.lecircographe.fr/script.js")
  end

  context "when a website is configured" do
    before do
      allow_any_instance_of(ApplicationController).to receive(:umami_website_id).and_return(website_id)
      allow_any_instance_of(ApplicationController).to receive(:umami_domain).and_return("staging.lecircographe.fr")
    end

    it "only counts visits on the environment's public host" do
      get root_path

      script = Nokogiri::HTML(response.body).at_css('script[src="https://analytics.lecircographe.fr/script.js"]')
      expect(script["data-website-id"]).to eq(website_id)
      expect(script["data-domains"]).to eq("staging.lecircographe.fr")
      expect(script.key?("defer")).to be(true)
    end
  end

  it "derives the domain from the environment's public host" do
    allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return({ host: "lecircographe.fr" })

    expect(ApplicationController.new.send(:umami_domain)).to eq("lecircographe.fr")
  end
end
