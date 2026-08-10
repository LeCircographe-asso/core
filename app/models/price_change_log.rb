# frozen_string_literal: true

class PriceChangeLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true
  belongs_to :user, optional: true

  validates :action, presence: true

  # Action types: merged (corrigé sans jamais avoir été vendu), versioned (nouvelle version créée)

  def self.log(loggable, user, action, change_data = {})
    create!(
      loggable: loggable,
      user: user,
      action: action,
      change_data: change_data.to_json
    )
  end
end
