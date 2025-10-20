require 'rails_helper'

RSpec.describe Membership, type: :model do
  it "can be created" do
    person = create(:person)
    membership_type = create(:membership_type)
    membership = Membership.new(person: person, membership_type: membership_type, status: :active)
    expect(membership).to be_present
  end

  it "requires a person" do
    membership_type = create(:membership_type)
    membership = Membership.new(membership_type: membership_type, status: :active)
    expect(membership).not_to be_valid
    expect(membership.errors[:person]).to include("must exist")
  end

  it "requires a membership_type" do
    person = create(:person)
    membership = Membership.new(person: person, status: :active)
    expect(membership).not_to be_valid
    expect(membership.errors[:membership_type]).to include("must exist")
  end

  it "has valid status values" do
    person = create(:person)
    membership_type = create(:membership_type)
    membership = Membership.new(person: person, membership_type: membership_type, status: :active)
    expect(membership.status).to eq("active")
  end
end
