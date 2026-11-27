# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::FeatureFlags", type: :request do
  it "shows every flag with its live state to a super admin" do
    login_as(create(:user, :super_admin))
    allow(Rails.application.config.x).to receive(:account_claim_enabled).and_return(true)

    get admin_feature_flags_path

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include("translation_missing")
    FeatureFlag.all.each { |flag| expect(response.body).to include("feature_flag_#{flag.key}") }
    expect(response.body).to match(/feature_flag_account_claim.*?#{I18n.t('admin.feature_flags.index.enabled')}/m)
  end

  it "is refused to admins" do
    login_as(create(:user, :admin))

    get admin_feature_flags_path

    expect(response).to redirect_to(admin_dashboard_index_path)
  end
end
