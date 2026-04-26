class FaqRepository
  CONFIG_PATH = Rails.root.join("config/content/faq.yml")
  CACHE_KEY = "faq:content:v1"

  class << self
    def load
      data = Rails.env.development? ? read_yaml : Rails.cache.fetch(CACHE_KEY) { read_yaml }

      {
        hero: data.fetch("hero", "").to_s,
        cta_label: (data["cta_label"].presence || "Contacter l’équipe"),
        entries: Array.wrap(data["entries"]).map { normalize_entry(_1) }
      }
    end

    private

    def read_yaml
      YAML.safe_load_file(CONFIG_PATH, permitted_classes: [], aliases: false) || {}
    rescue Errno::ENOENT
      {}
    end

    def normalize_entry(entry)
      {
        question: entry.fetch("question", "").to_s,
        answer: entry.fetch("answer", "").to_s
      }
    end
  end
end
