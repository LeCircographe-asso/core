# frozen_string_literal: true

require 'ostruct'

module People
  class PersonCreator
    include ActiveModel::Model
    include ActiveModel::Attributes

    Result = Struct.new(:success?, :person, :errors, :message, :created, keyword_init: true)

    attr_accessor :person

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :address, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
    attribute :birth_date, :date
    attribute :emergency_contact_name, :string
    attribute :emergency_contact_phone, :string
    attribute :notes, :string
    attribute :occupation, :string
    attribute :specialty, :string
    attribute :image_rights, :boolean, default: false
    attribute :get_involved, :boolean, default: false
    attribute :dyslexic_font, :boolean, default: false
    attribute :is_minor, :boolean, default: false

    attribute :allow_blank_attributes, :boolean, default: false

    def initialize(attributes = {})
      @provided_attribute_keys = extract_provided_attribute_keys(attributes)
      super
    end

    attribute :newsletter_subscribed, :boolean, default: nil
    attribute :newsletter_source, :string, default: 'admin'

    validates :first_name, presence: true, unless: :person_present?
    validates :last_name, presence: true, unless: :person_present?

    def call
      return failure('Invalid data', errors.full_messages) unless valid?

      ActiveRecord::Base.transaction do
        target_person, created = resolve_person

        update_person!(target_person) unless created
        ensure_newsletter!(target_person)

        success(
          person: target_person,
          message: created ? 'Person created successfully' : 'Person updated successfully',
          created: created
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      failure("Validation error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[People::PersonCreator] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      failure("Error creating or updating person: #{e.message}")
    end

    private

    def resolve_person
      return [person, false] if person.present?

      new_person = Person.new
      new_person.skip_membership_validation = true

      creation_attributes = if allow_blank_attributes
                              person_attributes
                            else
                              person_attributes.reject { |_k, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
                            end
      new_person.assign_attributes(creation_attributes)
      new_person.save!
      [new_person, true]
    end

    def update_person!(target_person)
      attributes = selected_person_attributes
      return if attributes.empty?

      target_person.skip_membership_validation = true
      target_person.assign_attributes(attributes)
      target_person.save! if target_person.changed?
    end

    def person_attributes
      {
        first_name: first_name,
        last_name: last_name,
        email: email,
        phone: phone,
        address: address,
        zip_code: zip_code,
        town: town,
        country: country,
        birth_date: birth_date,
        emergency_contact_name: emergency_contact_name,
        emergency_contact_phone: emergency_contact_phone,
        notes: notes,
        occupation: occupation,
        specialty: specialty,
        image_rights: image_rights,
        get_involved: get_involved,
        dyslexic_font: dyslexic_font,
        is_minor: is_minor
      }
    end

    def selected_person_attributes
      attributes = person_attributes
      attributes = attributes.slice(*@provided_attribute_keys) if @provided_attribute_keys.present?
      allow_blank_attributes ? attributes : attributes.compact_blank
    end

    def extract_provided_attribute_keys(attributes)
      return [] unless attributes.is_a?(Hash)

      permitted_keys = attributes.keys.map(&:to_sym)
      permitted_keys -= %i[person newsletter_subscribed newsletter_source allow_blank_attributes]
      permitted_keys
    end

    def ensure_newsletter!(target_person)
      return unless newsletter_subscribed && target_person.email.present?

      subscriber = NewsletterSubscriber.find_or_initialize_by(email: target_person.email.downcase)
      subscriber.person ||= target_person
      subscriber.source ||= newsletter_source
      subscriber.subscribed = true
      subscriber.save!
    end

    def success(person:, message:, created: false)
      Result.new(success?: true, person: person, errors: [], message: message, created: created)
    end

    def failure(message, error_list = nil)
      Result.new(success?: false, person: nil, errors: Array(error_list || message), message: message, created: false)
    end

    def person_present?
      person.present?
    end
  end
end
