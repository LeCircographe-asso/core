require 'rails_helper'

RSpec.describe Person, type: :model do
  it "can be created" do
    person = Person.new(first_name: "John", last_name: "Doe")
    expect(person).to be_present
  end

  it "has a full name" do
    person = Person.new(first_name: "John", last_name: "Doe")
    expect(person.full_name).to eq("John Doe")
  end

  it "requires first_name" do
    person = Person.new(last_name: "Doe")
    expect(person).not_to be_valid
    expect(person.errors[:first_name]).to include("can't be blank")
  end

  it "requires last_name" do
    person = Person.new(first_name: "John")
    expect(person).not_to be_valid
    expect(person.errors[:last_name]).to include("can't be blank")
  end

  it "can have a user account" do
    person = create(:person)
    user = create(:user, person: person)
    expect(person.user).to eq(user)
  end
end
