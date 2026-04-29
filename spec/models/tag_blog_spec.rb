require 'rails_helper'

RSpec.describe TagBlog, type: :model do
  let(:tag) { create(:tag) }
  let(:blog) { create(:blog) }

  describe 'associations' do
    it { should belong_to(:tag) }
    it { should belong_to(:blog) }
  end

  describe 'creation' do
    it 'can link tag to blog' do
      tag_blog = TagBlog.create!(tag: tag, blog: blog)
      expect(tag_blog).to be_persisted
    end
  end
end
