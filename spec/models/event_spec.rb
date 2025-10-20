require 'rails_helper'

RSpec.describe Event, type: :model do
  it "can be created" do
    event = Event.new(name: "Test Event", date: Date.today, category: :show)
    expect(event).to be_present
  end

  it "requires a name" do
    event = Event.new(date: Date.today, category: :show)
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include("can't be blank")
  end

  it "requires a date" do
    event = Event.new(name: "Test Event", category: :show)
    expect(event).not_to be_valid
    expect(event.errors[:date]).to include("can't be blank")
  end

  it "has a default category" do
    event = Event.new(name: "Test Event", date: Date.today)
    # Les enums Rails ont souvent une valeur par défaut, donc on teste juste qu'il y en a une
    expect(event.category).to be_present
  end

  it "has valid categories" do
    event = Event.new(name: "Test Event", date: Date.today, category: :show)
    expect(event.category).to eq("show")
  end

  it "can check if a person is registered" do
    person = create(:person)
    event = create(:event)
    expect(event.is_person_registered?(person)).to be_falsey
  end
end
