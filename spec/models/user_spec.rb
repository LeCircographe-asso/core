require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address) }
  end

  describe "associations" do
    it { should have_many(:user_memberships) }
    it { should have_many(:subscription_types).through(:user_memberships) }
    it { should have_many(:training_attendees).through(:user_memberships) }
  end

  describe "roles" do
    let(:user) { create(:user, role: :membership) }
    let(:circus_user) { create(:user, role: :circus_membership) }

    it "définit le rôle par défaut comme guest" do
      expect(User.new.role).to eq("guest")
    end

    it "permet de changer le rôle" do
      user.circus_membership!
      expect(user.circus_membership?).to be true
    end
  end

  describe "roles et adhésions" do
    let(:user) { create(:user, role: :membership) }
    let(:circus_user) { create(:user, role: :circus_membership) }
    
    it "un utilisateur membership ne peut pas accéder aux entraînements" do
      expect(user.can_train_today?).to be false
    end

    it "un circus_membership avec adhésion valide peut accéder aux entraînements" do
      membership = create(:user_membership, 
        user: circus_user,
        subscription_type: create(:subscription_type, :annual),
        expiration_date: 1.year.from_now
      )
      
      expect(circus_user.can_train_today?).to be true
    end
  end
end 