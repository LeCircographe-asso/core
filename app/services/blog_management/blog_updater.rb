module BlogManagement
  class BlogUpdater < BaseService
    attribute :blog_id, :integer
    attribute :title, :string
    attribute :content, :string
    attribute :tag_ids, array: true, default: []
    attribute :updated_by_id, :integer

    validates :blog_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        blog = Blog.find(blog_id)
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        unless updated_by.super_admin? || updated_by.admin?
          return failure("Insufficient permissions to update blog")
        end

        # Mettre à jour le blog
        blog.update!(
          title: title,
          content: content
        )

        # Mettre à jour les tags
        blog.tags.clear
        if tag_ids.present?
          tag_ids.each do |tag_id|
            tag = Tag.find(tag_id)
            blog.tags << tag
          end
        end

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "blog.updated",
          blog_id: blog.id,
          updated_by_id: updated_by_id,
          changes: blog.previous_changes
        )

          success(blog: blog, message: "Blog updated successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("Blog or User not found: #{e.message}")
      rescue => e
        Rails.logger.error "[BlogUpdater] Error: #{e.message}"
        failure("Error updating blog: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
