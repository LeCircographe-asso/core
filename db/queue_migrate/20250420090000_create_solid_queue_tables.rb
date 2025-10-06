class CreateSolidQueueTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_queue_jobs, if_not_exists: true do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments, null: false
      t.integer :priority, default: 0, null: false
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    create_table :solid_queue_semaphores, if_not_exists: true do |t|
      t.string :key, null: false
      t.integer :value, default: 0, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :solid_queue_jobs, :scheduled_at, where: "finished_at IS NULL", if_not_exists: true
    add_index :solid_queue_jobs, [ :queue_name, :finished_at ], if_not_exists: true
    add_index :solid_queue_jobs, :active_job_id, if_not_exists: true
    add_index :solid_queue_jobs, [ :concurrency_key, :finished_at ], if_not_exists: true

    add_index :solid_queue_semaphores, :key, unique: true, if_not_exists: true
    add_index :solid_queue_semaphores, :expires_at, if_not_exists: true
  end
end
