# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ExceptionalClosures", type: :request do
  let(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "PATCH /admin/exceptional_closure" do
    it "activates the closure with a label and end date" do
      patch admin_exceptional_closure_path, params: { active: "1", label: "Vacances d'été", ends_on: (Date.current + 10).to_s }

      expect(response).to redirect_to(admin_opening_hours_path)
      closure = ExceptionalClosure.current
      expect(closure).to be_in_effect
      expect(closure.label).to eq("Vacances d'été")
      expect(closure.updated_by_user).to eq(admin)
    end

    it "deactivates the closure" do
      ExceptionalClosure.current.update!(active: true, label: "Vacances d'été")

      patch admin_exceptional_closure_path, params: { active: "0" }

      expect(ExceptionalClosure.current).not_to be_in_effect
    end
  end
end
