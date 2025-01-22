namespace :test do
  desc "Tester toutes les fonctionnalités du Circographe"
  task :features => :environment do
    class CircographeTester
      def self.run
        new.run_all_tests
      end

      def run_all_tests
        puts "🎪 TESTEUR DE FONCTIONNALITÉS DU CIRCOGRAPHE"
        puts "==========================================\n\n"

        test_models
        test_workflows
        test_admin_features
        test_performance
        
        display_summary
      end

      private

      def test_models
        puts "📝 Test des Modèles"
        puts "-------------------"

        test_results = {
          "User" => {
            model: defined?(User),
            methods: {
              "Rôles" => User.respond_to?(:roles),
              "Adhésion valide" => User.method_defined?(:active_circus_membership?),
              "Peut s'entraîner" => User.method_defined?(:can_train_today?)
            }
          },
          "MembershipType" => {
            model: defined?(MembershipType),
            data: MembershipType.count > 0
          },
          "SubscriptionType" => {
            model: defined?(SubscriptionType),
            data: SubscriptionType.count > 0
          },
          "TrainingSession" => {
            model: defined?(TrainingSession),
            methods: {
              "Session du jour" => TrainingSession.respond_to?(:current_or_create),
              "Ajout participant" => TrainingSession.method_defined?(:add_attendee!)
            }
          }
        }

        display_test_results(test_results)
      end

      def test_workflows
        puts "\n🔄 Test des Workflows"
        puts "--------------------"

        workflows = {
          "Inscription" => test_registration_workflow,
          "Passage" => test_training_workflow,
          "Adhésion" => test_membership_workflow,
          "Paiement" => test_payment_workflow
        }

        display_workflow_results(workflows)
      end

      def test_admin_features
        puts "\n👑 Test des Fonctionnalités Admin"
        puts "--------------------------------"

        admin_features = {
          "Controllers" => {
            "Admin::BaseController" => defined?(Admin::BaseController),
            "Admin::MembersController" => defined?(Admin::MembersController),
            "Admin::TrainingSessionsController" => defined?(Admin::TrainingSessionsController)
          },
          "Vues" => {
            "Dashboard" => File.exist?('app/views/admin/dashboard/index.html.erb'),
            "Sessions" => File.exist?('app/views/admin/training_sessions/index.html.erb')
          },
          "Permissions" => test_admin_permissions
        }

        display_admin_results(admin_features)
      end

      def test_performance
        puts "\n⚡ Test de Performance"
        puts "---------------------"

        performance_tests = {
          "Recherche" => benchmark { User.first },
          "Session" => benchmark { TrainingSession.current_or_create },
          "Passages" => benchmark { TrainingAttendee.today }
        }

        display_performance_results(performance_tests)
      end

      private

      def test_registration_workflow
        {
          "Création utilisateur" => User.method_defined?(:register),
          "Validation email" => User.method_defined?(:validate_email),
          "Confirmation" => User.method_defined?(:confirm!)
        }
      end

      def test_training_workflow
        {
          "Vérification accès" => User.method_defined?(:can_train_today?),
          "Enregistrement passage" => defined?(TrainingAttendee),
          "Validation quota" => UserMembership.method_defined?(:remaining_entries)
        }
      end

      def test_membership_workflow
        {
          "Types disponibles" => defined?(MembershipType),
          "Paiements" => defined?(Payment),
          "Conversion circus" => User.method_defined?(:upgrade_to_circus!)
        }
      end

      def test_payment_workflow
        {
          "Création paiement" => defined?(Payment),
          "Validation montant" => Payment&.method_defined?(:validate_amount),
          "Statut" => Payment&.method_defined?(:complete!)
        }
      end

      def test_admin_permissions
        {
          "Vérification rôle" => User.method_defined?(:has_privileges?),
          "Contrôle accès" => defined?(Admin::BaseController),
          "Audit actions" => defined?(AdminAudit)
        }
      end

      def benchmark
        start_time = Time.current
        yield
        ((Time.current - start_time) * 1000).round(2)
      rescue StandardError => e
        "❌ #{e.message}"
      end

      def display_test_results(results)
        results.each do |name, checks|
          puts "\n#{name}:"
          checks.each do |type, value|
            case value
            when Hash
              value.each do |method, exists|
                puts "  #{status_icon(exists)} #{method}"
              end
            else
              puts "  #{status_icon(value)} #{type}"
            end
          end
        end
      end

      def display_workflow_results(workflows)
        workflows.each do |name, checks|
          puts "\n#{name}:"
          checks.each do |feature, exists|
            puts "  #{status_icon(exists)} #{feature}"
          end
        end
      end

      def display_admin_results(features)
        features.each do |category, checks|
          puts "\n#{category}:"
          checks.each do |feature, exists|
            puts "  #{status_icon(exists)} #{feature}"
          end
        end
      end

      def display_performance_results(results)
        results.each do |name, time|
          status = time.is_a?(String) ? time : "#{time}ms"
          puts "#{name}: #{status}"
        end
      end

      def status_icon(condition)
        condition ? "✅" : "❌"
      end

      def display_summary
        puts "\n\n📊 RÉSUMÉ DES TESTS"
        puts "==================\n"

        results = {
          models: collect_model_results,
          workflows: collect_workflow_results,
          admin: collect_admin_results,
          performance: collect_performance_results
        }

        display_summary_stats(results)
        display_critical_issues(results)
        display_suggestions(results)
      end

      def collect_model_results
        {
          total: 4, # User, MembershipType, SubscriptionType, TrainingSession
          present: [
            defined?(User) ? "User" : nil,
            defined?(MembershipType) ? "MembershipType" : nil,
            defined?(SubscriptionType) ? "SubscriptionType" : nil,
            defined?(TrainingSession) ? "TrainingSession" : nil
          ].compact
        }
      end

      def collect_workflow_results
        workflows = {
          "Inscription" => test_registration_workflow,
          "Passage" => test_training_workflow,
          "Adhésion" => test_membership_workflow,
          "Paiement" => test_payment_workflow
        }

        {
          total: workflows.values.map(&:size).sum,
          implemented: workflows.values.map { |w| w.values.count(true) }.sum
        }
      end

      def display_summary_stats(results)
        puts "Modèles: #{results[:models][:present].size}/#{results[:models][:total]} ✨"
        puts "Workflows: #{results[:workflows][:implemented]}/#{results[:workflows][:total]} 🔄"
        
        total_score = calculate_total_score(results)
        puts "\nScore Global: #{total_score}% #{grade_emoji(total_score)}"
      end

      def display_critical_issues(results)
        puts "\n⚠️ POINTS CRITIQUES"
        puts "----------------"

        missing_models = results[:models][:total] - results[:models][:present].size
        if missing_models > 0
          puts "❌ #{missing_models} modèles manquants"
        end

        missing_workflows = results[:workflows][:total] - results[:workflows][:implemented]
        if missing_workflows > 0
          puts "❌ #{missing_workflows} fonctionnalités de workflow non implémentées"
        end
      end

      def display_suggestions(results)
        puts "\n💡 SUGGESTIONS D'AMÉLIORATION"
        puts "-------------------------"

        if results[:models][:present].size < results[:models][:total]
          puts "\n1. Modèles à implémenter:"
          missing_models = ["User", "MembershipType", "SubscriptionType", "TrainingSession"] - results[:models][:present]
          missing_models.each do |model|
            puts "   - #{model}"
            case model
            when "MembershipType"
              puts "     rails generate model MembershipType name:string price:decimal duration:integer category:string"
            when "TrainingSession"
              puts "     rails generate model TrainingSession date:date status:string max_capacity:integer"
            end
          end
        end

        if results[:workflows][:implemented] < results[:workflows][:total]
          puts "\n2. Workflows à compléter:"
          puts "   - Système de paiement (PaymentService)"
          puts "   - Gestion des passages (TrainingAttendeeService)"
          puts "   - Workflow d'inscription (RegistrationService)"
        end

        puts "\n3. Prochaines étapes recommandées:"
        puts "   1. Implémenter les modèles manquants"
        puts "   2. Configurer les associations"
        puts "   3. Ajouter les validations"
        puts "   4. Créer les services métier"
      end

      def calculate_total_score(results)
        model_score = (results[:models][:present].size.to_f / results[:models][:total]) * 100
        workflow_score = (results[:workflows][:implemented].to_f / results[:workflows][:total]) * 100
        
        ((model_score + workflow_score) / 2).round(1)
      end

      def grade_emoji(score)
        case score
        when 90..100 then "🏆"
        when 75..89 then "🌟"
        when 50..74 then "💪"
        else "🎯"
        end
      end
    end

    CircographeTester.run
  end
end 