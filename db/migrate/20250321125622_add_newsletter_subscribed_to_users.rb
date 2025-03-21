class AddNewsletterSubscribedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :newsletter_subscribed, :boolean
  end
end
