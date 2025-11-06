# 🧭 Refonte UX / UI et dynamique JS — **Le Circographe**
*(Document de travail — 2025-11-06)*

---

## 🎯 Objectif global
Créer une expérience utilisateur fluide et vivante pour le site du **Circographe**, en respectant :
- Le design system et les atoms existants
- Le ton associatif et humain du projet
- Le modèle d’autogestion et d’adhésion sur place
- Les contraintes techniques : **Rails 8 + Hotwire / Stimulus**

---

## 🔧 Technologies actuelles disponibles

- **Stimulus controllers** : `accordion_controller` (accordéons Flowbite), `flash_controller` (feedback auto-dismiss), `home_animations` (animations page d’accueil), `global_animations` (IntersectionObserver fade-in), contrôleurs métiers admin (`payment_modal`, `reduced_rate`, etc.) exploitables en source d’inspiration.
- **Initialisation JS** : importmap avec `@hotwired/turbo-rails`, `stimulus-loading`, `Flowbite` via `window.initFlowbite`, modules maison `home_animations.js`, `global_animations.js` chargés sur chaque page.
- **Librairies UI** : Tailwind CSS (via `tailwindcss-rails`), Flowbite (accordéons, dropdown), Swiper (carrousels événements et galerie), SweetAlert2 et Stripe (sessions de paiement, côté admin/public).
- **Partials et composants réutilisables** : `shared/navbar`, `shared/footer`, `shared/opening_hours`, `shared/event_card`, `shared/event_carousel`, cartes `shared/card` & `shared/card_reverse`, blocs newsletter et FAQ.
- **Mise en page** : layout `application.html.erb` avec header sticky, flash zones, arrière-plan parallax configurable, classes utilitaires `fade-in` + observers.
- **Données** : modèles `Event`, `Person`, helpers `OpeningHoursHelper`, caches `Rails.cache` utilisés sur l’accueil, requêtes dédiées (`PersonQuery`) pour enrichir les pages si besoin.
- **Flux Hotwire** : Turbo Drive activé, Turbo Frames non encore systématisés sur les pages publiques, mais endpoint prêt (`form_with` + actions `events#index/show`).
- **Accessibilité & préférences** : classe `dyslexic-font-enabled` appliquée via `current_user`, à conserver dans le nouveau parcours.

Ce document compile :
1. La **nouvelle structure de navigation**
2. Le **parcours utilisateur complet**
3. Les **interactions JS dynamiques** recommandées
4. Les **optimisations techniques** compatibles Rails 8

---

## 🧩 Architecture UX/UI Globale

### Niveau 0 — Navigation principale

- Header fixe minimaliste  
- Liens : `Logo | Le Lieu | Nos Activités | Adhérer | À propos | Contact | S’inscrire`
- Sticky header + highlight dynamique du lien actif

**Interactions :**
- Stimulus `nav-active`
- Turbo Drive pour transitions de pages fluides (fade)
- Smooth scroll pour ancres internes
- Menu desktop/mobile déjà basé sur `shared/navbar` + Flowbite (`data-collapse-toggle`, dropdowns) ; conserver la structure et brancher `nav-active` pour synchroniser l’état actif via `turbo:load`.
- Penser à encapsuler les dropdowns et CTA secondaires dans des `turbo_frame_tag` pour pouvoir rafraîchir les états (par ex. affichage connecté/déconnecté) sans recharger la page complète.
- Le layout `application.html.erb` gère déjà l’arrière-plan parallax et l’injection de flash ; utiliser Turbo Streams pour diffuser les flash plutôt que recharger la page après actions publiques.

### Lignes directrices Hotwire globales

