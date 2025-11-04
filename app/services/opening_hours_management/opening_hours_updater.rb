module OpeningHoursManagement
  class OpeningHoursUpdater < BaseService

    attribute :opening_hours, hash: true
    attribute :updated_by_id, :integer

    validates :opening_hours, presence: true
    validates :updated_by_id, presence: true

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        updated_by = User.find(updated_by_id)

        # Vérifier les permissions
        unless updated_by.super_admin? || updated_by.admin?
          return failure("Insufficient permissions to update opening hours")
        end

        # Valider les horaires
        unless valid_hours?(opening_hours)
          return failure("Erreur : l'heure de fermeture doit être après l'heure d'ouverture pour tous les jours ouverts.")
        end

        # Sauvegarder dans le cache
        Rails.cache.write("opening_hours", opening_hours)

        # Instrumentation pour audit
        ActiveSupport::Notifications.instrument(
          "opening_hours.updated",
          updated_by_id: updated_by_id,
          days_count: opening_hours.keys.length
        )

        success(opening_hours: opening_hours, message: "Opening hours updated successfully")
      rescue ActiveRecord::RecordNotFound => e
        failure("User not found: #{e.message}")
      rescue => e
        Rails.logger.error "[OpeningHoursUpdater] Error: #{e.message}"
        failure("Error updating opening hours: #{e.message}")
      end
    end

    private

    def valid_hours?(hours)
      hours.values.all? do |time|
        if time.to_s.downcase == "fermé"
          true
        elsif time.match?(/\A(?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9] - (?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9]\z/)
          # Validation logique : fermeture > ouverture
          open_time, close_time = time.split(" - ")
          open_minutes = time_to_minutes(open_time)
          close_minutes = time_to_minutes(close_time)
          close_minutes > open_minutes
        else
          false
        end
      end
    end

    def time_to_minutes(time_str)
      hour, minute = time_str.split(":").map(&:to_i)
      hour * 60 + minute
    end

    # success et failure hérités de BaseService
  end
end


