require 'rails_helper'

RSpec.describe Blog, type: :model do
  let(:blog) { create(:blog) }

  describe 'associations' do
    it { should have_many(:tag_blogs) }
    it { should have_many(:tags).through(:tag_blogs) }
  end

  describe 'creation' do
    it "can be created with title" do
      expect(blog).to be_persisted
      expect(blog.title).to be_present
    end
  end
end
