# Documentation - Le Circographe

**Date:** 2025-01-31  
**Version:** Synthétisée et optimisée

---

## 📚 Guide de Navigation

### Architecture & Design

1. **[ARCHITECTURE_SERVICES.md](./ARCHITECTURE_SERVICES.md)** - ⭐ **Source unique de vérité**
   - Pattern Controller → Service → Model
   - 44 services dans 15 domaines
   - 21 ViewComponents actifs
   - Tous les controllers admin utilisent des services
   - Vérification complète de l'architecture

2. **[CONCERNS_ANALYSIS.md](./CONCERNS_ANALYSIS.md)** - Analyse complète des concerns
   - 10 concerns documentés
   - Tableau récapitulatif complet (13 modèles)
   - Plan d'action complété

3. **[MODEL_EVALUATION.md](./MODEL_EVALUATION.md)** - Évaluation du modèle de données
   - Score: 9/10
   - Architecture Person-Based
   - Points forts et améliorations

**Note:** Pour les détails ViewComponents, voir `../ARCHITECTURE_GUIDE.md` à la racine.

### Logique Métier

4. **[BUSINESS_LOGIC.md](./BUSINESS_LOGIC.md)** - Règles business complètes
   - Classification Zone 1/2/3
   - Domaines métier (Membership, Payment, Subscription, etc.)
   - Historique des refactorings
   - Architecture Services

5. **[ZONES_CLASSIFICATION.md](./ZONES_CLASSIFICATION.md)** - Classification par zones
   - Zone 1 (Stable) - Tests immédiats
   - Zone 2 (En cours) - Tests après stabilisation
   - Zone 3 (Future) - Pas de tests

### Tests & Qualité

6. **[TDD_GUIDE.md](./TDD_GUIDE.md)** - Guide complet TDD
   - Philosophie Red-Green-Refactor
   - Configuration et setup
   - Stratégie de tests (Invariants, Contrats, Caractérisation)
   - Workflow TDD
   - Outils et commandes
   - CI/CD

7. **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Guide tests et couverture
   - Pourquoi la couverture est importante
   - Rapport SimpleCov
   - Audit de couverture
   - Gaps identifiés
   - Plan d'action

8. **[CONTROLLERS_AUDIT.md](./CONTROLLERS_AUDIT.md)** - Audit des contrôleurs
   - Stratégie TDD par zone
   - Contrôleurs critiques (Zone 1)
   - État des tests
   - Plan d'action prioritaire

### UX/UI

9. **[UX_GUIDE.md](./UX_GUIDE.md)** - Guide UX/UI
   - Problèmes critiques identifiés
   - Procédure d'adhésion
   - Newsletter legacy
   - Gestion compte web
   - Plan d'action global

### Configuration

10. **[ASSETS_LOCK.md](./ASSETS_LOCK.md)** - Règles asset pipeline
    - Tailwind CSS
    - Propshaft
    - Vite (optionnel)

---

## 🎯 Fichiers par Thème

### Pour comprendre l'architecture
→ `ARCHITECTURE_SERVICES.md` + `CONCERNS_ANALYSIS.md` + `MODEL_EVALUATION.md`

### Pour comprendre la logique métier
→ `BUSINESS_LOGIC.md` + `ZONES_CLASSIFICATION.md`

### Pour écrire des tests
→ `TDD_GUIDE.md` + `TESTING_GUIDE.md` + `CONTROLLERS_AUDIT.md`

### Pour améliorer l'UX
→ `UX_GUIDE.md`

---

## 📊 Statistiques

- **11 fichiers docs/** (réduit de 18 → 11, -39%)
- **44 services** dans 15 domaines *Management
- **21 ViewComponents** actifs
- **2 Query Objects** (PersonQuery, PaymentQuery)
- **10 concerns** documentés
- **13 modèles** avec concerns
- **19 controllers admin** (13 utilisent services, 6 sans logique métier complexe)

---

## 🔗 Liens Croisés

Tous les fichiers principaux ont une section "Documentation liée" avec des liens vers les autres fichiers pertinents.

---

**Dernière mise à jour:** 2025-01-31  
**Synthèse:** 2025-01-31 - Documentation optimisée, code nettoyé, architecture vérifiée


