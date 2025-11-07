class MemberManagementService
  # Génère un numéro d'adhérent unique selon le format YYTNNN
  def self.generate_member_number(membership_type = "U")
    loop do
      # Format: YYTNNN (ex: 25C001, 25U400)
      year = Date.current.year.to_s.last(2) # 2025 -> 25
      type_code = (membership_type.upcase == "CIRQUE" || membership_type.upcase == "C") ? "C" : "U"

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
      if active_membership
        # Utiliser la catégorie pour déterminer le type
        case active_membership.membership_type.category
        when "circus"
          membership_type = "CIRQUE"
        when "basic"
          membership_type = "BASIQUE"
        else
          membership_type = "BASIQUE" # Par défaut
        end
      else
        # Par défaut, utiliser 'U' (Basique) si pas d'adhésion
        membership_type = "U"
      end
    end

    # Générer le nouveau numéro
    new_number = generate_member_number(membership_type)

    # Contourner la validation d'adhésion pour l'assignation du numéro
    person.skip_membership_validation = true
    person.update!(member_number: new_number)

    # Normaliser le type d'adhésion pour l'historique
    normalized_type = case membership_type.to_s.upcase
    when "CIRQUE", "C"
                       "Cirque"
    when "BASIQUE", "U", "BASIC"
                       "Basique"
    else
                       "Basique"
    end

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

  # Fusionne deux Person en gardant la "principale" (celle avec User ou plus récente)
  def self.merge_duplicate_persons(primary_person, secondary_person)
    ActiveRecord::Base.transaction do
      # 1. Fusionner les données de contact
      merged_data = {}

      # Email : garder celui qui existe
      if primary_person.email.blank? && secondary_person.email.present?
        merged_data[:email] = secondary_person.email
      end

      # Téléphone : garder celui qui existe
      if primary_person.phone.blank? && secondary_person.phone.present?
        merged_data[:phone] = secondary_person.phone
      end

      # Adresse : garder celle qui existe
      if primary_person.address.blank? && secondary_person.address.present?
        merged_data[:address] = secondary_person.address
        merged_data[:zip_code] = secondary_person.zip_code
        merged_data[:town] = secondary_person.town
        merged_data[:country] = secondary_person.country
      end

      # Mettre à jour la Person principale
      primary_person.update!(merged_data) if merged_data.any?

      # 2. Transférer toutes les relations
      transferred_count = 0

      # Transférer les adhésions
      memberships_count = secondary_person.memberships.count
      secondary_person.memberships.update_all(person_id: primary_person.id)
      transferred_count += memberships_count

      # Transférer les paiements
      payments_count = secondary_person.payments.count
      secondary_person.payments.update_all(person_id: primary_person.id)
      transferred_count += payments_count

      # Transférer les présences
      attendances_count = secondary_person.attendances.count
      secondary_person.attendances.update_all(person_id: primary_person.id)
      transferred_count += attendances_count

      # Transférer les carnets
      book_of_entries_count = secondary_person.book_of_entries.count
      secondary_person.book_of_entries.update_all(person_id: primary_person.id)
      transferred_count += book_of_entries_count

      # 3. Supprimer la Person secondaire
      secondary_person.destroy!

      {
        success: true,
        primary_person: primary_person,
        transferred_count: transferred_count,
        merged_fields: merged_data.keys
      }
    end
  rescue => e
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
    Person.where(member_number: [ nil, "" ]).each do |person|
      assign_member_number(person)
    end
  end

  # Analyse un numéro d'adhérent existant
  def self.parse_member_number(member_number)
    return nil unless member_number.present?

    # Format: YYTNNN
    match = member_number.match(/^(\d{2})([CU])(\d+)$/)
    return nil unless match

    {
      year: "20#{match[1]}", # 25 -> 2025
      type: match[2] == "C" ? "Cirque" : "Basique",
      number: match[3].to_i,
      full_year: match[1],
      type_code: match[2]
    }
  end

  # Valide le format d'un numéro d'adhérent
  def self.valid_member_number_format?(member_number)
    return false unless member_number.present?
    member_number.match?(/^\d{2}[CU]\d{3,5}$/)
  end

  # Génère des numéros d'adhérent pour les tests
  def self.generate_test_numbers(count = 5, membership_type = "U")
    # Créer des Person temporaires pour tester la séquence
    temp_people = []
    count.times do
      temp_person = Person.new(first_name: "Test", last_name: "User")
      temp_person.skip_membership_validation = true
      temp_person.member_number = generate_member_number(membership_type)
      temp_person.save! # Save to ensure sequential generation
      temp_people << temp_person.member_number
    end
    temp_people
  end
end
