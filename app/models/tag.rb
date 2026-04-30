# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :tag_blogs
  has_many :blogs, through: :tag_blogs
end
