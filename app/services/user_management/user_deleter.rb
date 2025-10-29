require "ostruct"

module UserManagement
  class UserDeleter
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person_id, :integer
    attribute :deleted_by_id, :integer
    attribute :reason, :string

    validates :person_id, presence: true
    validates :deleted_by_id, presence: true
    validates :reason, presence: true

    def call
      return failure("Invalid deletion data") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Find the person and deleter
          person = Person.find(person_id)
          deleted_by = User.find(deleted_by_id)

          # Check if person has financial data (super_admin can bypass this)
          if person.has_financial_data? && !deleted_by.super_admin?
            return failure("Cannot delete person with active financial data (memberships, contributions, or payments)")
          end

          # Check permissions - super_admin can delete anyone
          if person.user.present? && !deleted_by.super_admin? && !deleted_by.has_higher_permissions?(person.user)
            return failure("Insufficient permissions to delete this user")
          end

          # Archive the person (soft delete)
          person.archive!

          success(person: person)
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue => e
        failure("Unexpected error: #{e.message}")
      end
    end

    private

    def success(data = {})
      OpenStruct.new(success?: true, **data)
    end

    def failure(message)
      OpenStruct.new(success?: false, message: message)
    end
  end
end
