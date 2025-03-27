class AttendanceList < ApplicationRecord

has_many :attendances, dependent: :destroy
has_many :users, through: :attendances

enum :list_type, %i[
    training 
    event 
    meeting
  ] ,default: :training

enum :status, %i[
    open 
    close 
    archived
  ] ,default: :open

validates :start_date, presence: true
validates :end_date, presence: true
validate :end_after_start


private

def end_after_start
    if start_date.present? && end_date.present? && end_date <= start_date
      errors.add(:end_date, "doit être après la date de début")
  end
end
end 
