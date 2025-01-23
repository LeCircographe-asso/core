namespace :training do
  desc "Génère le rapport d'entraînement du jour"
  task generate_report: :environment do
    filename = TrainingSessionReportService.save_daily_report
    puts "Rapport généré : #{filename}"
  end

  desc "Affiche le rapport pour une date donnée (format: YYYY-MM-DD)"
  task :show_report, [:date] => :environment do |t, args|
    date = args[:date] ? Date.parse(args[:date]) : Date.current
    puts TrainingSessionReportService.read_report(date)
  end

  desc "Affiche les statistiques de fréquentation"
  task stats: :environment do
    stats = TrainingSessionReportService.send(:calculate_attendance_stats, Date.current)
    puts "\nStatistiques de fréquentation:"
    puts "- Maximum: #{stats[:max]} participants"
    puts "- Minimum: #{stats[:min]} participants"
    puts "- Moyenne: #{stats[:average].round(1)} participants"
  end
end 