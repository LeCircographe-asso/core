# frozen_string_literal: true

module Validatable
  extend ActiveSupport::Concern

  # Validations communes pour les emails
  def self.email_validation_options
    {
      uniqueness: { case_sensitive: false },
      format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas un email valide" },
      length: { maximum: 255 }
    }
  end

  # Validations communes pour les noms
  def self.name_validation_options
    {
      presence: true,
      length: { minimum: 2, maximum: 50 },
      format: { with: /\A[a-zA-ZÀ-ÿ\s\-']+\z/, message: 'ne peut contenir que des lettres, espaces, tirets et apostrophes' }
    }
  end

  # Validations communes pour les téléphones
  def self.phone_validation_options
    {
      format: { with: /\A\+?[0-9\s\-().]{10,20}\z/, message: "n'est pas un numéro de téléphone valide" },
      length: { maximum: 20 }
    }
  end

  # Validations communes pour les CGU
  def self.cgu_validation_options
    {
      acceptance: { message: 'Vous devez accepter les CGU pour continuer.' }
    }
  end

  # Validations communes pour la politique de confidentialité
  def self.privacy_policy_validation_options
    {
      acceptance: { message: 'Vous devez accepter la politique de confidentialité pour continuer.' }
    }
  end

  # Méthodes de validation personnalisées
  def validate_email_uniqueness_unless_person_email
    return if email.blank?

    # Si on a une Person associée avec le même email, c'est OK
    return if respond_to?(:person) && person&.email == email

    # Sinon, vérifier l'unicité normale
    return unless self.class.where(email: email).where.not(id: id).exists?

    errors.add(:email, 'est déjà utilisé')
  end

  def validate_phone_format
    return if phone.blank?
    return if phone.match?(/\A\+?[0-9\s\-().]{10,20}\z/)

    errors.add(:phone, "n'est pas un numéro de téléphone valide")
  end

  def validate_name_format
    return if first_name.blank? && last_name.blank?

    errors.add(:first_name, 'ne peut contenir que des lettres, espaces, tirets et apostrophes') if first_name.present? && !first_name.match?(/\A[a-zA-ZÀ-ÿ\s\-']+\z/)

    return unless last_name.present? && !last_name.match?(/\A[a-zA-ZÀ-ÿ\s\-']+\z/)

    errors.add(:last_name, 'ne peut contenir que des lettres, espaces, tirets et apostrophes')
  end

  # Méthodes de classe pour les validations
  class_methods do
    def validates_email(field = :email, options = {})
      validates field, Validatable.email_validation_options.merge(options)
    end

    def validates_names(first_name_field = :first_name, last_name_field = :last_name, options = {})
      validates first_name_field, Validatable.name_validation_options.merge(options)
      validates last_name_field, Validatable.name_validation_options.merge(options)
    end

    def validates_phone(field = :phone, options = {})
      validates field, Validatable.phone_validation_options.merge(options)
    end

    def validates_cgu(field = :cgu, options = {})
      validates field, Validatable.cgu_validation_options.merge(options)
    end

    def validates_privacy_policy(field = :privacy_policy, options = {})
      validates field, Validatable.privacy_policy_validation_options.merge(options)
    end
  end
end
