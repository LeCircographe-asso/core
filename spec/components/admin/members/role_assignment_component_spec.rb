# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Members::RoleAssignmentComponent, type: :component do
  let(:admin) { create(:user, :admin) }

  it "offers the current role plus the roles the editor can assign" do
    volunteer = create(:user, :volunteer)

    render_inline(described_class.new(user: volunteer, current_user: admin))

    options = page.all("select option").map(&:value)
    expect(options).to eq(%w[volunteer web_visitor])
    expect(page).to have_select(selected: I18n.t("admin.roles.labels.volunteer"))
  end

  it "only shows the role label when the editor cannot change it" do
    other_admin = create(:user, :admin)

    render_inline(described_class.new(user: other_admin, current_user: admin))

    expect(page).not_to have_css("select")
    expect(page).to have_text(I18n.t("admin.roles.labels.admin"))
  end
end
