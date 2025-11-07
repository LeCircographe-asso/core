require 'rails_helper'

RSpec.describe Tag, type: :model do
  let(:tag) { create(:tag) }

  describe 'associations' do
    it { should have_many(:tag_blogs) }
    it { should have_many(:blogs).through(:tag_blogs) }
  end

  describe 'creation' do
    it "can be created with name" do
      expect(tag).to be_persisted
      expect(tag.name).to be_present
    end
  end
end
