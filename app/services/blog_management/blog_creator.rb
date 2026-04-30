# frozen_string_literal: true

module BlogManagement
  class BlogCreator < BaseService
    attribute :title, :string
    attribute :content, :string
    attribute :tag_ids, array: true, default: []

    validates :title, presence: true
    validates :content, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        blog = Blog.create!(
          title: title,
          content: content
        )

        # Associer les tags
        if tag_ids.present?
          tag_ids.each do |tag_id|
            tag = Tag.find(tag_id)
            blog.tags << tag
          end
        end

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          'blog.created',
          blog_id: blog.id,
          title: title,
          tag_count: tag_ids.length
        )

        success(blog: blog, message: 'Blog created successfully')
      rescue ActiveRecord::RecordNotFound => e
        failure("Tag not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[BlogCreator] Error: #{e.message}"
        failure("Error creating blog: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
