# frozen_string_literal: true

class RemoveNewsletterSubscribedFromPeople < ActiveRecord::Migration[8.0]
  class MigrationPerson < ActiveRecord::Base
    self.table_name = "people"
  end

  class MigrationNewsletterSubscriber < ActiveRecord::Base
    self.table_name = "newsletter_subscribers"
  end

  def up
    return unless column_exists?(:people, :newsletter_subscribed)

    say_with_time "Backfill people.newsletter_subscribed into newsletter_subscribers" do
      MigrationPerson
        .where(newsletter_subscribed: true)
        .where.not(email: [ nil, "" ])
        .find_each do |person|
          subscriber = MigrationNewsletterSubscriber.find_or_initialize_by(email: person.email)
          subscriber.person_id = person.id
          subscriber.subscribed = true
          subscriber.source ||= "migration"
          subscriber.subscribed_at ||= Time.current
          subscriber.save!
        end
    end

    remove_column :people, :newsletter_subscribed
  end

  def down
    add_column :people, :newsletter_subscribed, :boolean, default: false unless column_exists?(:people, :newsletter_subscribed)
  end
end
