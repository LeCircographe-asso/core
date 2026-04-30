# Base class pour tous les services
# Fournit les méthodes communes success/failure et OpenStruct
require 'ostruct'

class BaseService
  include ActiveModel::Model
  include ActiveModel::Attributes

  private

  # Méthode générique pour créer une réponse de succès
  # Accepte des arguments nommés qui seront inclus dans l'OpenStruct
  def success(**data)
    OpenStruct.new(
      success?: true,
      message: data.delete(:message) || 'Operation completed successfully',
      **data
    )
  end

  # Méthode générique pour créer une réponse d'échec
  def failure(message, errors: nil)
    OpenStruct.new(
      success?: false,
      errors: errors || [message],
      message: message
    )
  end
end
