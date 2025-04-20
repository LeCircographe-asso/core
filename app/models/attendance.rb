class Attendance < ApplicationRecord
  include SoftDeletable

  belongs_to :attendance_list, optional: true
  belongs_to :user
  belongs_to :book_of_entry, optional: true

  validates :arrival_time, presence: true
  validates :user_id, uniqueness: { scope: :attendance_list_id, message: "est déjà marqué présent dans cette liste" }

  after_create :decrement_book_of_entry

private

  def decrement_book_of_entry
    return unless book_of_entry

    if book_of_entry.remaining > 0
      book_of_entry.update(remaining: book_of_entry.remaining - 1)

      if book_of_entry.remaining <= 0
        book_of_entry.update(status: :inactive)
      end
    end
  end
end
