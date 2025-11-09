require 'rails_helper'

RSpec.describe "Critical Features", type: :model do
  describe "User permissions" do
    it "identifies admin users correctly" do
      admin_user = create(:user, system_role: :admin)
      regular_user = create(:user, system_role: :web_visitor)

      expect(admin_user.has_privileges?).to be_truthy
      expect(regular_user.has_privileges?).to be_falsey
    end

    it "identifies super admin users correctly" do
      super_admin = create(:user, system_role: :super_admin)
      admin_user = create(:user, system_role: :admin)

      expect(super_admin.has_admin?).to be_truthy
      expect(admin_user.has_admin?).to be_truthy
    end
  end

  describe "Event registration" do
    it "can check if person is registered for event" do
      person = create(:person)
      event = create(:event)

      # Initially not registered
      expect(event.is_person_registered?(person)).to be_falsey
    end
  end

  describe "Membership status" do
    it "can determine active membership" do
      person = create(:person)
      membership_type = create(:membership_type)
      membership = create(:membership, person: person, membership_type: membership_type, status: :active)

      expect(membership.active?).to be_truthy
    end
  end
end
