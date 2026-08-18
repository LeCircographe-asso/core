# frozen_string_literal: true

require "csv"

module Imports
  class MemberImportService
    include ActiveModel::Model

    Result = Struct.new(
      :success?, :created_count, :duplicate_count, :error_count, :errors, :message, :details,
      keyword_init: true
    )

    attr_accessor :csv_content

    def call
      return failure("CSV vide") if csv_content.blank?

      rows = parse_csv
      return failure("Aucune ligne à importer") if rows.empty?

      puts "[Import] Début import avec #{rows.count} lignes"

      created = 0
      duplicates = 0
      errors_list = []
      details = []

      rows.each_with_index do |row, index|
        line_num = index + 2 # +2 car header est ligne 1
        result = import_row(row, line_num)

        first = row[COLUMNS[:first_name]] || "?"
        last = row[COLUMNS[:last_name]] || "?"
        detail = {
          line: line_num,
          name: "#{first} #{last}",
          status: nil,
          message: nil
        }

        if result[:success]
          created += 1
          detail[:status] = :success
          detail[:message] = "✓ Créé"
          puts "[Line #{line_num}] ✓ Créé"
        elsif result[:duplicate]
          duplicates += 1
          detail[:status] = :duplicate
          detail[:message] = result[:error]
          puts "[Line #{line_num}] ⊘ Doublon: #{result[:error]}"
        else
          errors_list << result[:error]
          detail[:status] = :error
          detail[:message] = result[:error]
          puts "[Line #{line_num}] ✗ Erreur: #{result[:error]}"
        end

        details << detail
      end

      puts "[Import] Résultat final: #{created} créés, #{duplicates} doublons, #{errors_list.count} erreurs"

      success(
        created_count: created,
        duplicate_count: duplicates,
        error_count: errors_list.count,
        errors: errors_list,
        details: details,
        message: "Import terminé : #{created} créés, #{duplicates} doublons, #{errors_list.count} erreurs"
      )
    rescue StandardError => e
      Rails.logger.error("[MemberImportService] Import failed: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Erreur d'import : #{e.message}")
    end

    private

    def parse_csv
      # Auto-detect separator (comma or tab)
      first_line = csv_content.lines.first
      sep = first_line&.include?("\t") ? "\t" : ","

      # Clean encoding (Google Sheets export can have BOM)
      cleaned = csv_content.dup
      cleaned.force_encoding("UTF-8")
      cleaned.gsub!("\xEF\xBB\xBF", "") # Remove BOM if present

      CSV.parse(cleaned, headers: true, col_sep: sep, liberal_parsing: true, encoding: "UTF-8")
    rescue StandardError => e
      Rails.logger.error("[MemberImportService] CSV parse error: #{e.message}")
      puts "Error details: #{e.inspect}"
      []
    end

    # Colonnes accédées par position, pas par nom : le fichier a deux colonnes "N°
    # adhérent" (une redondante = numéro de ligne, l'autre = vrai numéro type "25C001")
    # qui ne se distinguent que par un espace final — la recherche par nom normalisé
    # (strip) les confondait et prenait la mauvaise. La position est sans ambiguïté.
    COLUMNS = {
      row_index: 0,
      member_number: 1,
      last_name: 2,
      first_name: 3,
      birth_date: 4,
      address: 5,
      zip_code: 6,
      town: 7,
      phone: 8,
      email: 9,
      occupation: 10,
      specialty: 11,
      image_rights: 12,
      newsletter: 13,
      get_involved: 14,
      amount: 15,
      payment_method: 16,
      payment_date: 17
    }.freeze

    def import_row(row, line_num)
      member_number = row[COLUMNS[:member_number]]&.strip
      first_name = row[COLUMNS[:first_name]]&.strip
      last_name = row[COLUMNS[:last_name]]&.strip
      email = row[COLUMNS[:email]]&.strip
      phone = row[COLUMNS[:phone]]&.strip
      birth_date = parse_date(row[COLUMNS[:birth_date]])
      address = row[COLUMNS[:address]]&.strip
      zip_code = row[COLUMNS[:zip_code]]&.strip
      town = row[COLUMNS[:town]]&.strip
      occupation = row[COLUMNS[:occupation]]&.strip
      specialty = row[COLUMNS[:specialty]]&.strip
      image_rights = truthy?(row[COLUMNS[:image_rights]])
      get_involved = truthy?(row[COLUMNS[:get_involved]])
      newsletter = truthy?(row[COLUMNS[:newsletter]])

      amount_str = row[COLUMNS[:amount]]
      amount_euros = amount_str&.gsub(/[€\s]/, "")&.to_f || 0
      amount_cents = (amount_euros * 100).to_i
      payment_method = map_payment_method(row[COLUMNS[:payment_method]])
      payment_date = parse_date(row[COLUMNS[:payment_date]]) || Date.current

      # Validation minimale
      return { success: false, error: "Ligne #{line_num}: Prénom ou Nom manquant" } if first_name.blank? || last_name.blank?

      # Détection doublon (email, téléphone, ou member_number)
      if member_number.present? && Person.exists?(member_number: member_number)
        return { success: false, duplicate: true, error: "Doublon: numéro d'adhérent #{member_number}" }
      end
      if email.present? && Person.exists?(email: email)
        return { success: false, duplicate: true, error: "Doublon: email #{email}" }
      end
      if phone.present? && Person.exists?(phone: phone)
        return { success: false, duplicate: true, error: "Doublon: téléphone #{phone}" }
      end

      # Le montant payé (7€/10€) détermine le tarif : réduit ou plein
      membership_type = MembershipType.circus_types.current_versions.find_by(price_cents: amount_cents) ||
                         MembershipType.circus_types.current_versions.order(:price_cents).first
      return { success: false, error: "Aucun type d'adhésion Cirque trouvé" } unless membership_type

      ActiveRecord::Base.transaction do
        person = Person.create!(
          first_name: first_name,
          last_name: last_name,
          email: email.presence,
          phone: phone.presence,
          birth_date: birth_date,
          address: address,
          zip_code: zip_code,
          town: town,
          occupation: occupation,
          specialty: specialty,
          image_rights: image_rights,
          get_involved: get_involved,
          member_number: member_number.presence
        )

        # Best-effort : un email malformé/dupliqué ne doit pas faire échouer tout l'import de la personne
        NewsletterSubscriber.create(email: email) if newsletter && email.present?

        membership_end = payment_date + 1.year
        membership = person.memberships.create!(
          membership_type: membership_type,
          started_at: payment_date,
          ended_at: membership_end,
          status: membership_end >= Date.current ? :active : :expired
        )

        if amount_cents.positive?
          payment_result = People::PaymentRecorder.new(
            person: person,
            recorded_by_id: system_user_id,
            payment_method: payment_method,
            status: "success",
            total_cents: amount_cents,
            notes: "Import CSV",
            payment_lines: [ { item_type: "Membership", item_id: membership.id, amount_cents: amount_cents, description: membership_type.name } ]
          ).call

          raise payment_result.message unless payment_result.success?

          # Payment n'a pas de champ dédié à la date historique : on force created_at
          # pour que le paiement importé reflète la date réelle du CSV, pas la date d'import.
          payment_result.payment.update_column(:created_at, payment_date)
        end
      end

      { success: true }
    rescue StandardError => e
      { success: false, error: "Ligne #{line_num}: #{e.message}" }
    end

    # Regex stricte plutôt que Date.strptime : %y de strptime consomme les 4 chiffres
    # de "2006" en absorbant "20" comme année 2-chiffres (→ 2020) et ignore silencieusement
    # le "06" restant sans lever d'erreur — bug découvert sur un import réel (naissance
    # 15/04/2006 devenait 15/04/2020). La regex fixe la largeur exacte du groupe année.
    def parse_date(date_str)
      return nil if date_str.blank?

      str = date_str.strip

      if str =~ %r{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}
        day, month, year = $1.to_i, $2.to_i, $3.to_i
      elsif str =~ %r{\A(\d{1,2})/(\d{1,2})/(\d{2})\z}
        day, month, year2 = $1.to_i, $2.to_i, $3.to_i
        year = year2 >= 30 ? 1900 + year2 : 2000 + year2
      elsif str =~ %r{\A(\d{4})-(\d{1,2})-(\d{1,2})\z}
        year, month, day = $1.to_i, $2.to_i, $3.to_i
      else
        return nil
      end

      return nil unless (1900..Date.current.year).cover?(year)

      Date.new(year, month, day)
    rescue ArgumentError, Date::Error
      nil
    end

    def truthy?(value)
      return false if value.blank?

      value.strip.downcase.in?(%w[oui yes 1 true])
    end

    def map_payment_method(method_str)
      return "cash" if method_str.blank?

      case method_str.strip.downcase
      when /espèces|cash/
        "cash"
      when /chèque|check/
        "cheque"
      when /carte|card/
        "card"
      when /virement|transfer/
        "transfer"
      else
        "cash"
      end
    end

    def system_user_id
      User.where(system_role: %i[admin super_admin]).first&.id || 1
    end

    def success(attrs)
      Result.new(success?: true, **attrs)
    end

    def failure(message)
      Result.new(
        success?: false,
        created_count: 0,
        duplicate_count: 0,
        error_count: 0,
        errors: [ message ],
        message: message
      )
    end
  end
end
