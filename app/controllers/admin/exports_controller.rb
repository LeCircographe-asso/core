# frozen_string_literal: true

module Admin
  class ExportsController < BaseController
    require 'csv'

    def index
      Rails.logger.debug '#' * 111
    end

    def newsletter_subscribed
      users = User.where(newsletter_subscribed: true).select(:first_name, :last_name, :email_address)
      csv_data = users_to_csv_newsletter(users)
      send_data csv_data, filename: 'utilisateur_newsletter.csv', type: 'text/csv', disposition: 'attachment'
    end

    def all_users
      users = User.where(deleted: false).select(
        :id, :first_name, :last_name, :email_address, :birthdate,
        :address, :zip_code, :town, :phone_number, :occupation,
        :specialty, :newsletter_subscribed, :created_at
      )
      csv_data = users_to_csv(users)
      send_data csv_data, filename: 'tous_les_utilisateurs.csv', type: 'text/csv', disposition: 'attachment'
    end

    def users_to_csv(users)
      return '' if users.empty?

      CSV.generate(headers: true) do |csv|
        # Utiliser les colonnes sélectionnées dans la requête
        selected_columns = %i[id first_name last_name email_address birthdate
                              address zip_code town phone_number occupation
                              specialty newsletter_subscribed created_at]

        csv << selected_columns
        users.each do |user|
          csv << selected_columns.map { |col| user.send(col) }
        end
      end
    end

    def users_to_csv_newsletter(users)
      return '' if users.empty?

      CSV.generate(headers: true) do |csv|
        csv << %i[first_name last_name email_address]
        users.each do |user|
          csv << [user.first_name, user.last_name, user.email_address]
        end
      end
    end
  end
end
