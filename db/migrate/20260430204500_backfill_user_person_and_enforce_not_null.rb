# frozen_string_literal: true

class BackfillUserPersonAndEnforceNotNull < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationPerson < ApplicationRecord
    self.table_name = "people"
  end

  def up
    MigrationUser.where(person_id: nil).find_each do |user|
      person = MigrationPerson.create!(
        first_name: "Web",
        last_name: "User",
        email: user.email_address
      )
      user.update_columns(person_id: person.id)
    end

    change_column_null :users, :person_id, false
  end

  def down
    change_column_null :users, :person_id, true
  end
end
