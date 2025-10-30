# Configuration pour ViewComponent
Rails.application.configure do
  # Configuration ViewComponent
  config.view_component.view_component_path = "app/components"
  
  # Forcer l'autoloading des components
  config.autoload_paths += %W(#{config.root}/app/components)
  config.eager_load_paths += %W(#{config.root}/app/components)
end
