# frozen_string_literal: true

module Versionable
  extend ActiveSupport::Concern

  # Vérifier si c'est la version actuelle
  def current_version?
    effective_until.nil?
  end

  # Vérifier si c'est une version expirée
  def expired_version?
    effective_until.present? && effective_until < Date.current
  end

  # Vérifier si c'est une version future
  def future_version?
    effective_from.present? && effective_from > Date.current
  end

  # Obtenir la version active à une date donnée
  def self.version_at(model_class, date = Date.current)
    model_class.where("effective_from <= ? AND (effective_until IS NULL OR effective_until >= ?)", date, date)
  end

  # Méthodes de classe pour la gestion des versions
  class_methods do
    # Obtenir toutes les versions actives
    def current_versions
      where(effective_until: nil)
    end

    # Obtenir toutes les versions expirées
    def expired_versions
      where.not(effective_until: nil).where(effective_until: ...Date.current)
    end

    # Obtenir la version active à une date donnée
    def version_at(date = Date.current)
      where("effective_from <= ? AND (effective_until IS NULL OR effective_until >= ?)", date, date)
    end

    # Créer une nouvelle version avec fermeture de l'ancienne
    def create_version!(attributes, effective_from: Date.current, reason: nil, user: nil)
      transaction do
        # Fermer la version actuelle
        current_versions.update_all(effective_until: effective_from - 1.day)

        # Créer la nouvelle version
        create!(attributes.merge(
                  effective_from: effective_from,
                  effective_until: nil,
                  version_reason: reason,
                  created_by: user
                ))
      end
    end
  end
end
