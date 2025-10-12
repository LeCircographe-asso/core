class AttendanceList < ApplicationRecord
has_many :attendances, dependent: :destroy
has_many :users, through: :attendances

enum :list_type, %i[
    training
    event
    meeting
  ], default: :training

enum :status, %i[
    open
    close
    archived
  ], default: :open

validates :name, presence: true
validates :start_date, presence: true
validates :end_date, presence: true
validate :end_after_start

before_validation :set_default_name, if: -> { name.blank? }

private

def end_after_start
    if start_date.present? && end_date.present? && end_date <= start_date
      errors.add(:end_date, "doit être après la date de début")
    end
end

def set_default_name
  return unless start_date.present?

  self.name = case list_type
  when "training"
                "Registre de présence #{start_date.strftime("%d/%m/%Y")}"
  when "event"
                "Événement du #{start_date.strftime("%d/%m/%Y")}"
  when "meeting"
                "Réunion du #{start_date.strftime("%d/%m/%Y")}"
  else
                "Liste de présence ##{id || Time.current.to_i}"
  end
end
end
