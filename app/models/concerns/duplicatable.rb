module Duplicatable
  extend ActiveSupport::Concern

  # Méthodes de détection de doublons
  def self.find_duplicates_by_email(model_class, email_field = :email)
    model_class.group(email_field)
               .having("COUNT(*) > 1")
               .count
               .reject { |email, _| email.blank? }
               .map do |email, count|
      {
        type: :email,
        value: email,
        records: model_class.where(email_field => email),
        count: count
      }
    end
  end

  def self.find_duplicates_by_name(model_class, first_name_field = :first_name, last_name_field = :last_name)
    model_class.group(first_name_field, last_name_field)
               .having("COUNT(*) > 1")
               .count
               .map do |(first_name, last_name), count|
      {
        type: :name,
        value: "#{first_name} #{last_name}",
        records: model_class.where(first_name_field => first_name, last_name_field => last_name),
        count: count
      }
    end
  end

  def self.find_duplicates_by_phone(model_class, phone_field = :phone)
    model_class.group(phone_field)
               .having("COUNT(*) > 1")
               .count
               .reject { |phone, _| phone.blank? }
               .map do |phone, count|
      {
        type: :phone,
        value: phone,
        records: model_class.where(phone_field => phone),
        count: count
      }
    end
  end

  # Méthodes de fusion de doublons
  def self.merge_duplicates(primary_record, secondary_records, options = {})
    results = []

    secondary_records.each do |secondary|
      result = merge_duplicate_records(primary_record, secondary, options)
      results << {
        primary: primary_record.respond_to?(:full_name) ? primary_record.full_name : primary_record.id,
        secondary: secondary.respond_to?(:full_name) ? secondary.full_name : secondary.id,
        result: result
      }
    end

    results
  end

  def self.merge_duplicate_records(primary, secondary, options = {})
    return { success: false, error: "Cannot merge record with itself" } if primary.id == secondary.id

    ActiveRecord::Base.transaction do
      # Transférer les relations
      transfer_relations(primary, secondary, options)

      # Supprimer l'enregistrement secondaire
      secondary.destroy!

      { success: true, primary: primary, secondary: secondary }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def self.transfer_relations(primary, secondary, options = {})
    # Relations à transférer par défaut
    default_relations = %w[memberships payments contributions attendances]

    # Relations spécifiées dans les options
    relations_to_transfer = options[:relations] || default_relations

    relations_to_transfer.each do |relation|
      next unless secondary.respond_to?(relation)

      # Mettre à jour les clés étrangères
      secondary.send(relation).update_all("#{primary.class.name.downcase}_id" => primary.id)
    end
  end

  # Méthodes d'instance
  def find_duplicates_by_email
    self.class.where(email: email).where.not(id: id)
  end

  def find_duplicates_by_name
    return [] unless respond_to?(:first_name) && respond_to?(:last_name)

    self.class.where(first_name: first_name, last_name: last_name).where.not(id: id)
  end

  def find_duplicates_by_phone
    return [] unless respond_to?(:phone)

    self.class.where(phone: phone).where.not(id: id)
  end

  def has_duplicates?
    find_duplicates_by_email.exists? ||
    find_duplicates_by_name.exists? ||
    find_duplicates_by_phone.exists?
  end

  # Méthodes de classe
  class_methods do
    def find_all_duplicates
      duplicates = []
      duplicates += Duplicatable.find_duplicates_by_email(self)
      duplicates += Duplicatable.find_duplicates_by_name(self)
      duplicates += Duplicatable.find_duplicates_by_phone(self)
      duplicates
    end

    def cleanup_duplicates(options = {})
      results = []

      find_all_duplicates.each do |duplicate|
        records = duplicate[:records].to_a
        next if records.length < 2

        # Déterminer l'enregistrement principal
        primary = determine_primary_record(records)
        secondary = records - [ primary ]

        # Fusionner
        result = Duplicatable.merge_duplicates(primary, secondary, options)
        results.concat(result)
      end

      results
    end

    def determine_primary_record(records)
      # Priorité : 1. Avec User, 2. Plus récent, 3. Premier
      records.find { |r| r.respond_to?(:user) && r.user.present? } ||
      records.max_by(&:created_at) ||
      records.first
    end
  end
end
