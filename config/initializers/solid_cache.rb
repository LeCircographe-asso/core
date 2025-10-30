# Configure SolidCache to use SQLite database
Rails.application.config.to_prepare do
  # SolidCache configuration
  Rails.application.config.solid_cache.expires_in = 1.day
  Rails.application.config.solid_cache.connects_to = { database: { writing: :cache } }
  Rails.application.config.solid_cache.max_entries = 10000
  Rails.application.config.solid_cache.memory_cache_size = 64000
  Rails.application.config.solid_cache.compress_threshold = 1.kilobyte
end
