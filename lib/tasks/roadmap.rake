namespace :roadmap do
  desc "Vérifier l'état d'avancement de la roadmap"
  task :check => :environment do
    class RoadmapChecker
      attr_reader :phase1_results, :phase2_results, :phase3_results

      def initialize
        @phase1_results = {}
        @phase2_results = {}
        @phase3_results = {}
      end

      def self.run
        new.check_all
      end

      def check_all
        puts "🎪 VÉRIFICATION DE LA ROADMAP DU CIRCOGRAPHE"
        puts "=========================================\n\n"

        check_phase_1
        check_phase_2
        check_phase_3
        
        display_summary
      end

      private

      def check_phase_1
        puts "📍 PHASE 1 : Modèles Fondamentaux"
        puts "--------------------------------"

        @phase1_results = {
          "MembershipType" => {
            exists: model_exists?("MembershipType"),
            fields: safe_check_fields("MembershipType", [
              :name, :price, :duration, :category
            ]) 
          },
          "TrainingAttendee" => {
            exists: model_exists?("TrainingAttendee"),
            fields: safe_check_fields("TrainingAttendee", [
              :user_id, :training_session_id
            ])
          },
          "Donation" => {
            exists: model_exists?("Donation"),
            fields: safe_check_fields("Donation", [
              :user_id, :amount, :notes
            ])
          }
        }

        display_model_results(@phase1_results)
      end

      def check_phase_2
        puts "\n📍 PHASE 2 : Interface Admin"
        puts "----------------------------"

        @phase2_results = {
          "Controllers" => {
            "Admin::BaseController" => controller_exists?("Admin::BaseController"),
            "Admin::MembersController" => controller_exists?("Admin::MembersController"),
            "Admin::DashboardController" => controller_exists?("Admin::DashboardController")
          },
          "Vues" => {
            "Dashboard" => check_view('app/views/admin/dashboard/index.html.erb'),
            "Gestion membres" => check_view('app/views/admin/members/index.html.erb'),
            "Passages" => check_view('app/views/admin/training_sessions/index.html.erb')
          },
          "Fonctionnalités" => {
            "Recherche membres" => check_controller_action("Admin::MembersController", "search"),
            "Ajout passage" => check_controller_action("Admin::TrainingSessionsController", "add_attendee"),
            "Gestion adhésions" => check_controller_action("Admin::MembersController", "manage_membership")
          }
        }

        display_feature_results(@phase2_results)
      end

      def check_phase_3
        puts "\n📍 PHASE 3 : Optimisation"
        puts "--------------------------"

        @phase3_results = {
          "Performance" => {
            "Index sur user_id" => check_index_exists(:training_attendees, :user_id),
            "Index sur training_session_id" => check_index_exists(:training_attendees, :training_session_id),
            "Cache fragments" => File.exist?('app/views/admin/dashboard/_stats.html.erb')
          },
          "Tests" => {
            "RSpec installé" => File.exist?('spec/rails_helper.rb'),
            "Tests modèles" => Dir.glob('spec/models/*_spec.rb').any?,
            "Tests système" => Dir.glob('spec/system/*_spec.rb').any?
          }
        }

        display_feature_results(@phase3_results)
      end

      private

      def model_exists?(model_name)
        Object.const_defined?(model_name)
      rescue
        false
      end

      def safe_check_fields(model_name, fields)
        return {} unless model_exists?(model_name)
        model = model_name.constantize
        check_model_fields(model, fields)
      rescue
        {}
      end

      def check_model_fields(model, fields)
        fields.each_with_object({}) do |field, result|
          result[field] = model.column_names.include?(field.to_s)
        end
      end

      def check_index_exists(table, column)
        ActiveRecord::Base.connection.index_exists?(table, column)
      rescue
        false
      end

      def controller_exists?(controller_name)
        controller_name.constantize < ApplicationController
      rescue
        false
      end

      def check_view(path)
        File.exist?(path)
      end

      def check_controller_action(controller_name, action)
        return false unless controller_exists?(controller_name)
        controller_name.constantize.instance_methods.include?(action.to_sym)
      rescue
        false
      end

      def display_model_results(results)
        results.each do |model, checks|
          status = checks[:exists] ? '✅' : '❌'
          puts "\n#{status} #{model}"
          
          if checks[:exists] && checks[:fields].any?
            puts "  Champs :"
            checks[:fields].each do |field, exists|
              status = exists ? '✅' : '❌'
              puts "  #{status} #{field}"
            end
          end
        end
      end

      def display_feature_results(results)
        results.each do |category, checks|
          puts "\n#{category}:"
          checks.each do |feature, exists|
            status = exists ? '✅' : '❌'
            puts "  #{status} #{feature}"
          end
        end
      end

      def display_summary
        puts "\n📊 RÉSUMÉ"
        puts "========="
        
        phase1_score = calculate_phase_score(@phase1_results)
        phase2_score = calculate_phase_score(@phase2_results)
        phase3_score = calculate_phase_score(@phase3_results)
        
        total_score = ((phase1_score + phase2_score + phase3_score) / 3.0).round(1)
        
        puts "\nProgression par phase :"
        puts "Phase 1 : #{phase1_score}% #{progress_emoji(phase1_score)}"
        puts "Phase 2 : #{phase2_score}% #{progress_emoji(phase2_score)}"
        puts "Phase 3 : #{phase3_score}% #{progress_emoji(phase3_score)}"
        
        puts "\nScore global : #{total_score}% #{progress_emoji(total_score)}"
        
        display_next_steps(phase1_score, phase2_score, phase3_score)
      end

      def calculate_phase_score(results)
        return 0 if results.empty?
        
        total = 0
        implemented = 0
        
        results.each do |_, checks|
          checks.each do |_, exists|
            total += 1
            implemented += 1 if exists
          end
        end
        
        ((implemented.to_f / total) * 100).round(1)
      end

      def progress_emoji(score)
        case score
        when 90..100 then "🌟"
        when 70..89 then "💪"
        when 40..69 then "��"
        else "🚧"
        end
      end

      def display_next_steps(phase1, phase2, phase3)
        puts "\n📝 PROCHAINES ÉTAPES"
        puts "-------------------"
        
        if phase1 < 100
          puts "\nPhase 1 :"
          puts "- Implémenter les modèles manquants"
          puts "- Compléter les champs requis"
        end
        
        if phase1 >= 70 && phase2 < 100
          puts "\nPhase 2 :"
          puts "- Mettre en place l'interface admin"
          puts "- Ajouter les fonctionnalités manquantes"
        end
        
        if phase2 >= 70 && phase3 < 100
          puts "\nPhase 3 :"
          puts "- Optimiser les performances"
          puts "- Compléter la suite de tests"
        end
      end
    end

    RoadmapChecker.run
  end
end 