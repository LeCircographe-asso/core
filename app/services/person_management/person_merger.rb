module PersonManagement
  class PersonMerger < BaseService

    attr_accessor :source, :target, :actor
    attr_writer :merge_type

    validates :source, presence: true
    validates :target, presence: true
    validates :actor, presence: true
    validates :merge_type, inclusion: { in: %w[admin_merge duplicate_cleanup] }
    
    def merge_type
      @merge_type ||= "admin_merge"
    end

    def call
      return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

      begin
        ActiveRecord::Base.transaction do
          # Vérifier que source et target sont différents
          if source.id == target.id
            return failure("Cannot merge person with itself")
          end

          # Utiliser le service existant MemberManagementService
          result = MemberManagementService.merge_duplicate_persons(target, source)

          if result[:success]
            # Instrumentation pour audit
            ActiveSupport::Notifications.instrument(
              "person.merged",
              source_person_id: source.id,
              target_person_id: target.id,
              actor_id: actor.id,
              merge_type: merge_type,
              transferred_count: result[:transferred_count],
              merged_fields: result[:merged_fields]
            )

            success(
              primary_person: result[:primary_person],
              transferred_count: result[:transferred_count],
              merged_fields: result[:merged_fields],
              message: "Persons merged successfully"
            )
          else
            failure(result[:error] || "Merge failed")
          end
        end
      rescue => e
        Rails.logger.error "[PersonMerger] Error: #{e.message}"
        failure("Error merging persons: #{e.message}")
      end
    end

    private

    # success et failure hérités de BaseService
  end
end
