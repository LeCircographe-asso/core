# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserManagement::RoleChanger do
  let(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }
  let(:web_visitor) { create(:user) }

  def change(user, role, by:)
    described_class.new(user_id: user.id, system_role: role, changed_by_id: by.id).call
  end

  it "lets an admin promote a web visitor to volunteer, and take the role back" do
    expect(change(web_visitor, "volunteer", by: admin)).to be_success
    expect(web_visitor.reload).to be_volunteer

    expect(change(web_visitor, "web_visitor", by: admin)).to be_success
    expect(web_visitor.reload).to be_web_visitor
  end

  it "lets a super_admin promote someone to admin and demote them" do
    expect(change(web_visitor, "admin", by: super_admin)).to be_success
    expect(web_visitor.reload).to be_admin

    expect(change(web_visitor, "volunteer", by: super_admin)).to be_success
    expect(web_visitor.reload).to be_volunteer
  end

  it "refuses a role the editor cannot assign" do
    result = change(web_visitor, "admin", by: admin)

    expect(result).not_to be_success
    expect(result.message).to eq(I18n.t("services.errors.insufficient_permissions.role_assignment"))
    expect(web_visitor.reload).to be_web_visitor
  end

  it "never assigns super_admin, even for a super_admin" do
    expect(change(web_visitor, "super_admin", by: super_admin)).not_to be_success
    expect(web_visitor.reload).to be_web_visitor
  end

  it "refuses to touch an account of equal or higher rank" do
    other_admin = create(:user, :admin)

    expect(change(other_admin, "volunteer", by: admin).message)
      .to eq(I18n.t("services.errors.insufficient_permissions.role_change"))
    expect(change(super_admin, "admin", by: admin)).not_to be_success
    expect(other_admin.reload).to be_admin
    expect(super_admin.reload).to be_super_admin
  end

  it "refuses to change your own role" do
    expect(change(super_admin, "admin", by: super_admin)).not_to be_success
    expect(super_admin.reload).to be_super_admin
  end

  it "refuses an unknown role" do
    expect(change(web_visitor, "owner", by: super_admin)).not_to be_success
  end

  it "instruments the change for audit" do
    events = []
    callback = ->(*args) { events << ActiveSupport::Notifications::Event.new(*args).payload }

    ActiveSupport::Notifications.subscribed(callback, "user.role_changed") do
      change(web_visitor, "volunteer", by: admin)
    end

    expect(events).to contain_exactly(
      hash_including(user_id: web_visitor.id, changed_by_id: admin.id, from: "web_visitor", to: "volunteer")
    )
  end
end
