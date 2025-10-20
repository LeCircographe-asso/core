class CreateBlogSystem < ActiveRecord::Migration[8.0]
  def change
    # Blog System
    create_table "blogs", force: :cascade do |t|
      t.string "title"
      t.string "content"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "tags", force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "tag_blogs", force: :cascade do |t|
      t.bigint "tag_id", null: false
      t.bigint "blog_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tag_id"], name: "index_tag_blogs_on_tag_id"
      t.index ["blog_id"], name: "index_tag_blogs_on_blog_id"
    end

    # Foreign Keys
    add_foreign_key "tag_blogs", "tags"
    add_foreign_key "tag_blogs", "blogs"
  end
end
