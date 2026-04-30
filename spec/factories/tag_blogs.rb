# frozen_string_literal: true

FactoryBot.define do
  factory :tag_blog do
    association :tag
    association :blog
  end
end
