# Vérifie que l'initializer est chargé
Rails.logger.info "Loading Pagy configuration..."

# Configuration de base
require 'pagy'

# Extras utiles
require 'pagy/extras/bootstrap'  # Pour le style Bootstrap
require 'pagy/extras/overflow'   # Pour gérer le dépassement de pages

# Configuration par défaut
Pagy::DEFAULT.merge!(
  # Nombre d'items par page
  items: 20,
  
  # Nombre de liens de pagination à afficher
  nav_items: 7,
  
  # Comportement en cas de dépassement
  overflow: :last_page,
  
  # Textes des boutons (en français)
  i18n_key: 'pagy.item_name',
  
  # Labels des boutons
  label_prev: '&lsaquo;&nbsp;Précédent',
  label_next: 'Suivant&nbsp;&rsaquo;',
  
  # Taille des métadonnées
  metadata: [:page, :count, :last_page]
)

Rails.logger.info "Pagy configuration loaded successfully!" 