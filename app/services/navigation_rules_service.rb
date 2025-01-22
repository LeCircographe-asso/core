class NavigationRulesService
  def self.load_rules
    YAML.load_file(Rails.root.join('.navigation_rules'))
  end

  def self.allowed_paths_for(role)
    rules = load_rules
    rules.dig('roles', role.to_s, 'paths') || []
  end

  def self.default_path_for(role)
    rules = load_rules
    rules.dig('roles', role.to_s, 'default') || '/'
  end

  def self.has_permission?(user, action)
    rules = load_rules
    allowed_roles = rules.dig('permissions', action.to_s) || []
    allowed_roles.include?(user.role)
  end
end 