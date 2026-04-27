# 📚 Base de Connaissance - Le Circographe

Ce dossier contient toute la documentation technique, les découvertes, et les plans d'action pour le projet.

> **Journal historique non normatif** — les fichiers de ce dossier reflètent l'état du projet à différentes dates et **ne sont pas la source de vérité du vocabulaire métier courant**.
> Pour les règles canoniques, se référer à :
> - [`docs/glossary.md`](../glossary.md)
> - [`docs/domain_model.md`](../domain_model.md)
> - [`docs/payments.md`](../payments.md)
> - [`docs/migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md)

---

## 📋 **Index des Documents**

### ✅ **Source de vérité**
- Voir [`docs/README.md`](../README.md) pour l'index courant.

### **🧠 Connaissance Critique**
- **[KNOWLEDGE_BASE.md](KNOWLEDGE_BASE.md)** - Règles d'or, solutions résolues, pièges évités
- **[archive/SESSION_LOG_2025-10-12.md](archive/SESSION_LOG_2025-10-12.md)** - Journal détaillé de la session de debug CSS (historique)

### **🚀 Déploiement**
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guide rapide de déploiement (staging/production)
- **[archive/DEPLOYMENT_ANALYSIS.md](archive/DEPLOYMENT_ANALYSIS.md)** - Analyse approfondie des logs (historique)
- **[archive/DEPLOIEMENT.md](archive/DEPLOIEMENT.md)** - Documentation initiale (historique)
- **[archive/DEPLOIEMENT_RAPIDE.md](archive/DEPLOIEMENT_RAPIDE.md)** - Procédure rapide (historique)

### **📊 Performance & Optimisations**
- **[archive/PERFORMANCE_REPORT.md](archive/PERFORMANCE_REPORT.md)** - Rapport de performance (historique)
- **[OPTIMIZATIONS_TODO.md](OPTIMIZATIONS_TODO.md)** - Liste des optimisations à implémenter
- **[archive/ANALYSIS_SUMMARY.md](archive/ANALYSIS_SUMMARY.md)** - Résumé exécutif (historique)

### **🎨 CSS & Frontend**
- **[CSS_MIGRATION_STRATEGY.md](CSS_MIGRATION_STRATEGY.md)** - Plan de migration CSS vers architecture propre

### **🏗️ Production**
- **[PRODUCTION_DEPLOYMENT_PLAN.md](PRODUCTION_DEPLOYMENT_PLAN.md)** - Plan de déploiement production (historique)

---

## 🎯 **Documents par Priorité (historique)**

**Note:** L’ordre ci-dessous reflète une priorisation de 2025-10-12.  
Pour l’actuel, se référer à `to-do.md` (produit) et `knowledge/OPTIMIZATIONS_TODO.md` (infra).

### **À Lire en Premier :**
1. **KNOWLEDGE_BASE.md** - Règles critiques à ne jamais oublier
2. **DEPLOYMENT_GUIDE.md** - Workflow de déploiement standard

### **Pour Déployer :**
3. **PRODUCTION_DEPLOYMENT_PLAN.md** - Plan complet pour mise en production
4. **DEPLOYMENT_ANALYSIS.md** - Comprendre les logs et warnings

### **Pour Optimiser :**
5. **OPTIMIZATIONS_TODO.md** - Actions concrètes d'optimisation
6. **PERFORMANCE_REPORT.md** - Métriques et gains attendus

### **Pour Refactorer :**
7. **CSS_MIGRATION_STRATEGY.md** - Sortir du "bordel CSS"

---

## 📅 **Historique**

- **2025-10-12** - Session intensive de debug et optimisation
  - ✅ Résolution `Propshaft::MissingAssetError`
  - ✅ Correction workflow Git (branches dédiées)
  - ✅ Optimisations Docker build cache
  - ✅ Sécurité (Rack CVE, bundle audit)
  - ✅ Plan production avec maintenance mode

---

## 🔄 **Mise à Jour**

Cette base de connaissance est vivante. Ajouter un nouveau document :

```bash
# 1. Créer le fichier dans knowledge/
touch knowledge/NOUVEAU_DOCUMENT.md

# 2. Ajouter à l'index ci-dessus
# 3. Commit sur branche dédiée
git checkout -b docs/nouveau-document
git add knowledge/
git commit -m "docs: Add NOUVEAU_DOCUMENT"
git push origin docs/nouveau-document
```

---

**Dernière mise à jour :** 2025-10-12
