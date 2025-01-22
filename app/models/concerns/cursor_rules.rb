module CursorRules
  extend ActiveSupport::Concern

  included do
    # Règles de navigation pour les différents rôles
    NAVIGATION_RULES = {
      guest: {
        allowed_paths: ['/login', '/register'],
        redirect_path: '/login'
      },
      membership: {
        allowed_paths: ['/profile', '/trainings', '/events'],
        redirect_path: '/profile'
      },
      circus_membership: {
        allowed_paths: ['/profile', '/trainings', '/events', '/circus'],
        redirect_path: '/profile'
      },
      volunteer: {
        allowed_paths: ['/admin/trainings', '/admin/members'],
        redirect_path: '/admin/trainings'
      },
      admin: {
        allowed_paths: ['*'],  # Accès total
        redirect_path: '/admin/dashboard'
      },
      godmode: {
        allowed_paths: ['*'],  # Accès total
        redirect_path: '/admin/dashboard'
      }
    }

    # Règles d'accès aux fonctionnalités
    ACCESS_RULES = {
      can_manage_users: -> { admin? || godmode? },
      can_manage_memberships: -> { admin? || godmode? },
      can_record_training: -> { volunteer? || admin? || godmode? },
      can_view_statistics: -> { admin? || godmode? },
      can_manage_payments: -> { admin? || godmode? }
    }
  end

  # Méthodes d'instance pour vérifier les accès
  def allowed_to_access?(path)
    rules = NAVIGATION_RULES[role.to_sym]
    return true if rules[:allowed_paths].include?('*')
    rules[:allowed_paths].any? { |allowed| path.start_with?(allowed) }
  end

  def redirect_path
    NAVIGATION_RULES[role.to_sym][:redirect_path]
  end

  def can?(action)
    ACCESS_RULES[action]&.call
  end
end 