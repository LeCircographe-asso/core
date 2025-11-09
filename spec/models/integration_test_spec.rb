require 'rails_helper'

RSpec.describe "Integration Tests", type: :model do
  describe "Complete user workflow" do
    it "can create a complete user with person and membership" do
      # Create a person
      person = create(:person, first_name: "Alice", last_name: "Smith")

      # Create a user account linked to the person
      user = create(:user, person: person, email_address: "alice@example.com")

      # Create a membership type
      membership_type = create(:membership_type)

      # Create a membership for the person
      membership = create(:membership, person: person, membership_type: membership_type, status: :active)

      # Verify the complete setup
      expect(user.person).to eq(person)
      expect(user.full_name).to eq("Alice Smith")
      expect(user.memberships).to include(membership)
      expect(membership.active?).to be_truthy
    end
  end

  describe "Event and attendance workflow" do
    it "can create an event and check attendance" do
      # Create an event
      event = create(:event, name: "Weekly Circus Training", date: Date.tomorrow, category: :workshop)

      # Create a person
      person = create(:person)

      # Verify they're not initially registered
      expect(event.is_person_registered?(person)).to be_falsey

      # Verify event details
      expect(event.name).to eq("Weekly Circus Training")
      expect(event.category).to eq("workshop")
      expect(event.date).to be > Date.current
    end
  end

  describe "Admin workflow" do
    it "can create an admin user and verify permissions" do
      # Create an admin user
      admin = create(:user, system_role: :admin)

      # Create a regular user
      regular_user = create(:user, system_role: :web_visitor)

      # Verify admin permissions
      expect(admin.has_privileges?).to be_truthy
      expect(admin.has_admin?).to be_truthy

      # Verify regular user permissions
      expect(regular_user.has_privileges?).to be_falsey
      expect(regular_user.has_admin?).to be_falsey
    end
  end
end
