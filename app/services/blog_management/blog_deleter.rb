# frozen_string_literal: true

module BlogManagement
  class BlogDeleter < BaseService
    attribute :blog_id, :integer
    attribute :deleted_by_id, :integer

    validates :blog_id, presence: true
    validates :deleted_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        blog = Blog.find(blog_id)
        deleted_by = User.find(deleted_by_id)

        # Vérifier les permissions
        return failure("Insufficient permissions to delete blog") unless deleted_by.super_admin? || deleted_by.admin?

        # Supprimer les associations de tags
        blog.tags.clear

        # Supprimer le blog
        blog.destroy!

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "blog.deleted",
          blog_id: blog_id,
          deleted_by_id: deleted_by_id,
          title: blog.title
        )

        success(message: "Blog deleted successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("Blog or User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[BlogDeleter] Error: #{e.message}"
        failure("Error deleting blog: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
