namespace :setup do
  desc "Installer les modèles de base du Circographe"
  task :models => :environment do
    puts "🎪 Vérification des modèles du Circographe..."

    # Vérifier et créer les types d'adhésion
    if defined?(MembershipType)
      puts "\n✅ Types d'adhésion déjà configurés"
    else
      puts "\n📝 Génération du modèle MembershipType..."
      system("rails generate model MembershipType \
             name:string \
             price:decimal \
             duration:integer \
             description:text \
             category:string")
    end

    # Vérifier et créer le modèle Donation
    if defined?(Donation)
      puts "\n✅ Modèle Donation déjà configuré"
    else
      puts "\n📝 Génération du modèle Donation..."
      system("rails generate model Donation \
             user:references \
             amount:decimal \
             payment_method:string \
             notes:text")
    end

    puts "\n🔄 Migration de la base de données..."
    system("rails db:migrate")

    # Création des données de base
    if defined?(MembershipType) && MembershipType.count == 0
      puts "\n🌱 Création des types d'adhésion de base..."
      MembershipType.create!([
        { 
          name: 'basic_membership',
          price: 1,
          duration: 365,
          description: 'Adhésion simple annuelle',
          category: 'membership'
        },
        { 
          name: 'circus_membership',
          price: 25,
          duration: 365,
          description: 'Adhésion circus annuelle',
          category: 'circus_membership'
        }
      ])
    end

    if defined?(SubscriptionType) && SubscriptionType.count == 0
      puts "\n🌱 Création des types d'abonnement..."
      SubscriptionType.create!([
        { name: 'daily', price: 4, duration: 1, description: 'Accès journée' },
        { name: 'booklet', price: 30, duration: -1, description: 'Carnet 10 entrées' },
        { name: 'trimestrial', price: 65, duration: 90, description: 'Abonnement 3 mois' },
        { name: 'annual', price: 150, duration: 365, description: 'Abonnement annuel' }
      ])
    end

    puts "\n✅ Configuration terminée !"
  end

  desc "Vérifier l'état des modèles"
  task :check => :environment do
    puts "🔍 Vérification de l'état des modèles..."
    
    {
      'TrainingAttendee' => defined?(TrainingAttendee),
      'SubscriptionType' => defined?(SubscriptionType),
      'MembershipType' => defined?(MembershipType),
      'Donation' => defined?(Donation)
    }.each do |model, exists|
      status = exists ? '✅' : '❌'
      puts "#{status} #{model}"
    end

    if defined?(MembershipType)
      puts "\nTypes d'adhésion disponibles:"
      MembershipType.all.each do |type|
        puts "- #{type.name} (#{type.price}€)"
      end
    end

    if defined?(SubscriptionType)
      puts "\nTypes d'abonnement disponibles:"
      SubscriptionType.all.each do |type|
        puts "- #{type.name} (#{type.price}€)"
      end
    end

    if defined?(Donation)
      puts "\nDons reçus:"
      total = Donation.sum(:amount)
      count = Donation.count
      puts "Total: #{total}€ (#{count} dons)"
    end
  end

  desc "Nettoyer les doublons"
  task :clean => :environment do
    if defined?(SubscriptionType)
      puts "🧹 Nettoyage des types d'abonnement en double..."
      SubscriptionType.select(:name).group(:name).having("count(*) > 1").each do |duplicate|
        extras = SubscriptionType.where(name: duplicate.name)[1..-1]
        extras.each(&:destroy)
      end
    end

    if defined?(MembershipType)
      puts "🧹 Nettoyage des types d'adhésion en double..."
      MembershipType.select(:name).group(:name).having("count(*) > 1").each do |duplicate|
        extras = MembershipType.where(name: duplicate.name)[1..-1]
        extras.each(&:destroy)
      end
    end
    
    puts "✨ Nettoyage terminé !"
  end
end 