- Activer les transitions de page via Turbo Drive + CSS `fade` en s’appuyant sur `application.css` (classes `fade-in`) et le hook `global_animations` ; prévoir un léger `setTimeout` pour éviter les flashes lors d’un `turbo:before-cache`.
- Normaliser l’usage de `turbo_frame_tag` pour les modals, formulaires AJAX (newsletter, contact), et sections filtrées afin de tirer parti des Turbo Streams sans rechargement global.
- Centraliser les scripts Swiper dans un futur `slider_controller` Stimulus qui instancie/détruit le carrousel sur `turbo:load` et `turbo:before-cache`.
- Réutiliser `window.initFlowbite()` côté `turbo:load` et ajouter un guard `turbo:before-cache` pour nettoyer les états ouverts (accordéons, dropdowns) avant navigation.
- Surveiller `log/development.log` après chaque refactor pour vérifier les temps de réponse et éviter les requêtes N+1 provoquées par les nouvelles sections.

---

## 🏠 1. Accueil (Landing)

**Objectif :** immersion rapide + CTA principal vers *Le Lieu*

- Hero (titre, sous-titre, CTA)
- Événements à venir (cards dynamiques)
- Horaires (partial partagé)
- Carte Google Maps intégrée

**JS / Stimulus :**
- `reveal_controller` pour apparitions progressives
- `infinite_scroll_controller` pour chargement d’événements
- `scroll_hint_controller` pour l’animation du “scroll down”

**Technologies actuelles :**
- Vue `home/index.html.erb` avec animation `home_animations.js`, classes utilitaires `opacity-0` + `fade-in` reliées à `global_animations.js`.
- Partials existants : `shared/event_card` (affiche le dernier événement), `shared/opening_hours` (horaires cache) et iframe Google Maps.
- Données `Event` déjà accessibles (controller `EventsController#index`/`show`), caches horaires via `OpeningHoursHelper`.

**Actions Hotwire / Stimulus proposées :**
- Étendre `home_animations` pour gérer les effets reveal des sections supplémentaires (événements, horaires, CTA) via `IntersectionObserver`, en assurant le nettoyage `turbo:before-cache`.
- Envelopper la liste d’événements à venir dans un `turbo_frame_tag` (ex. `id="events_upcoming"`) alimenté par un endpoint `EventsController#upcoming` pour rafraîchir sans rechargement global.
- Ajouter un `scroll_hint_controller` léger pour l’indicateur “scroll down”, en se basant sur les mêmes classes que `home_animations` (éviter scripts dupliqués).

---

## 🎪 2. Le Lieu

**Objectif :** présenter le lieu, ses pôles, et le fonctionnement autogéré

### Structure :
1. Hero — “Bienvenue au Circographe”  
2. Le Cirque — Card + Modal / Accordéon  
3. Les Arts Graphiques — idem  
4. Fonctionnement — 3 cards (Auto-gestion / Bénévolat / Adhésion sur place)  
5. Galerie (carousel horizontal)  
6. CTA final — “Passer nous voir”

**JS / Stimulus :**
- `accordion_controller`
- `modal_controller`
- `reveal_controller`
- `slider_controller` (wrapper Glide.js ou Splide.js)

**Technologies actuelles :**
- Pages `pages/association`, `pages/circus_details`, `pages/graphic_arts_details` utilisant les partials `shared/card` et `shared/card_reverse` avec classes Tailwind déjà conformes au design.
- Accordéons Flowbite disponibles côté mobile (`shared/navbar`) et `accordion_controller` prêt à l’emploi.
- Carrousels Swiper existants dans `shared/event_carousel` (JS inline) qui peuvent servir de base pour une galerie.

**Actions Hotwire / Stimulus proposées :**
- Factoriser les sections en partials (`shared/place_section`, `shared/gallery_slider`) pour hydrater les pages Le Lieu / Cirque / Arts Graphiques avec le même contenu, tout en conservant la charte existante.
- Créer un `modal_controller` Stimulus qui s’appuie sur Flowbite (ou Turbo Frames) pour présenter les détails des pôles sans recharger la page ; prévoir des `turbo_frame_tag` ciblant les contenus.
- Remplacer l’initialisation Swiper inline par un futur `slider_controller` commun, gérant l’instance côté `turbo:load` et `turbo:before-cache`.

