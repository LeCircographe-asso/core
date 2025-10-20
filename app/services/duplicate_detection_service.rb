class DuplicateDetectionService
  def self.find_duplicates
    duplicates = []
    
    # 1. Détecter les Person avec le même nom et email
    name_email_duplicates = find_name_email_duplicates
    duplicates.concat(name_email_duplicates)
    
    # 2. Détecter les User avec le même email mais différentes Person
    email_duplicates = find_email_duplicates
    duplicates.concat(email_duplicates)
    
    # 3. Détecter les Person sans User mais avec un User existant avec le même email
    orphan_duplicates = find_orphan_duplicates
    duplicates.concat(orphan_duplicates)
    
    duplicates.uniq
  end
  
  def self.find_name_email_duplicates
    duplicates = []
    
    # Grouper par nom complet et email
    Person.where.not(email: [nil, '']).group(:first_name, :last_name, :email)
          .having('COUNT(*) > 1').each do |person|
      group = Person.where(first_name: person.first_name, 
                          last_name: person.last_name, 
                          email: person.email)
      duplicates << {
        type: :name_email_duplicate,
        description: "Personnes avec le même nom et email",
        records: group.to_a,
        severity: :high
      }
    end
    
    duplicates
  end
  
  def self.find_email_duplicates
    duplicates = []
    
    # User avec le même email mais liés à différentes Person
    User.joins(:person).group(:email_address)
        .having('COUNT(DISTINCT person_id) > 1').each do |user|
      users = User.joins(:person).where(email_address: user.email_address)
      duplicates << {
        type: :email_duplicate,
        description: "Comptes web avec le même email liés à différentes personnes",
        records: users.to_a,
        severity: :high
      }
    end
    
    duplicates
  end
  
  def self.find_orphan_duplicates
    duplicates = []
    
    # Person sans User mais avec un User existant avec le même email
    Person.left_joins(:user).where(users: { id: nil })
          .where.not(email: [nil, '']).each do |person|
      existing_user = User.find_by(email_address: person.email)
      
      if existing_user.present?
        duplicates << {
          type: :orphan_duplicate,
          description: "Personne sans compte web mais avec un compte existant",
          records: [person, existing_user],
          severity: :medium
        }
      end
    end
    
    duplicates
  end
  
  def self.cleanup_duplicates(duplicate_id)
    # Cette méthode pourrait être implémentée pour nettoyer automatiquement
    # les doublons détectés
    Rails.logger.info "Cleanup requested for duplicate ID: #{duplicate_id}"
  end
  
  def self.generate_report
    duplicates = find_duplicates
    
    {
      total_duplicates: duplicates.count,
      high_severity: duplicates.count { |d| d[:severity] == :high },
      medium_severity: duplicates.count { |d| d[:severity] == :medium },
      duplicates: duplicates
    }
  end
end
