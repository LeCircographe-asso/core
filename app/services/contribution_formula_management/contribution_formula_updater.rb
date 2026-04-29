module ContributionFormulaManagement
  class ContributionFormulaUpdater < BaseService
    attribute :contribution_formula_id, :integer
    attribute :attributes, hash: true
    attribute :updated_by_id, :integer

    validates :contribution_formula_id, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        contribution_formula = ContributionFormula.find(contribution_formula_id)
        updated_by = User.find(updated_by_id)

        return failure('Seul le super-admin peut modifier des plans de cotisation') unless updated_by.super_admin?

        ActiveRecord::Base.transaction do
          contribution_formula.update!(attributes)

          ActiveSupport::Notifications.instrument(
            'contribution_formula.updated',
            contribution_formula_id: contribution_formula.id,
            updated_by_id: updated_by_id,
            changes: contribution_formula.previous_changes
          )

          success(contribution_formula: contribution_formula, message: 'Contribution formula updated successfully')
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Contribution formula or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[ContributionFormulaUpdater] Error: #{e.message}"
        failure("Error updating contribution formula: #{e.message}")
      end
    end
  end
end
