# config/schedule.rb

set :output, "log/cron.log"  # Redirige les logs vers un fichier

# Planifier une tâche pour vérifier les adhésions expirant bientôt
every :day, at: '8:00am' do
  runner "MembershipExpirationReminderJob.perform_later"
end
