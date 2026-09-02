# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Automatic bug reporting", type: :request do
  it "enqueues a report when a controller action raises an unhandled exception" do
    expect do
      get "/events/999999"
    end.to have_enqueued_job(Support::AutomaticBugReportJob)

    expect(response).to have_http_status(:not_found)
  end

  it "tags a RecordNotFound as :not_found rather than a generic server error" do
    expect do
      get "/events/999999"
    end.to have_enqueued_job(Support::AutomaticBugReportJob).with(
      hash_including(kind: :not_found, error_class: "ActiveRecord::RecordNotFound")
    )
  end

  it "does not report exceptions a controller already rescues itself" do
    admin = create(:user, :admin)
    login_as(admin)

    # Admin::PaymentsController rescues ActiveRecord::RecordNotFound itself
    # (redirect_payment_not_found) — the subscriber must not see it as unhandled.
    expect do
      get "/admin/payments/999999"
    end.not_to have_enqueued_job(Support::AutomaticBugReportJob)
  end
end
