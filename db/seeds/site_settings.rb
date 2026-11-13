# frozen_string_literal: true

# Réglages singletons du site. `.current` les crée à la volée si besoin, mais les poser ici évite
# qu'une simple visite publique (GET) écrive en base sur une base fraîche. Idempotent.
ExceptionalClosure.current
BugReportWidgetSetting.current
