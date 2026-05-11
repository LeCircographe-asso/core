# frozen_string_literal: true

class PersistOpeningHoursSchedule < ActiveRecord::Migration[8.1]
  DAY_MAP = {
    "lundi" => 0,
    "mardi" => 1,
    "mercredi" => 2,
    "jeudi" => 3,
    "vendredi" => 4,
    "samedi" => 5,
    "dimanche" => 6
  }.freeze

  DEFAULT_SCHEDULE = {
    "lundi" => "Fermé",
    "mardi" => "14:00 - 22:00",
    "mercredi" => "14:00 - 22:00",
    "jeudi" => "14:00 - 22:00",
    "vendredi" => "14:00 - 22:00",
    "samedi" => "14:00 - 22:00",
    "dimanche" => "14:00 - 22:00"
  }.freeze

  def up
    add_column :opening_hours, :closed, :boolean, default: false, null: false
    add_reference :opening_hours, :updated_by_user, foreign_key: { to_table: :users }
    change_column_null :opening_hours, :open_at, true
    change_column_null :opening_hours, :close_at, true

    say_with_time "Deduplicating opening hours by day" do
      OpeningHourRecord.order(:day, updated_at: :desc, id: :desc).group_by(&:day).each_value do |rows|
        rows.drop(1).each(&:destroy!)
      end
    end

    say_with_time "Ensuring one opening hour row per weekday" do
      DEFAULT_SCHEDULE.each do |day_name, value|
        day_value = DAY_MAP.fetch(day_name)
        record = OpeningHourRecord.find_or_initialize_by(day: day_value)

        if value == "Fermé"
          record.closed = true
          record.open_at = nil
          record.close_at = nil
        else
          open_at, close_at = value.split(" - ")
          record.closed = false
          record.open_at = open_at
          record.close_at = close_at
        end

        record.save!
      end
    end

    add_index :opening_hours, :day, unique: true
  end

  def down
    remove_index :opening_hours, :day
    change_column_null :opening_hours, :open_at, false
    change_column_null :opening_hours, :close_at, false
    remove_reference :opening_hours, :updated_by_user, foreign_key: { to_table: :users }
    remove_column :opening_hours, :closed
  end

  class OpeningHourRecord < ApplicationRecord
    self.table_name = "opening_hours"
  end
end
