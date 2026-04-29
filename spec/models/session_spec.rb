require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'creation' do
    it 'can be created with factory' do
      session = create(:session, user: user)
      expect(session).to be_persisted
      expect(session.user).to eq(user)
    end
  end
end
