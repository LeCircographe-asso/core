module Admin
  class ExportsController < BaseController
    require "csv"

    def index
      p "#"*111
    end

    def newsletter_subscribed
      users = User.where(newsletter_subscribed: true).select(:first_name, :last_name, :email_address)
      csv_data = users_to_csv(users)
      send_data csv_data, filename: "utilisateur_newsletter.csv", type: "text/csv", disposition: "attachment"
      head :no_content
    end

    def users_to_csv(users)
      CSV.generate(headers: true) do |csv|
        csv << users.first.attributes.keys
        users.each do |user|
          csv << user.attributes.values
        end
      end
    end
  end
end
