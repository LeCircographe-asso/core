require 'rails_helper'

RSpec.describe BlogManagement::BlogUpdater do
  let(:blog) { create(:blog) }
  let(:admin_user) { create(:user, system_role: :admin) }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  describe '#call' do
    context 'with valid attributes' do
      it 'updates blog successfully' do
        updater = described_class.new(
          blog_id: blog.id,
          title: 'Updated Title',
          content: 'Updated Content',
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be true
        expect(blog.reload.title).to eq('Updated Title')
        expect(blog.reload.content.to_plain_text).to eq('Updated Content')
      end

      it 'updates tags when provided' do
        blog.tags << tag1

        updater = described_class.new(
          blog_id: blog.id,
          title: blog.title,
          content: blog.content,
          tag_ids: [tag2.id],
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be true
        expect(blog.reload.tags).to include(tag2)
        expect(blog.reload.tags).not_to include(tag1)
      end

      it 'clears tags when tag_ids is empty' do
        blog.tags << tag1

        updater = described_class.new(
          blog_id: blog.id,
          title: blog.title,
          content: blog.content,
          tag_ids: [],
          updated_by_id: admin_user.id
        )

        result = updater.call

        expect(result.success?).to be true
        expect(blog.reload.tags).to be_empty
      end
    end

    context 'with invalid attributes' do
      it 'returns failure when blog_id is missing' do
        updater = described_class.new(
          title: 'Updated Title',
          updated_by_id: admin_user.id
        )

        result = updater.call
        expect(result.success?).to be false
      end

      it 'returns failure when updated_by_id is missing' do
        updater = described_class.new(
          blog_id: blog.id,
          title: 'Updated Title'
        )

        result = updater.call
        expect(result.success?).to be false
      end

      it "returns failure when user doesn't have permissions" do
        volunteer = create(:user, system_role: :volunteer)

        updater = described_class.new(
          blog_id: blog.id,
          title: 'Updated Title',
          updated_by_id: volunteer.id
        )

        result = updater.call
        expect(result.success?).to be false
        expect(result.message).to include('Insufficient permissions')
      end
    end

    context 'instrumentation' do
      it 'fires blog.updated notification' do
        expect do
          updater = described_class.new(
            blog_id: blog.id,
            title: 'Updated Title',
            content: blog.content,
            updated_by_id: admin_user.id
          )
          updater.call
        end.to instrument('blog.updated')
      end
    end
  end
end
