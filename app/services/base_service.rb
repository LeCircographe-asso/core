# frozen_string_literal: true

# Base class pour tous les services
# Fournit les méthodes communes success/failure et OpenStruct
require "ostruct"

class BaseService
  include ActiveModel::Model
  include ActiveModel::Attributes

  private

  # Méthode générique pour créer une réponse de succès
  # Accepte des arguments nommés qui seront inclus dans l'OpenStruct
  def success(**data)
    OpenStruct.new(
      success?: true,
      message: data.delete(:message) || I18n.t("services.base.success_default"),
      **data
    )
  end

  # Méthode générique pour créer une réponse d'échec
  def failure(message = nil, errors: nil)
    resolved_message = message || I18n.t("services.base.failure_default")
    OpenStruct.new(
      success?: false,
      errors: errors || [ resolved_message ],
      message: resolved_message
    )
  end
end
