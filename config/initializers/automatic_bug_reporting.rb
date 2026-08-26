# frozen_string_literal: true

# Capture automatiquement toute exception non gérée levée pendant une requête (500) —
# et, via la route catch-all + ApplicationController#url_not_found, les 404 de routage —
# pour les faire remonter dans BugReport (écran admin "Rapports de bug"), en plus des
# rapports envoyés manuellement par les utilisateurs. Actif dans tous les environnements
# (dev/staging/prod) : c'est justement l'intérêt, voir un bug local avant qu'il parte en prod.
#
# `process_action.action_controller` est l'événement d'instrumentation natif de Rails qui
# encadre le traitement complet d'une action (y compris le rendu de vue) — il expose
# `payload[:exception_object]` uniquement quand l'exception n'a été interceptée par aucun
# `rescue_from` applicatif, donc uniquement les vraies pannes non gérées. Ne modifie jamais
# la réponse (page d'erreur normale de Rails inchangée) : l'exception continue de se propager
# normalement après notification des subscribers.
Rails.application.config.after_initialize do
  ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*, payload|
    exception = payload[:exception_object]
    next unless exception

    request = payload[:request]

    Support::AutomaticBugReportJob.perform_later(
      error_class: exception.class.name,
      message: exception.message,
      kind: :error,
      path: payload[:path],
      backtrace: exception.backtrace,
      user_agent: request&.user_agent,
      person_id: Current.user&.person_id,
      reporter_role: Current.user&.system_role
    )
  rescue StandardError => e
    Rails.logger.error("[AutomaticBugReporting] failed to enqueue: #{e.message}")
  end
end
