# Legacy DDD vocabulary aliases — temporary.
#
# Before phase 3.1, two domain models were named after a non-canonical vocabulary:
#   - SubscriptionPlan -> ContributionFormula (cible)
#   - BookOfEntry      -> Contribution        (cible)
#
# The renames have been applied to the schema, the model classes and most direct
# call sites, but historical rows still exist in `payment_lines.item_type` with
# the legacy values "SubscriptionPlan" and "BookOfEntry". To keep polymorphic
# associations resolvable until the data migration in phase 3.2, we expose the
# legacy class names as constants that resolve to the new models.
#
# This file MUST be deleted as part of the phase 3.2 cleanup, together with the
# data migration that rewrites `payment_lines.item_type`.

Rails.application.config.to_prepare do
  Object.const_set(:SubscriptionPlan, ContributionFormula) unless Object.const_defined?(:SubscriptionPlan)
  Object.const_set(:BookOfEntry, Contribution) unless Object.const_defined?(:BookOfEntry)
end
