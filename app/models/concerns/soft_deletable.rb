module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Scopes pour les enregistrements actifs et archivés
    scope :active, -> { where(deleted_at: nil) }
    scope :archived, -> { where.not(deleted_at: nil) }
  end

  # Vérifier si l'enregistrement est archivé
  def archived?
    deleted_at.present?
  end

  # Archiver l'enregistrement (soft delete)
  def archive!
    return false if respond_to?(:has_financial_data?) && has_financial_data?
    
    update!(deleted_at: Time.current)
  end

  # Restaurer l'enregistrement
  def restore!
    update!(deleted_at: nil)
  end

  # Vérifier si l'enregistrement peut être archivé
  def can_be_archived?
    !archived? && (!respond_to?(:has_financial_data?) || !has_financial_data?)
  end
end


