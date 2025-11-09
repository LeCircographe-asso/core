#!/usr/bin/env ruby
# Script d'analyse complète de l'application Le Circographe
# Usage: ruby scripts/app_analysis.rb

require 'fileutils'
require 'json'
require 'time'

class AppAnalyzer
  def initialize
    @app_root = File.expand_path('..', __dir__)
    @results = {
      timestamp: Time.now.iso8601,
      components: {},
      models: {},
      controllers: {},
      services: {},
      helpers: {},
      views: {},
      routes: {},
      unused_files: [],
      recommendations: []
    }

    puts "🔍 Analyse de l'application Le Circographe"
    puts "📁 Répertoire: #{@app_root}"
    puts "=" * 60
  end

  def analyze_all
    analyze_components
    analyze_models
    analyze_controllers
    analyze_services
    analyze_helpers
    analyze_views
    analyze_routes
    find_unused_files
    generate_recommendations
    generate_report
  end

  private

  def analyze_components
    puts "\n🎨 Analyse des composants ViewComponent..."

    components_dir = File.join(@app_root, 'app', 'components')
    return unless Dir.exist?(components_dir)

    Dir.glob("#{components_dir}/**/*_component.rb").each do |file|
      component_name = File.basename(file, '_component.rb')
      component_path = file.gsub("#{@app_root}/", "")

      # Analyser le fichier du composant
      component_info = analyze_component_file(file)

      # Vérifier l'utilisation
      usage = find_component_usage(component_name)

      @results[:components][component_name] = {
        file: component_path,
        class_name: component_info[:class_name],
        methods: component_info[:methods],
        used_in_views: usage[:views],
        used_in_controllers: usage[:controllers],
        used_in_helpers: usage[:helpers],
        used_in_tests: usage[:tests],
        usage_count: usage[:total_count],
        is_used: usage[:total_count] > 0,
        has_template: File.exist?(file.gsub('.rb', '.html.erb'))
      }
    end
  end

  def analyze_component_file(file)
    content = File.read(file)

    {
      class_name: extract_class_name(content),
      methods: extract_methods(content)
    }
  end

  def extract_class_name(content)
    match = content.match(/class\s+(\w+Component)/)
    match ? match[1] : nil
  end

  def extract_methods(content)
    methods = []
    content.scan(/def\s+(\w+)/) do |match|
      methods << match[0] unless match[0].start_with?('_')
    end
    methods
  end

  def find_component_usage(component_name)
    usage = {
      views: [],
      controllers: [],
      helpers: [],
      tests: [],
      total_count: 0
    }

    # Recherche dans les vues
    Dir.glob("#{@app_root}/app/views/**/*.erb").each do |file|
      content = File.read(file)
      if content.include?(component_name) || content.include?(component_name.split('_').map(&:capitalize).join)
        usage[:views] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les contrôleurs
    Dir.glob("#{@app_root}/app/controllers/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(component_name) || content.include?(component_name.split('_').map(&:capitalize).join)
        usage[:controllers] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les helpers
    Dir.glob("#{@app_root}/app/helpers/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(component_name) || content.include?(component_name.split('_').map(&:capitalize).join)
        usage[:helpers] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les tests
    Dir.glob("#{@app_root}/spec/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(component_name) || content.include?(component_name.split('_').map(&:capitalize).join)
        usage[:tests] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    usage
  end

  def analyze_models
    puts "\n📊 Analyse des modèles..."

    models_dir = File.join(@app_root, 'app', 'models')
    return unless Dir.exist?(models_dir)

    Dir.glob("#{models_dir}/*.rb").each do |file|
      next if File.basename(file) == 'application_record.rb'

      model_name = File.basename(file, '.rb')
      model_path = file.gsub("#{@app_root}/", "")

      model_info = analyze_model_file(file)
      usage = find_model_usage(model_name)

      @results[:models][model_name] = {
        file: model_path,
        class_name: model_info[:class_name],
        associations: model_info[:associations],
        validations: model_info[:validations],
        methods: model_info[:methods],
        scopes: model_info[:scopes],
        used_in_controllers: usage[:controllers],
        used_in_services: usage[:services],
        used_in_helpers: usage[:helpers],
        used_in_views: usage[:views],
        usage_count: usage[:total_count],
        is_used: usage[:total_count] > 0
      }
    end
  end

  def analyze_model_file(file)
    content = File.read(file)

    {
      class_name: extract_class_name(content),
      associations: extract_associations(content),
      validations: extract_validations(content),
      methods: extract_methods(content),
      scopes: extract_scopes(content)
    }
  end

  def extract_associations(content)
    associations = []
    content.scan(/(belongs_to|has_many|has_one|has_and_belongs_to_many)\s+:(\w+)/) do |type, name|
      associations << { type: type, name: name }
    end
    associations
  end

  def extract_validations(content)
    validations = []
    content.scan(/validates\s+:(\w+)/) do |match|
      validations << match[0]
    end
    validations
  end

  def extract_scopes(content)
    scopes = []
    content.scan(/scope\s+:(\w+)/) do |match|
      scopes << match[0]
    end
    scopes
  end

  def find_model_usage(model_name)
    usage = {
      controllers: [],
      services: [],
      helpers: [],
      views: [],
      total_count: 0
    }

    # Recherche dans les contrôleurs
    Dir.glob("#{@app_root}/app/controllers/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(model_name) || content.include?(model_name.split('_').map(&:capitalize).join)
        usage[:controllers] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les services
    Dir.glob("#{@app_root}/app/services/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(model_name) || content.include?(model_name.split('_').map(&:capitalize).join)
        usage[:services] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les helpers
    Dir.glob("#{@app_root}/app/helpers/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(model_name) || content.include?(model_name.split('_').map(&:capitalize).join)
        usage[:helpers] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les vues
    Dir.glob("#{@app_root}/app/views/**/*.erb").each do |file|
      content = File.read(file)
      if content.include?(model_name) || content.include?(model_name.split('_').map(&:capitalize).join)
        usage[:views] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    usage
  end

  def analyze_controllers
    puts "\n🎮 Analyse des contrôleurs..."

    controllers_dir = File.join(@app_root, 'app', 'controllers')
    return unless Dir.exist?(controllers_dir)

    Dir.glob("#{controllers_dir}/**/*_controller.rb").each do |file|
      next if File.basename(file) == 'application_controller.rb'

      controller_name = File.basename(file, '_controller.rb')
      controller_path = file.gsub("#{@app_root}/", "")

      controller_info = analyze_controller_file(file)
      usage = find_controller_usage(controller_name)

      @results[:controllers][controller_name] = {
        file: controller_path,
        class_name: controller_info[:class_name],
        actions: controller_info[:actions],
        before_actions: controller_info[:before_actions],
        private_methods: controller_info[:private_methods],
        has_views: usage[:has_views],
        view_files: usage[:view_files],
        is_used: usage[:has_views] || controller_info[:actions].any?
      }
    end
  end

  def analyze_controller_file(file)
    content = File.read(file)

    {
      class_name: extract_class_name(content),
      actions: extract_actions(content),
      before_actions: extract_before_actions(content),
      private_methods: extract_private_methods(content)
    }
  end

  def extract_actions(content)
    actions = []
    content.scan(/def\s+(\w+)/) do |match|
      action = match[0]
      actions << action unless action.start_with?('_') || action == 'initialize'
    end
    actions
  end

  def extract_before_actions(content)
    before_actions = []
    content.scan(/before_action\s+:(\w+)/) do |match|
      before_actions << match[0]
    end
    before_actions
  end

  def extract_private_methods(content)
    private_methods = []
    in_private = false

    content.lines.each do |line|
      if line.strip == 'private'
        in_private = true
        next
      elsif line.strip == 'end' && in_private
        in_private = false
        next
      end

      if in_private && line.match(/def\s+(\w+)/)
        private_methods << $1
      end
    end

    private_methods
  end

  def find_controller_usage(controller_name)
    views_dir = File.join(@app_root, 'app', 'views', controller_name)
    has_views = Dir.exist?(views_dir)

    view_files = []
    if has_views
      view_files = Dir.glob("#{views_dir}/*.erb").map { |f| f.gsub("#{@app_root}/", "") }
    end

    {
      has_views: has_views,
      view_files: view_files
    }
  end

  def analyze_services
    puts "\n⚙️ Analyse des services..."

    services_dir = File.join(@app_root, 'app', 'services')
    return unless Dir.exist?(services_dir)

    Dir.glob("#{services_dir}/**/*.rb").each do |file|
      service_name = File.basename(file, '.rb')
      service_path = file.gsub("#{@app_root}/", "")

      service_info = analyze_service_file(file)
      usage = find_service_usage(service_name)

      @results[:services][service_name] = {
        file: service_path,
        class_name: service_info[:class_name],
        methods: service_info[:methods],
        used_in_controllers: usage[:controllers],
        used_in_other_services: usage[:services],
        used_in_jobs: usage[:jobs],
        usage_count: usage[:total_count],
        is_used: usage[:total_count] > 0
      }
    end
  end

  def analyze_service_file(file)
    content = File.read(file)

    {
      class_name: extract_class_name(content),
      methods: extract_methods(content)
    }
  end

  def find_service_usage(service_name)
    usage = {
      controllers: [],
      services: [],
      jobs: [],
      total_count: 0
    }

    # Recherche dans les contrôleurs
    Dir.glob("#{@app_root}/app/controllers/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(service_name) || content.include?(service_name.split('_').map(&:capitalize).join)
        usage[:controllers] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les autres services
    Dir.glob("#{@app_root}/app/services/**/*.rb").each do |file|
      next if file.include?(service_name)
      content = File.read(file)
      if content.include?(service_name) || content.include?(service_name.split('_').map(&:capitalize).join)
        usage[:services] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les jobs
    Dir.glob("#{@app_root}/app/jobs/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(service_name) || content.include?(service_name.split('_').map(&:capitalize).join)
        usage[:jobs] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    usage
  end

  def analyze_helpers
    puts "\n🛠️ Analyse des helpers..."

    helpers_dir = File.join(@app_root, 'app', 'helpers')
    return unless Dir.exist?(helpers_dir)

    Dir.glob("#{helpers_dir}/**/*.rb").each do |file|
      next if File.basename(file) == 'application_helper.rb'

      helper_name = File.basename(file, '_helper.rb')
      helper_path = file.gsub("#{@app_root}/", "")

      helper_info = analyze_helper_file(file)
      usage = find_helper_usage(helper_name)

      @results[:helpers][helper_name] = {
        file: helper_path,
        class_name: helper_info[:class_name],
        methods: helper_info[:methods],
        used_in_views: usage[:views],
        used_in_controllers: usage[:controllers],
        usage_count: usage[:total_count],
        is_used: usage[:total_count] > 0
      }
    end
  end

  def analyze_helper_file(file)
    content = File.read(file)

    {
      class_name: extract_class_name(content),
      methods: extract_methods(content)
    }
  end

  def find_helper_usage(helper_name)
    usage = {
      views: [],
      controllers: [],
      total_count: 0
    }

    # Recherche dans les vues
    Dir.glob("#{@app_root}/app/views/**/*.erb").each do |file|
      content = File.read(file)
      if content.include?(helper_name) || content.include?(helper_name.split('_').map(&:capitalize).join)
        usage[:views] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    # Recherche dans les contrôleurs
    Dir.glob("#{@app_root}/app/controllers/**/*.rb").each do |file|
      content = File.read(file)
      if content.include?(helper_name) || content.include?(helper_name.split('_').map(&:capitalize).join)
        usage[:controllers] << file.gsub("#{@app_root}/", "")
        usage[:total_count] += 1
      end
    end

    usage
  end

  def analyze_views
    puts "\n👁️ Analyse des vues..."

    views_dir = File.join(@app_root, 'app', 'views')
    return unless Dir.exist?(views_dir)

    Dir.glob("#{views_dir}/**/*.erb").each do |file|
      view_name = File.basename(file, '.erb')
      view_path = file.gsub("#{@app_root}/", "")

      view_info = analyze_view_file(file)

      @results[:views][view_path] = {
        file: view_path,
        partial: view_name.start_with?('_'),
        uses_components: view_info[:components],
        uses_helpers: view_info[:helpers],
        size: File.size(file)
      }
    end
  end

  def analyze_view_file(file)
    content = File.read(file)

    {
      components: extract_view_components(content),
      helpers: extract_view_helpers(content)
    }
  end

  def extract_view_components(content)
    components = []
    content.scan(/render\s+['"]([^'"]*_component)['"]/) do |match|
      components << match[0]
    end
    components
  end

  def extract_view_helpers(content)
    helpers = []
    content.scan(/(\w+_path|\w+_url|\w+_helper)/) do |match|
      helpers << match[0]
    end
    helpers.uniq
  end

  def analyze_routes
    puts "\n🛣️ Analyse des routes..."

    routes_file = File.join(@app_root, 'config', 'routes.rb')
    return unless File.exist?(routes_file)

    content = File.read(routes_file)
    routes_info = extract_routes(content)

    @results[:routes] = {
      file: 'config/routes.rb',
      total_routes: routes_info[:total_routes],
      namespaced_routes: routes_info[:namespaced_routes],
      resource_routes: routes_info[:resource_routes],
      custom_routes: routes_info[:custom_routes]
    }
  end

  def extract_routes(content)
    {
      total_routes: content.scan(/get|post|put|patch|delete/).count,
      namespaced_routes: content.scan(/namespace\s+:(\w+)/).flatten,
      resource_routes: content.scan(/resources\s+:(\w+)/).flatten,
      custom_routes: content.scan(/get\s+['"]([^'"]+)['"]/).flatten
    }
  end

  def find_unused_files
    puts "\n🗑️ Recherche des fichiers non utilisés..."

    # Composants non utilisés
    @results[:components].each do |name, info|
      unless info[:is_used]
        @results[:unused_files] << {
          type: 'component',
          name: name,
          file: info[:file],
          reason: 'Composant non utilisé dans l\'application'
        }
      end
    end

    # Services non utilisés
    @results[:services].each do |name, info|
      unless info[:is_used]
        @results[:unused_files] << {
          type: 'service',
          name: name,
          file: info[:file],
          reason: 'Service non utilisé dans l\'application'
        }
      end
    end

    # Helpers non utilisés
    @results[:helpers].each do |name, info|
      unless info[:is_used]
        @results[:unused_files] << {
          type: 'helper',
          name: name,
          file: info[:file],
          reason: 'Helper non utilisé dans l\'application'
        }
      end
    end
  end

  def generate_recommendations
    puts "\n💡 Génération des recommandations..."

    # Composants non utilisés
    unused_components = @results[:components].select { |_, info| !info[:is_used] }
    if unused_components.any?
      @results[:recommendations] << {
        type: 'cleanup',
        priority: 'medium',
        title: 'Supprimer les composants non utilisés',
        description: "#{unused_components.count} composants ne sont pas utilisés",
        files: unused_components.keys,
        action: 'delete'
      }
    end

    # Services non utilisés
    unused_services = @results[:services].select { |_, info| !info[:is_used] }
    if unused_services.any?
      @results[:recommendations] << {
        type: 'cleanup',
        priority: 'high',
        title: 'Supprimer les services non utilisés',
        description: "#{unused_services.count} services ne sont pas utilisés",
        files: unused_services.keys,
        action: 'delete'
      }
    end

    # Contrôleurs sans vues
    controllers_without_views = @results[:controllers].select { |_, info| !info[:has_views] }
    if controllers_without_views.any?
      @results[:recommendations] << {
        type: 'review',
        priority: 'medium',
        title: 'Vérifier les contrôleurs sans vues',
        description: "#{controllers_without_views.count} contrôleurs n\'ont pas de vues associées",
        files: controllers_without_views.keys,
        action: 'review'
      }
    end
  end

  def generate_report
    puts "\n📊 Génération du rapport..."

    # Rapport JSON
    json_file = File.join(@app_root, 'app_analysis_report.json')
    File.write(json_file, JSON.pretty_generate(@results))

    # Rapport texte
    text_file = File.join(@app_root, 'app_analysis_report.txt')
    generate_text_report(text_file)

    puts "\n✅ Analyse terminée !"
    puts "📄 Rapport JSON: #{json_file}"
    puts "📄 Rapport texte: #{text_file}"

    # Afficher un résumé
    display_summary
  end

  def generate_text_report(file)
    File.open(file, 'w') do |f|
      f.puts "RAPPORT D'ANALYSE - LE CIRCOGRAPHE"
      f.puts "=" * 50
      f.puts "Date: #{@results[:timestamp]}"
      f.puts

      # Résumé
      f.puts "RÉSUMÉ"
      f.puts "-" * 20
      f.puts "Composants: #{@results[:components].count} (#{@results[:components].count { |_, info| info[:is_used] }} utilisés)"
      f.puts "Modèles: #{@results[:models].count} (#{@results[:models].count { |_, info| info[:is_used] }} utilisés)"
      f.puts "Contrôleurs: #{@results[:controllers].count} (#{@results[:controllers].count { |_, info| info[:has_views] }} avec vues)"
      f.puts "Services: #{@results[:services].count} (#{@results[:services].count { |_, info| info[:is_used] }} utilisés)"
      f.puts "Helpers: #{@results[:helpers].count} (#{@results[:helpers].count { |_, info| info[:is_used] }} utilisés)"
      f.puts "Vues: #{@results[:views].count}"
      f.puts "Fichiers non utilisés: #{@results[:unused_files].count}"
      f.puts

      # Composants non utilisés
      unused_components = @results[:components].select { |_, info| !info[:is_used] }
      if unused_components.any?
        f.puts "COMPOSANTS NON UTILISÉS"
        f.puts "-" * 30
        unused_components.each do |name, info|
          f.puts "❌ #{name} (#{info[:file]})"
        end
        f.puts
      end

      # Services non utilisés
      unused_services = @results[:services].select { |_, info| !info[:is_used] }
      if unused_services.any?
        f.puts "SERVICES NON UTILISÉS"
        f.puts "-" * 25
        unused_services.each do |name, info|
          f.puts "❌ #{name} (#{info[:file]})"
        end
        f.puts
      end

      # Recommandations
      if @results[:recommendations].any?
        f.puts "RECOMMANDATIONS"
        f.puts "-" * 20
        @results[:recommendations].each_with_index do |rec, index|
          f.puts "#{index + 1}. [#{rec[:priority].upcase}] #{rec[:title]}"
          f.puts "   #{rec[:description]}"
          f.puts "   Action: #{rec[:action]}"
          f.puts
        end
      end
    end
  end

  def display_summary
    puts "\n📈 RÉSUMÉ DE L'ANALYSE"
    puts "=" * 40

    total_components = @results[:components].count
    used_components = @results[:components].count { |_, info| info[:is_used] }

    total_services = @results[:services].count
    used_services = @results[:services].count { |_, info| info[:is_used] }

    total_helpers = @results[:helpers].count
    used_helpers = @results[:helpers].count { |_, info| info[:is_used] }

    puts "🎨 Composants: #{used_components}/#{total_components} utilisés"
    puts "📊 Modèles: #{@results[:models].count}"
    puts "🎮 Contrôleurs: #{@results[:controllers].count}"
    puts "⚙️ Services: #{used_services}/#{total_services} utilisés"
    puts "🛠️ Helpers: #{used_helpers}/#{total_helpers} utilisés"
    puts "👁️ Vues: #{@results[:views].count}"
    puts "🗑️ Fichiers non utilisés: #{@results[:unused_files].count}"

    if @results[:unused_files].any?
      puts "\n⚠️ FICHIERS À SUPPRIMER:"
      @results[:unused_files].each do |file|
        puts "   ❌ #{file[:name]} (#{file[:file]})"
      end
    end
  end
end

# Exécution du script
if __FILE__ == $0
  analyzer = AppAnalyzer.new
  analyzer.analyze_all
end
