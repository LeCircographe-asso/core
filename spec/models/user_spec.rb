require 'rails_helper'

RSpec.describe User, type: :model do
  it "can be created" do
    user = User.new(email: "test@example.com")
    expect(user).to be_present
  end
end