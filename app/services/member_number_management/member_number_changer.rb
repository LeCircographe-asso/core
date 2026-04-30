# frozen_string_literal: true

module MemberNumberManagement
  class MemberNumberChanger < BaseService
    attribute :person_id, :integer
    attribute :new_member_number, :string
    attribute :new_membership_type, :string
    attribute :change_notes, :string
    attribute :changed_by_id, :integer

    validates :person_id, presence: true
    validates :new_member_number, presence: true
    validates :changed_by_id, presence: true
    validate :valid_member_number_format
    validate :member_number_uniqueness

    def call
      return failure(I18n.t("services.validation.invalid_data_with_details", details: errors.full_messages.join(", "))) unless valid?

      begin
        person = Person.find(person_id)
        changed_by = User.find(changed_by_id)

        # Vérifier les permissions
        return failure("Insufficient permissions to change member number") unless can_change_member_number?(person, changed_by)

        old_number = person.member_number

        ActiveRecord::Base.transaction do
          # Changer le numéro via la méthode métier du modèle
          result = person.change_member_number(new_membership_type, change_notes)

          return failure("Impossible de changer le numéro d'adhérent") unless result

          # Mettre à jour le numéro actuel
          person.update!(member_number: new_member_number)

          # Mettre à jour l'historique avec le bon numéro
          current_history = person.current_member_number_history
          current_history&.update!(
            member_number: new_member_number,
            notes: change_notes.presence || "Changement manuel de #{old_number} vers #{new_member_number}"
          )

          # Instrumentation pour audit
          ActiveSupport::Notifications.instrument(
            "member_number.changed",
            person_id: person.id,
            old_number: old_number,
            new_number: new_member_number,
            changed_by_id: changed_by_id
          )

          success(
            person: person,
            old_number: old_number,
            new_number: new_member_number,
            message: "Numéro d'adhérent changé avec succès"
          )
        end
      rescue ActiveRecord::RecordNotFound => e
        failure("Person or User not found: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        failure("Validation error: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "[MemberNumberChanger] Error: #{e.message}"
        failure("Error changing member number: #{e.message}")
      end
    end

    private

    def valid_member_number_format
      return if MemberManagementService.valid_member_number_format?(new_member_number)

      errors.add(:new_member_number, "Format invalide. Utilisez le format YYTNNN (ex: 25C001)")
    end

    def member_number_uniqueness
      if Person.exists?(member_number: new_member_number) ||
         MemberNumberHistory.exists?(member_number: new_member_number)
        errors.add(:new_member_number, "Ce numéro d'adhérent est déjà utilisé")
      end
    end

    def can_change_member_number?(_person, changed_by)
      # Un admin/super_admin peut changer n'importe quel numéro
      changed_by.super_admin? || changed_by.admin?
    end

    # success et failure hérités de BaseService
  end
end
