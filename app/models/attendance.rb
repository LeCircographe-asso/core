# frozen_string_literal: true

class Attendance < ApplicationRecord
  include Dateable

  belongs_to :person
  belongs_to :attendance_list, optional: true
  belongs_to :contribution, optional: true

  validates :date, presence: true
  # Une présence par personne et par jour. Le « like » d'un événement n'est pas
  # une présence : il vit dans `EventInterest`.
  validates :person_id, uniqueness: { scope: :date, message: :daily_presence_taken }

  before_create :set_date_if_missing
  after_create :decrement_contribution, if: -> { attendance_list_id.present? }

  scope :by_person, ->(person) { where(person: person) }

  scope :today, -> { where(date: Date.current) }
  scope :this_week, -> { where(date: Date.current.all_week) }
  scope :this_month, -> { where(date: Date.current.all_month) }

  private

  def set_date_if_missing
    self.date ||= Date.current
  end

  def decrement_contribution
    return unless contribution

    contribution.use_session!
  end
end
