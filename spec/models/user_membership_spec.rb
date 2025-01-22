require 'rails_helper'

RSpec.describe UserMembership, type: :model do
  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:subscription_type_id) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:subscription_type) }
    it { should belong_to(:payment).optional }
    it { should have_many(:training_attendees) }
  end

  describe "adhésion" do
    let(:membership) { create(:user_membership) }

    it "est valide avec une date d'expiration future" do
      membership.expiration_date = 1.month.from_now
      expect(membership).to be_valid
    end
  end

  describe "validité des abonnements" do
    let(:daily_sub) { create(:subscription_type, :daily) }
    let(:booklet_sub) { create(:subscription_type, :booklet) }
    
    it "un abonnement journée n'est valide que le jour même" do
      membership = create(:user_membership, subscription_type: daily_sub)
      
      travel_to Time.current do
        expect(membership.valid_subscription?).to be true
      end
      
      travel_to 1.day.from_now do
        expect(membership.valid_subscription?).to be false
      end
    end

    it "un carnet est valide tant qu'il reste des entrées" do
      membership = create(:user_membership, subscription_type: booklet_sub)
      
      # Simuler 9 passages
      9.times do
        create(:training_attendee, user_membership: membership)
      end
      
      expect(membership.remaining_entries).to eq(1)
      expect(membership.valid_subscription?).to be true
      
      create(:training_attendee, user_membership: membership)
      expect(membership.valid_subscription?).to be false
    end
  end
end 