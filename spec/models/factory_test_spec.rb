require 'rails_helper'

RSpec.describe "Factory Tests", type: :model do
  it "can create a person" do
    person = create(:person)
    expect(person).to be_persisted
    expect(person.first_name).to be_present
    expect(person.last_name).to be_present
  end

  it "can create a user" do
    user = create(:user)
    expect(user).to be_persisted
    expect(user.email_address).to be_present
  end

  it "can create an event" do
    event = create(:event)
    expect(event).to be_persisted
    expect(event.name).to be_present
    expect(event.date).to be_present
  end

  it "can create a person with a user account" do
    person = create(:person)
    user = create(:user, person: person)
    
    expect(user.person).to eq(person)
    expect(person.user).to eq(user)
  end
end
