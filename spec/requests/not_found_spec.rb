# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unmatched routes", type: :request do
  it "serves the branded 404 page for an unknown path" do
    get "/this-route-does-not-exist-xyz"

    expect(response).to have_http_status(:not_found)
  end

  it "enqueues an automatic bug report job" do
    expect do
      get "/this-route-does-not-exist-xyz"
    end.to have_enqueued_job(Support::AutomaticBugReportJob)
  end

  it "does not require authentication" do
    get "/this-route-does-not-exist-xyz"

    expect(response).not_to redirect_to(new_session_path)
  end
end
