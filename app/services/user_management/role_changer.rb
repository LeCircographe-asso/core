# frozen_string_literal: true

module UserManagement
  # Change le system_role d'un compte (promotion ou retrait de rôle).
  # Règles (cf. docs/domain/role_permissions.md) :
  # - l'éditeur doit être de rang strictement supérieur au compte visé (User#can_change_role_of?) ;
  # - le nouveau rôle doit faire partie de ses rôles attribuables (User#can_assign_role?).
  class RoleChanger < BaseService
    attribute :user_id, :integer
    attribute :system_role, :string
    attribute :changed_by_id, :integer

    validates :user_id, :changed_by_id, presence: true
    validates :system_role, inclusion: { in: User.system_roles.keys }

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      user = User.find(user_id)
      changed_by = User.find(changed_by_id)

      return failure(I18n.t("services.errors.insufficient_permissions.role_change")) unless changed_by.can_change_role_of?(user)
      return success(user: user, message: I18n.t("services.success.role_unchanged")) if user.system_role == system_role
      return failure(I18n.t("services.errors.insufficient_permissions.role_assignment")) unless changed_by.can_assign_role?(system_role)

      previous_role = user.system_role
      return failure(I18n.t("services.validation.invalid_data_with_details", details: user.errors.full_messages.join(", "))) unless user.update(system_role: system_role)

      ActiveSupport::Notifications.instrument(
        "user.role_changed",
        user_id: user.id,
        person_id: user.person_id,
        changed_by_id: changed_by.id,
        from: previous_role,
        to: system_role
      )

      success(user: user, message: I18n.t("services.success.role_changed", name: user.full_name, role: I18n.t("admin.roles.labels.#{system_role}")))
    rescue ActiveRecord::RecordNotFound => e
      failure(I18n.t("services.errors.user_not_found", message: e.message))
    end
  end
end
