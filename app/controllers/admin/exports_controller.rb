# frozen_string_literal: true

module Admin
  class ExportsController < BaseController
    require "csv"

    before_action :require_admin_rights

    def index
    end

    def newsletter_subscribed
      subscribers = NewsletterSubscriber.subscribed.includes(:person).order(:email)
      csv_data = users_to_csv_newsletter(subscribers)
      send_data csv_data, filename: "utilisateur_newsletter.csv", type: "text/csv", disposition: "attachment"
    end

    def all_users
      people = Person.active.includes(:newsletter_subscriber, :user).order(:last_name, :first_name)
      csv_data = users_to_csv(people)
      send_data csv_data, filename: "tous_les_utilisateurs.csv", type: "text/csv", disposition: "attachment"
    end

    def users_to_csv(people)
      return "" if people.empty?

      CSV.generate(headers: true) do |csv|
        csv << %i[id first_name last_name email email_address birth_date address zip_code town phone occupation specialty newsletter_subscribed created_at]
        people.each do |person|
          csv << [
            person.id,
            person.first_name,
            person.last_name,
            person.email,
            person.user&.email_address,
            person.birth_date,
            person.address,
            person.zip_code,
            person.town,
            person.phone,
            person.occupation,
            person.specialty,
            person.newsletter_subscribed?,
            person.created_at
          ]
        end
      end
    end

    def users_to_csv_newsletter(subscribers)
      return "" if subscribers.empty?

      CSV.generate(headers: true) do |csv|
        csv << %i[first_name last_name email]
        subscribers.each do |subscriber|
          csv << [ subscriber.person&.first_name, subscriber.person&.last_name, subscriber.email ]
        end
      end
    end
  end
end
