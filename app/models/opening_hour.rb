# frozen_string_literal: true

class OpeningHour < ApplicationRecord
  DAYS = {
    lundi: 0,
    mardi: 1,
    mercredi: 2,
    jeudi: 3,
    vendredi: 4,
    samedi: 5,
    dimanche: 6
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

  belongs_to :updated_by_user, class_name: "User", optional: true

  enum :day, DAYS

  validates :day, presence: true, uniqueness: true
  validates :open_at, presence: true, unless: :closed?
  validates :close_at, presence: true, unless: :closed?
  validate :close_after_open, unless: :closed?

  scope :ordered, -> { order(:day) }

  def self.schedule_hash
    schedule = DEFAULT_SCHEDULE.dup

    ordered.each do |record|
      schedule[record.day.to_s] = record.formatted_range
    end

    schedule
  end

  def self.latest_update_entry
    ordered.where.not(updated_at: nil).order(updated_at: :desc, id: :desc).first
  end

  def self.replace_schedule!(schedule_hash:, updated_by_user:)
    transaction do
      DAYS.each_key do |day_name|
        raw_value = schedule_hash.fetch(day_name.to_s) { schedule_hash.fetch(day_name.to_sym, "Fermé") }
        record = find_or_initialize_by(day: day_name)
        record.updated_by_user = updated_by_user

        if raw_value.to_s.strip.casecmp("fermé").zero?
          record.closed = true
          record.open_at = nil
          record.close_at = nil
        else
          open_at, close_at = parse_range!(raw_value)
          record.closed = false
          record.open_at = open_at
          record.close_at = close_at
        end

        record.save!
      end
    end
  end

  def self.parse_range!(value)
    match = value.to_s.strip.match(/\A(\d{2}:\d{2}) - (\d{2}:\d{2})\z/)
    raise ArgumentError, "invalid time range" if match.nil?

    [ parse_time!(match[1]), parse_time!(match[2]) ]
  end

  def self.parse_time!(value)
    Time.zone.parse(value) || raise(ArgumentError, "invalid time")
  end

  def formatted_range
    return "Fermé" if closed?

    "#{open_at.strftime("%H:%M")} - #{close_at.strftime("%H:%M")}"
  end

  private

  def close_after_open
    return if open_at.blank? || close_at.blank?
    return if close_at > open_at

    errors.add(:close_at, "doit être après l'heure d'ouverture")
  end
end
