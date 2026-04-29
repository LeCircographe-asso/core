module ContributionFormulaManagement
  class ContributionFormulaDeleter < BaseService
    attribute :contribution_formula_id, :integer
    attribute :deleted_by_id, :integer

    validates :contribution_formula_id, presence: true
    validates :deleted_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        contribution_formula = ContributionFormula.find(contribution_formula_id)
        deleted_by = User.find(deleted_by_id)

        return failure('Seul le super-admin peut supprimer des plans de cotisation') unless deleted_by.super_admin?

        return failure("Impossible de supprimer ce plan car il est utilisé par des carnets d'entrées") if contribution_formula.contributions.any?

        ActiveRecord::Base.transaction do
          contribution_formula.destroy!

          ActiveSupport::Notifications.instrument(
            'contribution_formula.deleted',
            contribution_formula_id: contribution_formula.id,
            deleted_by_id: deleted_by_id
          )

          success(message: 'Contribution formula deleted successfully')
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Contribution formula or User not found: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[ContributionFormulaDeleter] Error: #{e.message}"
        failure("Error deleting contribution formula: #{e.message}")
      end
    end
  end
end
