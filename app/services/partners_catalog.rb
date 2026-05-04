# frozen_string_literal: true

class PartnersCatalog
  Partner = Struct.new(:name, :description, :link, :logo, keyword_init: true)

  def self.public_partners
    [
      Partner.new(name: "Ville de Toulouse", description: "Soutien institutionnel & logistique", link: "https://www.toulouse.fr"),
      Partner.new(name: "L'Usine", description: "Compagnonnage cirque contemporain", link: "https://www.usine-c.com"),
      Partner.new(name: "École de cirque Pop", description: "Partage de savoir-faire pédagogique", link: "https://www.ecoledecirquepop.fr"),
      Partner.new(name: "Atelier Graphein", description: "Temps d’accueil en création graphiques & expositions", link: "https://ateliergraphein.fr")
    ]
  end
end
