# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Idle session timeout", type: :request do
  let(:admin) { create(:user, :admin, email_address: "desk@example.com", password: "password123") }

  before { login_as(admin) }

  it "lets an active admin through and records activity" do
    @current_session.update!(updated_at: 5.minutes.ago)

    get admin_exports_path

    expect(response).to have_http_status(:success)
    expect(@current_session.reload.updated_at).to be > 1.minute.ago
  end

  context "when the admin has been idle past the timeout" do
    before { @current_session.update!(updated_at: 16.minutes.ago) }

    it "destroys the session and asks to sign in again" do
      expect { get admin_exports_path }.to change(Session, :count).by(-1)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("sessions.idle_expired_alert"))
    end

    it "prefills the email and returns to the original page after sign-in" do
      get admin_exports_path
      logout

      get new_session_path
      expect(response.body).to include('value="desk@example.com"')

      post session_path, params: { email_address: "desk@example.com", password: "password123" }
      expect(response).to redirect_to(admin_exports_url)
    end

    it "returns to the referring page when a form was submitted after expiry" do
      post restore_admin_member_path(create(:person)), headers: { "HTTP_REFERER" => admin_exports_url }
      logout

      post session_path, params: { email_address: "desk@example.com", password: "password123" }
      expect(response).to redirect_to(admin_exports_url)
    end
  end

  it "does not expire a web visitor" do
    logout
    login_as(create(:user))
    @current_session.update!(updated_at: 30.days.ago)

    get settings_path

    expect(response).not_to redirect_to(new_session_path)
  end
end
