# frozen_string_literal: true

class MemberManagementService
  # Génère un numéro d'adhérent unique selon le format YYTNNN
  def self.generate_member_number(membership_type = "U")
    loop do
      # Format: YYTNNN (ex: 25C001, 25U400)
      year = Date.current.year.to_s.last(2) # 2025 -> 25
      type_code = MemberNumberManagement::Policy.type_code_for(membership_type)

      # Chercher le dernier numéro pour cette année et ce type
      # Utiliser l'historique ET les numéros actuels pour éviter les conflits
      pattern = "#{year}#{type_code}%"

      # Numéros actuels
      current_numbers = Person.where("member_number LIKE ?", pattern)
                              .pluck(:member_number)
                              .map { |num| num.gsub(/^\d{2}[CU]/, "").to_i }

      # Numéros dans l'historique
      history_numbers = MemberNumberHistory.where("member_number LIKE ?", pattern)
                                           .pluck(:member_number)
                                           .map { |num| num.gsub(/^\d{2}[CU]/, "").to_i }

      # Prendre le maximum entre les deux
      last_number = (current_numbers + history_numbers).max || 0

      new_number = last_number + 1

      # Déterminer le padding selon le nombre de chiffres nécessaires
      # Actuellement 3 chiffres (001-999), extensible à 4 ou 5
      padding = new_number > 999 ? 4 : 3
      padding = 5 if new_number > 9999 # Pour la scalabilité future

      member_number = "#{year}#{type_code}#{new_number.to_s.rjust(padding, '0')}"

      # Vérifier l'unicité dans les deux tables
      break member_number unless Person.exists?(member_number: member_number) ||
                                 MemberNumberHistory.exists?(member_number: member_number)
    end
  end

  # Assigne un numéro d'adhérent à une Person
  def self.assign_member_number(person, membership_type = nil)
    return person.member_number if person.member_number.present?

    # Déterminer le type d'adhésion
    if membership_type.nil?
      # Chercher l'adhésion active la plus récente
      active_membership = person.memberships.active.order(:created_at).last
      membership_type = if active_membership
                          # Utiliser la catégorie pour déterminer le type
                          case active_membership.membership_type.category
                          when "circus"
                            "CIRQUE"
                          when "basic"
                            "BASIQUE"
                          else
                            "BASIQUE" # Par défaut
                          end
      else
                          # Par défaut, utiliser 'U' (Basique) si pas d'adhésion
                          "U"
      end
    end

    # Générer le nouveau numéro
    new_number = generate_member_number(membership_type)

    # Contourner la validation d'adhésion pour l'assignation du numéro
    person.skip_membership_validation = true
    person.update!(member_number: new_number)

    # Normaliser le type d'adhésion pour l'historique
    normalized_type = MemberNumberManagement::Policy.type_label_for(membership_type)

    # Créer l'historique
    person.member_number_histories.create!(
      member_number: new_number,
      membership_type: normalized_type,
      year: Date.current.year,
      notes: "Numéro d'adhérent initial",
      assigned_at: Time.current
    )

    person.member_number
  end

  # Réémet un numéro d'adhérent lors d'une reprise d'adhésion : contrairement à
  # #assign_member_number (première assignation), la Person a déjà un numéro — on le
  # remplace et on trace le changement, sur le même modèle que
  # People::MembershipUpgrader#handle_member_number_change!.
  def self.reissue_member_number!(person, membership_type:, recorded_by:)
    old_number = person.member_number
    new_number = generate_member_number(membership_type)

    close_out_previous_number!(person, old_number) if old_number.present?

    type_label = MemberNumberManagement::Policy.type_label_for(membership_type)
    person.member_number_histories.create!(
      member_number: new_number,
      membership_type: type_label,
      year: Date.current.year,
      notes: "Reprise d'adhésion #{type_label} — enregistré par #{recorded_by.email}",
      assigned_at: Time.current
    )

    person.skip_membership_validation = true
    person.update!(member_number: new_number)

    new_number
  end

  # Ferme l'entrée d'historique du numéro qu'on remplace. Beaucoup de personnes ont
  # un member_number posé hors du suivi historique (import CSV, saisie initiale
  # antérieure à member_number_histories) : #where(...).first renvoyait alors nil et
  # #reissue_member_number! perdait silencieusement la trace du numéro d'avant la
  # reprise. On reconstitue donc une entrée déjà close si aucune n'existe.
  def self.close_out_previous_number!(person, old_number)
    history = person.member_number_histories.where(member_number: old_number).order(:id).last

    if history
      history.mark_as_replaced! if history.current?
      return
    end

    parsed = MemberNumberManagement::Policy.parse(old_number)
    person.member_number_histories.create!(
      member_number: old_number,
      membership_type: parsed&.dig(:type) || "Basique",
      year: parsed&.dig(:year)&.to_i || person.created_at.year,
      notes: "Numéro antérieur non tracé (import ou saisie initiale) — reconstitué lors de la reprise",
      assigned_at: person.created_at,
      replaced_at: Time.current
    )
  end

  # Fusionne deux Person en gardant la "principale" (celle avec User ou plus récente)
  def self.merge_duplicate_persons(primary_person, secondary_person)
    ActiveRecord::Base.transaction do
      # 1. Fusionner les données de contact
      merged_data = {}

      # Email : garder celui qui existe
      merged_data[:email] = secondary_person.email if primary_person.email.blank? && secondary_person.email.present?

      # Téléphone : garder celui qui existe
      merged_data[:phone] = secondary_person.phone if primary_person.phone.blank? && secondary_person.phone.present?

      # Adresse : garder celle qui existe
      if primary_person.address.blank? && secondary_person.address.present?
        merged_data[:address] = secondary_person.address
        merged_data[:zip_code] = secondary_person.zip_code
        merged_data[:town] = secondary_person.town
        merged_data[:country] = secondary_person.country
      end

      # Préparer les mises à jour de contact
      if merged_data.any?
        secondary_person.update!(email: nil) if merged_data.key?(:email)
        secondary_person.update!(phone: nil) if merged_data.key?(:phone)

        primary_person.skip_membership_validation = true
        primary_person.update!(merged_data)
      end

      transferred_count = secondary_person.memberships.count +
                          secondary_person.payments.count +
                          secondary_person.attendances.count +
                          secondary_person.contributions.count

      merge_result = People::AccountMerger.new(
        source_person: secondary_person,
        target_person: primary_person,
        merge_type: "member_management_cleanup",
        destroy_source: true
      ).call
      raise merge_result.message unless merge_result.success?

      {
        success: true,
        primary_person: primary_person,
        transferred_count: transferred_count,
        merged_fields: merged_data.keys
      }
    end
  rescue StandardError => e
    {
      success: false,
      error: e.message
    }
  end

  # Identifie les doublons et propose des fusions
  def self.identify_duplicates
    duplicates = []

    # Doublons par nom
    Person.group(:first_name, :last_name)
          .having("COUNT(*) > 1")
          .pluck(:first_name, :last_name)
          .each do |first_name, last_name|
      group = Person.where(first_name: first_name, last_name: last_name)

      # Déterminer la Person principale (avec User ou plus récente)
      primary = group.joins(:user).first || group.order(:created_at).last
      secondary = group.where.not(id: primary.id)

      duplicates << {
        type: :name_duplicate,
        primary_person: primary,
        secondary_persons: secondary.to_a,
        description: "Personnes avec le même nom: #{primary.full_name}"
      }
    end

    duplicates
  end

  # Nettoie automatiquement les doublons
  def self.cleanup_duplicates
    results = []

    identify_duplicates.each do |duplicate|
      duplicate[:secondary_persons].each do |secondary|
        result = merge_duplicate_persons(duplicate[:primary_person], secondary)
        results << {
          primary: duplicate[:primary_person].full_name,
          secondary: secondary.full_name,
          result: result
        }
      end
    end

    results
  end

  # Assigne des numéros d'adhérent à toutes les Person qui n'en ont pas
  def self.assign_missing_member_numbers
    Person.where(member_number: [ nil, "" ]).find_each do |person|
      assign_member_number(person)
    end
  end

  # Analyse un numéro d'adhérent existant
  def self.parse_member_number(member_number)
    MemberNumberManagement::Policy.parse(member_number)
  end

  # Valide le format d'un numéro d'adhérent
  def self.valid_member_number_format?(member_number)
    MemberNumberManagement::Policy.valid_format?(member_number)
  end

  # Génère des numéros d'adhérent pour les tests
  def self.generate_test_numbers(count = 5, membership_type = "U")
    # Créer des Person temporaires pour tester la séquence
    temp_people = []
    count.times do
      temp_person = Person.new(first_name: "Test", last_name: "User", is_minor: false)
      temp_person.skip_membership_validation = true
      temp_person.member_number = generate_member_number(membership_type)
      temp_person.save!(validate: false) # Save to ensure sequential generation
      temp_people << temp_person.member_number
    end
    temp_people
  end
end
