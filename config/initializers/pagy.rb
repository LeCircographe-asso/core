require "pagy"
require "pagy/extras/bootstrap"
require "pagy/extras/items"
require "pagy/extras/overflow"

# Configuration Pagy
Pagy::DEFAULT[:items] = 25  # 25 items par page par défaut
Pagy::DEFAULT[:size] = [ 1, 4, 4, 1 ]  # Navigation: prev, pages, next, last
Pagy::DEFAULT[:overflow] = :last_page  # Gérer les pages hors limites
Pagy::DEFAULT[:page_param] = :page  # Paramètre de page dans l'URL

# Configuration pour Tailwind CSS
Pagy::DEFAULT[:nav_css] = "relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
Pagy::DEFAULT[:nav_link_class] = "relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
Pagy::DEFAULT[:nav_active_class] = "z-10 bg-indigo-50 border-indigo-500 text-indigo-600"
