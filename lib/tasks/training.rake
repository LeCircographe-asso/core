namespace :training do
  desc "Gestion des sessions d'entraînement"
  
  task create_session: :environment do
    if TrainingSession.create_for_today
      puts "✓ Session créée pour le #{Date.current}"
    else
      puts "✗ Erreur lors de la création de la session"
    end
  end

  task close_expired: :environment do
    count = TrainingSession.where('date < ?', Date.current)
                          .where(status: 'open')
                          .update_all(status: 'closed')
    puts "✓ #{count} session(s) fermée(s)"
  end

  task generate_report: :environment do
    filename = TrainingSessionReportService.save_daily_report
    puts "✓ Rapport sauvegardé : #{filename}"
  end

  task daily_maintenance: :environment do
    Rake::Task["training:close_expired"].invoke
    Rake::Task["training:create_session"].invoke
    Rake::Task["training:generate_report"].invoke
  end
end 