---

## 🗓️ 3. Nos Activités

**Objectif :** regrouper événements + actualités + newsletter dans une interface dynamique

### Structure :
- Filtres dynamiques (`Tous | À venir | Passés | Actus`)
- Grid d’événements (lazy load)
- Modals de détails (Turbo Frame)
- Bloc newsletter (AJAX)

**JS / Stimulus :**
- `tabs_controller`
- `infinite_scroll_controller`
- `modal_controller`
- `form_feedback_controller`

**Technologies actuelles :**
- Templates `pages/news`, `events/index`, `shared/event_card`, `shared/event_carousel` s’appuyant sur Swiper + Tailwind pour les grilles et CTA.
- Modèle `Event` avec scopes `upcoming`, `past`, `by_date`; `EventsController#index/show` déjà exposés côté public.
- Formulaire newsletter `form_with` (POST `newsletter_signup_path`) et `flash_controller` pour afficher des retours utilisateur.

**Actions Hotwire / Stimulus proposées :**
- Introduire un `tabs_controller` qui filtre via Turbo Frames (ex. `turbo_frame_tag :events_tab`) et Streams alimentés par de nouveaux endpoints `EventsController#upcoming` / `#past` pour éviter des rechargements complets.
- Déporter l’initialisation Swiper dans le `slider_controller` commun, et gérer la destruction dans `turbo:before-cache` pour prévenir les duplications.
- Passer le formulaire newsletter en mode Turbo (`form_with data: { turbo_stream: true }`) et diffuser un Turbo Stream de succès/erreur vers la zone `flash` existante.

---

## 🤝 4. Adhérer

**Objectif :** clarifier le processus d’adhésion sur place

### Structure :
1. Hero — “Adhérer au Circographe”  
2. Pourquoi adhérer — 3 cards Metro  
3. Comment ça marche — Timeline (3 étapes)  
4. Tarifs & types d’adhésion — 2 cards + accordéon  
5. Documents requis — checklist interactive  
6. Horaires + carte Google  
7. CTA final — “Passer nous voir”

**JS / Stimulus :**
- `timeline_controller`
- `accordion_controller`
- `checklist_controller`
- `scroll_controller` (smooth anchor)
- `reveal_controller`

**Technologies actuelles :**
- Template `pages/become_member` avec grilles Tailwind, icônes SVG, sections déjà structurées (avantages, adhésions, cotisations, résidences) et classes `fade-in`.
- Accordéons Flowbite disponibles (mobile) et `accordion_controller` déjà en production (`pages/faq`).
- Composants admin `reduced_rate`, `editable_member_number` pouvant inspirer la logique checklist/timeline.

**Actions Hotwire / Stimulus proposées :**
- Créer un `timeline_controller` qui révèle les étapes au scroll en réutilisant `global_animations` pour l’observer, avec fallback `prefers-reduced-motion` similaire à `home_animations`.
- Implémenter un `checklist_controller` simple qui coche/décoche les items requis et peut émettre un Turbo Stream lorsque l’utilisateur marque une tâche comme faite (synchronisation éventuelle avec le compte connecté via future API).
- Utiliser un `turbo_frame_tag` pour afficher dynamiquement les tarifs / types d’adhésions depuis une source (ex. `MembershipType`), afin d’éviter de dupliquer du contenu statique.

---

## 🧑‍🎨 5. À propos

**Objectif :** humaniser le projet, présenter l’équipe et les valeurs

### Structure :
- Mission & valeurs
- Équipe (slider horizontal)
- Historique (timeline verticale)
- Partenaires / Presse

**JS / Stimulus :**
- `slider_controller`
- `reveal_controller`
- `timeline_controller`

**Technologies actuelles :**
- Pages `pages/about`, `pages/gallery`, `pages/blog_newsletter` offrant déjà des grilles visuelles, sliders Swiper et sections textes.
- Composants `shared/event_carousel` et carrousel galerie (JS inline) réutilisables pour l’équipe/partenaires.
- Animation `fade-in` + `global_animations` activées sur toutes les sections.

