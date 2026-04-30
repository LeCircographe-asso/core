# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlogManagement::BlogCreator do
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  describe '#call' do
    context 'with valid attributes' do
      it 'creates blog successfully' do
        creator = described_class.new(
          title: 'Test Blog',
          content: 'Test Content'
        )

        result = creator.call

        expect(result.success?).to be true
        expect(result.blog).to be_present
        expect(result.blog.title).to eq('Test Blog')
        expect(result.blog.content.to_plain_text).to eq('Test Content')
      end

      it 'associates tags when provided' do
        creator = described_class.new(
          title: 'Test Blog',
          content: 'Test Content',
          tag_ids: [ tag1.id, tag2.id ]
        )

        result = creator.call

        expect(result.success?).to be true
        expect(result.blog.tags).to include(tag1, tag2)
      end

      it 'creates blog without tags when tag_ids is empty' do
        creator = described_class.new(
          title: 'Test Blog',
          content: 'Test Content',
          tag_ids: []
        )

        result = creator.call

        expect(result.success?).to be true
        expect(result.blog.tags).to be_empty
      end
    end

    context 'with invalid attributes' do
      it 'returns failure when title is missing' do
        creator = described_class.new(content: 'Test Content')

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include('Invalid data')
      end

      it 'returns failure when content is missing' do
        creator = described_class.new(title: 'Test Blog')

        result = creator.call
        expect(result.success?).to be false
      end

      it "returns failure when tag doesn't exist" do
        creator = described_class.new(
          title: 'Test Blog',
          content: 'Test Content',
          tag_ids: [ 99_999 ]
        )

        result = creator.call
        expect(result.success?).to be false
        expect(result.message).to include('Tag not found')
      end
    end

    context 'instrumentation' do
      it 'fires blog.created notification' do
        expect do
          creator = described_class.new(
            title: 'Test Blog',
            content: 'Test Content',
            tag_ids: [ tag1.id ]
          )
          creator.call
        end.to instrument('blog.created')
      end
    end
  end
end
