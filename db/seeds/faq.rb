Faq.destroy_all

contact_url = "/contact#contact-form"
become_member_url = "/adhesion#tarifs"
map_url = "/contact#map"

faq_data = [
  # AVANT VISITE — section "Avant de te déplacer" sur /adhesion
  { label: "avant_visite", position: 1, question: "Comment adhérer ?",
    answer: "Sur place, lors d'un créneau d'accueil : visite du lieu, fiche d'adhésion et explication de l'autogestion. Pas d'inscription en ligne — on fait ça ensemble au lieu pour que chacun·e parte avec les mêmes repères." },
  { label: "avant_visite", position: 2, question: "Paiement adhésion ou cotisation",
    answer: "Carte bancaire ou espèces à l'accueil, avec les bénévoles." },
  { label: "avant_visite", position: 3, question: "Je débute : les entraînements libres me concernent ?",
    answer: "Les créneaux libres cirque sont pour des pratiquant·es autonomes en sécurité. Pour apprendre les bases, une école partenaire ; pour une orientation, <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">écris-nous</a> en Question générale." },
  # ADHESION — onglet "Adhérer & pratiquer" sur /faq
  { label: "adhesion", position: 1, question: "Adhésion visiteur ou adhésion cirque : quelle différence ?",
    answer: "L'adhésion visiteur (don libre dès 1 €) donne accès aux temps ouverts sans pratique. L'adhésion cirque (10 €, tarif réduit 7 €) est nécessaire pour les entraînements libres — elle s'accompagne d'une cotisation à choisir selon ta pratique." },
  { label: "adhesion", position: 2, question: "Durée de l'adhésion",
    answer: "L'adhésion est annuelle, date à date à partir du jour de ta venue. La cotisation cirque (séance, carnet, trimestre ou annuelle) s'y ajoute selon tes besoins." },
  { label: "adhesion", position: 3, question: "Tarif réduit ou solidaire",
    answer: "Un tarif réduit à 7 € existe pour l'adhésion cirque. Parles-en directement aux bénévoles lors de ton accueil — on trouve toujours une solution." },
  # GENERAL — onglet "Lieu & horaires" sur /faq
  { label: "general", position: 1, question: "Adresse et accès",
    answer: "97 bis boulevard de Suisse, 31200 Toulouse. <a href=\"#{map_url}\" class=\"text-[#5836A5] underline\">Plan et bus (ligne 15)</a>." },
  { label: "general", position: 2, question: "Horaires",
    answer: "Les créneaux publics bougent selon la saison et les bénévoles. À jour sur l'accueil, la page Adhérer et la page Contact — jette un œil avant de venir." },
  { label: "general", position: 3, question: "Soutenir le lieu ou une question administrative",
    answer: "Adhérer, cotisation, don : <a href=\"#{become_member_url}\" class=\"text-[#5836A5] underline\">page Adhérer</a>. Pour un partenariat, un don hors cadre ou une demande administrative : <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">formulaire Contact</a> (Question générale ou Partenariat)." },
  # CONTACT — onglet "Écrire & proposer" sur /faq
  { label: "contact", position: 1, question: "Demander un temps d'accueil en création",
    answer: "Écris-nous avec le <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">formulaire Contact</a>, catégorie « Temps d'accueil en création » — on te répond sur les dispo et le cadre." },
  { label: "contact", position: 2, question: "Partenariat, atelier, événement ou projet avec le lieu",
    answer: "Le plus simple : passer lors d'un créneau d'ouverture avec ton idée. Tu peux aussi utiliser le <a href=\"#{contact_url}\" class=\"text-[#5836A5] underline\">formulaire Contact</a> (Partenariat ou Question générale). Les bénévoles t'orientent." }
]

faq_data.each { |attrs| Faq.create!(attrs) }
puts "  #{Faq.count} entrées FAQ créées (avant_visite: #{Faq.by_label('avant_visite').count}, adhesion: #{Faq.by_label('adhesion').count}, general: #{Faq.by_label('general').count}, contact: #{Faq.by_label('contact').count})"