**Actions Hotwire / Stimulus proposées :**
- Étendre le futur `slider_controller` pour piloter aussi la section équipe (images, bios) et synchroniser avec les sliders des autres pages.
- Utiliser un `timeline_controller` commun avec Adhérer pour raconter l’historique (vertical timeline) tout en conservant le style Tailwind existant.
- Prévoir un `turbo_frame_tag` `partners` afin de charger/rafraîchir la liste des partenaires via un partial (`shared/_partners`) et un endpoint admin pour mise à jour sans redeployer.

---

## 📬 6. Contact

**Objectif :** centraliser la communication et les infos pratiques

### Structure :
- Formulaire de contact (Turbo Stream feedback)
- FAQ rapide (accordéons)
- Infos pratiques (horaires, adresse, carte)
- CTA “Venir nous voir”

**JS / Stimulus :**
- `form_feedback_controller`
- `accordion_controller`
- `scroll_controller`

**Technologies actuelles :**
- Template `pages/contact_us` avec formulaire HTML classique `form` (POST `/submit_contact`), classes Tailwind et `fade-in`.
- FAQ `pages/faq` déjà couplée à `accordion_controller` et Flowbite.
- `flash_controller` pour afficher des messages et `shared/navbar` pour rediriger vers FAQ / autres pages.

**Actions Hotwire / Stimulus proposées :**
- Convertir le formulaire de contact en `form_with url: contact_path, data: { turbo_stream: true }` et déclencher un Turbo Stream de confirmation/erreur (rejoué par `flash_controller`).
- Réutiliser `form_feedback_controller` pour valider les champs côté client (ex. statut “envoi en cours” et retour succès) tout en respectant Rails UJS.
- Incorporer la FAQ dans un `turbo_frame_tag` alimenté par un partial commun afin de partager les contenus dynamiques entre page Contact et page FAQ.

---

## ⚙️ Stimulus Controllers recommandés

| Fonction | Controller |
|-----------|-------------|
| Accordéons / FAQ | `accordion_controller.js` |
| Modals dynamiques | `modal_controller.js` |
| Reveal au scroll | `reveal_controller.js` |
| Smooth scroll / anchors | `scroll_controller.js` |
| Infinite scroll (actu / events) | `infinite_scroll_controller.js` |
| Navigation active | `nav_active_controller.js` |
| Carousel / slider | `slider_controller.js` |
| Timeline animée | `timeline_controller.js` |
| Checklists interactives | `checklist_controller.js` |
| Form feedback / AJAX | `form_feedback_controller.js` |

---

## 🧠 Parcours utilisateur simplifié

```
[ACCUEIL]
   ↓
[LE LIEU]
   ↓
[ADHÉRER] ←→ [NOS ACTIVITÉS]
   ↓
[À PROPOS] ←→ [CONTACT]
```

**Micro-flux dynamiques :**
- “Découvrir l’association” → Le Lieu
- “Voir le fonctionnement” → Adhérer
- “Passer nous voir” → Contact (horaires)
- “Rejoindre l’équipe” → Contact (formulaire)

Chaque CTA guide l’utilisateur naturellement vers l’étape suivante.

---

## 🔁 Bénéfices attendus

✅ Pages plus courtes (2–3 scrolls max)  
✅ Navigation cohérente et fluide (Turbo transitions)  
✅ Expérience moderne sans framework lourd  
✅ Réutilisation des partials et des composants existants  
✅ Meilleure lisibilité et hiérarchie de l’information

---

## 📎 Notes techniques (Rails 8 + Hotwire)

- Utiliser `turbo_frame_tag` pour les sections dynamiques (modals, filtres, etc.)  
- Centraliser les horaires dans `shared/_schedule.html.erb`  
- Gérer les transitions globales via Turbo Drive (fade CSS)  
- Inclure `stimulus-loading.js` pour lazy init des controllers  
- Tous les contrôleurs JS dans `app/javascript/controllers/`  
- Aucun besoin de Webpack lourd — tout passe par importmaps ou esbuild léger.

