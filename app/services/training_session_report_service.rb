class TrainingSessionReportService
  def self.generate_daily_report(date = Date.current)
    session = TrainingSession.find_by(date: date)
    return "Aucune session trouvée pour le #{date}" unless session

    report = ["=== Rapport d'entraînement du #{date} ===\n"]
    
    # Informations de base
    report << "Status: #{session.status}"
    report << "Capacité max: #{session.max_capacity}"
    report << "Enregistré par: #{session.recorded_by.email}"
    
    # Statistiques de fréquentation
    stats = calculate_attendance_stats(date)
    report << "\nStatistiques de fréquentation:"
    report << "- Aujourd'hui: #{session.training_attendees.count} participants"
    report << "- Maximum historique: #{stats[:max]} participants"
    report << "- Minimum historique: #{stats[:min]} participants"
    report << "- Moyenne: #{stats[:average].round(1)} participants"
    
    # Liste des participants
    report << "\nParticipants (#{session.training_attendees.count}):"
    session.training_attendees.includes(:user, :user_membership).each do |attendance|
      user = attendance.user
      membership = attendance.user_membership
      report << "- #{user.first_name} #{user.last_name} (#{user.email})"
      report << "  └ Adhésion: #{membership&.subscription_type&.name || 'Aucune'}"
    end

    report << "\n=== Fin du rapport ==="
    report.join("\n")
  end

  def self.save_daily_report(date = Date.current)
    report = generate_daily_report(date)
    
    # Créer le dossier s'il n'existe pas
    reports_dir = Rails.root.join('storage', 'training_reports')
    FileUtils.mkdir_p(reports_dir)
    
    # Sauvegarder le rapport
    filename = "training_report_#{date}.txt"
    File.write(reports_dir.join(filename), report)
    
    filename
  end

  def self.read_report(date)
    filename = Rails.root.join('storage', 'training_reports', "training_report_#{date}.txt")
    return "Rapport non trouvé pour le #{date}" unless File.exist?(filename)
    
    File.read(filename)
  end

  def self.calculate_attendance_stats(current_date)
    # Récupérer toutes les sessions jusqu'à aujourd'hui
    sessions = TrainingSession
      .where('date <= ?', current_date)
      .includes(:training_attendees)
    
    return { max: 0, min: 0, average: 0 } if sessions.empty?

    # Calculer les statistiques
    counts = sessions.map { |s| s.training_attendees.count }
    
    {
      max: counts.max,
      min: counts.min,
      average: counts.sum.to_f / counts.size
    }
  end
end 