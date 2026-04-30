# frozen_string_literal: true

module UserManagement
  class UserDeleter < BaseService
    attribute :person_id, :integer
    attribute :deleted_by_id, :integer
    attribute :reason, :string

    validates :person_id, presence: true
    validates :deleted_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure('Invalid deletion data') unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the person and deleter
          person = Person.find(person_id)
          deleted_by = User.find(deleted_by_id)

          # Check if person has financial data (super_admin can bypass this)
          return failure('Cannot delete person with active financial data (memberships, contributions, or payments)') if person.has_financial_data? && !deleted_by.super_admin?

          # Check permissions - super_admin can delete anyone
          return failure('Insufficient permissions to delete this user') if person.user.present? && !deleted_by.super_admin? && !deleted_by.has_higher_permissions?(person.user)

          # Archive the person (soft delete)
          person.archive!

          success(person: person, message: 'User deleted successfully')
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue StandardError => e
        failure("Unexpected error: #{e.message}")
      end
    end

    # success et failure hérités de BaseService
  end
end