---

## 🛠️ Roadmap technique Hotwire / Stimulus

**Livrables front (Stimulus / Turbo)**
- Créer les contrôleurs `nav-active`, `slider`, `timeline`, `checklist`, `scroll_hint` et `modal` en s’appuyant sur Stimulus + Flowbite, avec hooks `turbo:load` / `turbo:before-cache` documentés.
- Mutualiser l’initialisation Swiper dans `slider_controller` (activer/détruire l’instance) et supprimer les scripts inline des partials (`shared/event_carousel`, carrousel news/galerie).
- Généraliser l’usage de `turbo_frame_tag` pour les sections dynamiques (événements, newsletter, partenaires, FAQ), en respectant les layouts actuels.

**Backend & services**
- Ajouter des endpoints légers type `EventsController#upcoming`, `#past`, et un service/Query (ex. `EventQuery` existante) pour encapsuler la logique de filtrage.
- Centraliser les données horaires / partenaires dans des partials + caches (`Rails.cache`) pour réduire le coût des rafraîchissements Turbo.
- Préparer un endpoint `ContactsController#create` renvoyant des Turbo Streams pour le formulaire de contact.

**Tests & suivi qualité**
- Écrire des tests système (Capybara) pour couvrir le parcours public (navigation, filtres événements, soumission newsletter/contact) en mode Turbo.
- Ajouter des tests unitaires pour les services/queries exploités par les frames (ex. `EventQuery.upcoming`).
- Prévoir des tests JS légers (Stimulus via @hotwired/stimulus-testing ou Jest) pour `slider_controller` et `nav-active`.
- Surveiller `log/development.log` et configurer un filtre pour les healthchecks ; vérifier l’absence de N+1 lors des rafraîchissements (Bullet gem en dev si besoin).

---

## ✅ Conclusion

Cette refonte UX/UI vise à alléger la structure du site, dynamiser la navigation et valoriser
l’autogestion du Circographe sans modifier le design system existant.

L’expérience utilisateur devient fluide, claire, et fidèle à l’esprit du lieu :  
**vivante, collective, et accessible.**

| Ancienne page       | Statut      | Nouvelle destination                 |
| ------------------- | ----------- | ------------------------------------ |
| Home                | ✅ Conservée | Accueil                              |
| Le lieu             | 🔁 Fusion   | “Le Lieu” (cirque + arts graphiques) |
| Le cirque           | 🔁 Fusion   | “Le Lieu”                            |
| Les arts graphiques | 🔁 Fusion   | “Le Lieu”                            |
| Actualités          | 🔁 Fusion   | “Nos Activités”                      |
| Blog                | 🔁 Fusion   | “Nos Activités”                      |
| Événements          | 🔁 Fusion   | “Nos Activités”                      |
| Devenir membre      | 🔁 Fusion   | “Adhérer”                            |
| Informations utiles | 🔁 Fusion   | “Adhérer”                            |
| À propos            | ✅ Conservée | “À propos”                           |
| Équipe / Historique | 🔁 Fusion   | “À propos”                           |
| Contact             | ✅ Conservée | “Contact”                            |
| FAQ                 | 🔁 Intégrée | “Adhérer” + “Contact”                |



🏠 Accueil
│
├── 🎪 Le Lieu
│   ├── Le Cirque (ancre interne)
│   ├── Les Arts Graphiques (ancre interne)
│   └── Fonctionnement du lieu (autogestion, bénévoles, adhésion)
│
├── 🗓️ Nos Activités
│   ├── Événements à venir
│   ├── Événements passés
│   ├── Actualités / blog
│   └── Newsletter
│
├── 🤝 Adhérer
│   ├── Pourquoi nous rejoindre ?
│   ├── Comment adhérer (étapes)
│   ├── Tarifs & types d’adhésion
│   ├── Documents requis
│   └── FAQ courte
│
├── 🧑‍🎨 À propos
│   ├── Mission et valeurs
│   ├── L’équipe et le CA
│   ├── Histoire / fondateurs
│   └── Partenaires / presse
│
└── 📬 Contact
    ├── Formulaire
    ├── Horaires
    ├── Adresse / plan
    └── Mini FAQ


