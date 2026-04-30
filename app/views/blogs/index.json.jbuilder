# frozen_string_literal: true

json.array! @blogs, partial: 'blogs/blog', as: :blog
