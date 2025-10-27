require "ostruct"

module People
  class Merger
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    attribute :source  # Person à fusionner (admin)
    attribute :target  # Person de destination (user)
    attribute :actor   # Qui fait la fusion
    attribute :merge_type, :string, default: "user_claim"
    
    validates :source, :target, :actor, presence: true
    
    def call
      return failure("Invalid data") unless valid?
      
      # Validation critique : empêcher fusion si les deux ont des Users différents
      if target.user.present? && source.user.present? && target.user.id != source.user.id
        log_merge_attempt("BLOCKED: Les deux Person ont des Users différents (source.user=#{source.user.id}, target.user=#{target.user.id})")
        return failure("Impossible de fusionner : conflit de comptes utilisateurs")
      end
      
      # Validation : empêcher fusion si source = target
      if source.id == target.id
        log_merge_attempt("BLOCKED: Tentative de fusion d'une Person avec elle-même")
        return failure("Impossible de fusionner une Person avec elle-même")
      end

      ActiveRecord::Base.transaction do
        log_merge_attempt("START")
        
        # Lier le User de la source à la cible si nécessaire
        if source.user.present? && target.user.nil?
          source.user.update!(person: target)
          log_merge_attempt("User #{source.user.id} transféré de Person #{source.id} à Person #{target.id}")
        elsif source.user.present? && target.user.present? && source.user.id != target.user.id
          # Cas déjà bloqué par validation ci-dessus, mais au cas où
          source.user.update!(person: nil, deleted_at: Time.current)
          log_merge_attempt("User #{source.user.id} archivé (doublon)")
        end

        # Transférer toutes les associations
        transfer_associations
        
        # Mettre à jour les informations de la cible
        update_target_info
        
        # Archiver la Person source
        source.archive!
        
        log_merge_attempt("SUCCESS: Person #{source.id} archivée, données transférées à Person #{target.id}")
        success(target, "Fiches fusionnées avec succès")
      end
    rescue => e
      log_merge_attempt("ERROR: #{e.message}")
      failure(e.message)
    end
    
    private
    
    def transfer_associations
      source.memberships.update_all(person_id: target.id)
      source.payments.update_all(person_id: target.id)
      source.attendances.update_all(person_id: target.id)
      source.book_of_entries.update_all(person_id: target.id)
      source.member_number_histories.update_all(person_id: target.id)
    end

    def update_target_info
      target.update!(
        first_name: source.first_name.presence || target.first_name,
        last_name: source.last_name.presence || target.last_name,
        email: source.email.presence || target.email,
        phone: source.phone.presence || target.phone,
        address: source.address.presence || target.address,
        city: source.city.presence || target.city,
        zip_code: source.zip_code.presence || target.zip_code,
        birth_date: source.birth_date.presence || target.birth_date,
        is_minor: source.is_minor || target.is_minor,
        newsletter_subscribed: source.newsletter_subscribed || target.newsletter_subscribed,
        newsletter_unsubscribe_token: source.newsletter_unsubscribe_token.presence || target.newsletter_unsubscribe_token
      )
    end

    def log_merge_attempt(message)
      Rails.logger.info("[MERGE] Type: #{merge_type} | Source: #{source&.id} | Target: #{target&.id} | Actor: #{actor&.email_address || 'system'} | #{message}")
    end
    
    def success(target, message)
      OpenStruct.new(success?: true, target: target, message: message)
    end
    
    def failure(message)
      OpenStruct.new(success?: false, errors: [message], message: message)
    end
  end
end