**WIREFRAME**

# 🧭 Wireframe éditorial & UX/UI — **Le Circographe**
*(Document global — 2025-11-06)*

---

## 🎯 Objectif global

Refonte complète du site du **Circographe** : architecture, parcours utilisateur, logique UX/UI et structure éditoriale.  
Ce document compile **toutes les pages** dans un format clair pour le développement et la rédaction dans **Cursor**.

**Ton :** humain, chaleureux, professionnel  
**Style :** textes courts et structurés  
**Technos front :** Rails 8 + Hotwire / Stimulus  
**Design :** minimaliste, atoms existants conservés  

---

# 🏠 Page 1 — Accueil

## 🎯 Objectif
Accueillir, orienter, et inviter à découvrir le lieu.  
Page courte, impactante, CTA vers “Le Lieu” et “Adhérer”.

### Structure
```
[HERO]
  ↓
[Événements à venir]
  ↓
[Horaires & infos]
  ↓
[Carte Google Maps]
  ↓
[Footer]
```

### Contenu
**Titre :** “Le Circographe”  
**Sous-titre :** “Où le cirque et les arts graphiques se rencontrent.”  
**Texte :**
> Un lieu associatif, ouvert à tous, où la création prend vie entre chapiteaux et pinceaux.

**CTA principal :** [Découvrir l’association → /le-lieu]  
**Bloc événements :** Cards dynamiques (3–4 max)  
**Bloc horaires :** partial `_schedule.html.erb` partagé  
**Bloc carte :** GMap embed + adresse

**JS / Stimulus :**
- `reveal_controller` (fade au scroll)
- `infinite_scroll_controller` (événements)
- `scroll_hint_controller` (scroll down visuel)

---

# 🎪 Page 2 — Le Lieu

## 🎯 Objectif
Présenter le cœur du projet : pratique artistique, autogestion, rencontre humaine.

### Structure
```
[HERO]
  ↓
[Le Cirque]
  ↓
[Les Arts Graphiques]
  ↓
[Fonctionnement du lieu]
  ↓
[Bénévoles]
  ↓
[Galerie]
  ↓
[CTA final]
```

### Contenu résumé
- **HERO :** “Bienvenue au Circographe” — court texte de présentation  
- **Le Cirque :** entraînement libre, résidences, stages  
- **Arts Graphiques :** créations libres, expositions, résidences visuelles  
- **Fonctionnement :** autogestion, adhésion sur place, participation collective  
- **Bénévoles :** appel à rejoindre l’équipe  
- **Galerie :** carousel mixte  
- **CTA final :** “Tout commence par une rencontre — passe nous voir.”

**JS / Stimulus :**
- `accordion_controller`
- `modal_controller`
- `slider_controller`
- `reveal_controller`

---

# 🗓️ Page 3 — Nos Activités

## 🎯 Objectif
Regrouper tout ce qui fait vivre le lieu : événements, actus, stages, expositions.

### Structure
```
[Filtres dynamiques]
  ↓
[Grid d’événements]
  ↓
[Newsletter]
  ↓
[CTA final]
```

### Contenu
**Filtres :** “Tous | À venir | Passés | Actualités”  
**Cards :** titre, image, date, court résumé, bouton [En savoir +]  
**Newsletter :** “Abonnez-vous pour suivre les stages et expositions.”

**JS / Stimulus :**
- `tabs_controller` (filtres dynamiques)
- `infinite_scroll_controller`
- `modal_controller`
- `form_feedback_controller`

---

# 🤝 Page 4 — Adhérer

## 🎯 Objectif
Expliquer simplement le processus d’adhésion, sur place uniquement.  
Page pratique, fluide, centrée sur la rencontre et la transparence.

