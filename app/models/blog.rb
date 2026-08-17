# frozen_string_literal: true

class Blog < ApplicationRecord
  has_rich_text :content
  has_one_attached :cover_image
  has_many :tag_blogs
  has_many :tags, through: :tag_blogs
end
