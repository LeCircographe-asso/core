# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin contribution formulas routes", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  it "serves canonical contribution_formulas index route" do
    get admin_contribution_formulas_path

    expect(response).to have_http_status(:success)
  end

  it "keeps legacy subscription_plans index route working" do
    get admin_subscription_plans_path

    expect(response).to have_http_status(:success)
  end
end