### Structure
```
[HERO]
  ↓
[Pourquoi adhérer]
  ↓
[Comment ça marche]
  ↓
[Tarifs & types]
  ↓
[Documents requis]
  ↓
[Horaires + carte]
  ↓
[CTA final]
```

### Contenu
**HERO :** “Adhérer au Circographe — tout commence par une poignée de main.”  
**Pourquoi adhérer :** 3 cards (Pratiquer / Créer / Faire vivre le lieu)  
**Comment ça marche :** ① Passer nous voir → ② Adhérer au bureau → ③ Participer  
**Tarifs :** Standard / Solidaire (accordéon réductions)  
**Documents :** checklist interactive (identité, domicile, photo, justificatif)  
**Horaires :** partial `_schedule.html.erb` + carte Google  
**CTA final :** “Passer nous voir”

**JS / Stimulus :**
- `timeline_controller`
- `accordion_controller`
- `checklist_controller`
- `scroll_controller`
- `form_feedback_controller`

---

# 🧑‍🎨 Page 5 — À propos

## 🎯 Objectif
Présenter les valeurs, l’équipe et l’histoire du lieu.

### Structure
```
[Mission & valeurs]
  ↓
[Équipe]
  ↓
[Historique]
  ↓
[Partenaires / Presse]
  ↓
[CTA Contact]
```

### Contenu
**Mission :** rendre la création accessible, décloisonner les disciplines.  
**Équipe :** slider horizontal portraits + rôles  
**Historique :** timeline 2023–2025 (ouverture, projets accueillis, évolution)  
**Partenaires :** grille logos avec hover infos

**JS / Stimulus :**
- `slider_controller`
- `timeline_controller`
- `reveal_controller`

---

# 📬 Page 6 — Contact

## 🎯 Objectif
Faciliter le contact et l’accès au lieu.  

### Structure
```
[HERO]
  ↓
[Formulaire de contact]
  ↓
[FAQ rapide]
  ↓
[Infos pratiques]
  ↓
[CTA final]
```

### Contenu
**Formulaire :** Nom, Email, Sujet, Message, CTA [Envoyer]  
**FAQ :** 4–5 questions (accordéons)  
**Infos pratiques :** Adresse, horaires, plan, liens réseaux  
**CTA :** [Venir nous voir]

**JS / Stimulus :**
- `form_feedback_controller`
- `accordion_controller`
- `scroll_controller`

---

# ⚙️ Stimulus Controllers communs

| Fonction | Controller |
|-----------|-------------|
| Accordéons / FAQ | `accordion_controller.js` |
| Modals dynamiques | `modal_controller.js` |
| Reveal au scroll | `reveal_controller.js` |
| Smooth scroll / anchors | `scroll_controller.js` |
| Infinite scroll | `infinite_scroll_controller.js` |
| Navigation active | `nav_active_controller.js` |
| Carousel / slider | `slider_controller.js` |
| Timeline animée | `timeline_controller.js` |
| Checklists interactives | `checklist_controller.js` |
| Form feedback / AJAX | `form_feedback_controller.js` |

---

# 🔁 Parcours utilisateur

```
[ACCUEIL]
   ↓
[LE LIEU]
   ↓
[ADHÉRER] ←→ [NOS ACTIVITÉS]
   ↓
[À PROPOS] ←→ [CONTACT]
```

**Micro-flux dynamiques :**
- “Découvrir l’association” → Le Lieu  
- “Voir le fonctionnement” → Adhérer  
- “Passer nous voir” → Contact  
- “Rejoindre l’équipe” → Contact formulaire

---

# 🧠 Résumé stratégique

✅ Scroll limité (2–3 écrans par page)  
✅ Parcours fluide et cohérent  
✅ Composants réutilisables (horaires, modals, galerie)  
✅ Dynamique moderne via Stimulus + Turbo  
✅ Fidélité à l’esprit du lieu : accessible, collectif, vivant
