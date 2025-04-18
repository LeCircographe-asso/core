require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'associations' do
    it { should have_many(:user_memberships) }
    it { should have_many(:user).through(:user_memberships) }
  end

  describe 'enum' do
    it { should define_enum_for(:type_name).with_values([ :No_Member, :Basic, :Circus ]) }
  end

  describe 'default values' do
    it 'has No_Member as default type' do
      membership = Membership.new
      expect(membership.type_name).to eq('No_Member')
    end
  end
end
