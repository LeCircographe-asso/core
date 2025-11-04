require 'rails_helper'

RSpec.describe BlogManagement::BlogDeleter do
  let(:blog) { create(:blog) }
  let(:admin_user) { create(:user, system_role: :admin) }
  let(:tag) { create(:tag) }

  describe "#call" do
    context "with valid attributes" do
      it "deletes blog successfully" do
        blog.tags << tag
        
        deleter = described_class.new(
          blog_id: blog.id,
          deleted_by_id: admin_user.id
        )
        
        result = deleter.call
        
        expect(result.success?).to be true
        expect { blog.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "clears tags before deletion" do
        blog.tags << tag
        
        deleter = described_class.new(
          blog_id: blog.id,
          deleted_by_id: admin_user.id
        )
        
        result = deleter.call
        
        expect(result.success?).to be true
        expect(blog.tags.count).to eq(0) # Tags cleared before deletion
      end
    end

    context "with invalid attributes" do
      it "returns failure when blog_id is missing" do
        deleter = described_class.new(deleted_by_id: admin_user.id)
        
        result = deleter.call
        expect(result.success?).to be false
      end

      it "returns failure when deleted_by_id is missing" do
        deleter = described_class.new(blog_id: blog.id)
        
        result = deleter.call
        expect(result.success?).to be false
      end

      it "returns failure when user doesn't have permissions" do
        volunteer = create(:user, system_role: :volunteer)
        
        deleter = described_class.new(
          blog_id: blog.id,
          deleted_by_id: volunteer.id
        )
        
        result = deleter.call
        expect(result.success?).to be false
        expect(result.message).to include("Insufficient permissions")
      end
    end

    context "instrumentation" do
      it "fires blog.deleted notification" do
        expect {
          deleter = described_class.new(
            blog_id: blog.id,
            deleted_by_id: admin_user.id
          )
          deleter.call
        }.to instrument("blog.deleted")
      end
    end
  end
end


