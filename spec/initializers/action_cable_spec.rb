# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Action Cable initializer" do
  it "allows HTTPS origins for staging and production hosts (Solid Cable / Kamal)" do
    origins = Rails.application.config.action_cable.allowed_request_origins
    expect(origins).to include(
      "https://staging.lecircographe.fr",
      "https://lecircographe.fr"
    )
  end
end
