# 📚 Base de Connaissance - Le Circographe

Ce dossier contient toute la documentation technique, les découvertes, et les plans d'action pour le projet.

---

## 📋 **Index des Documents**

### **🧠 Connaissance Critique**
- **[KNOWLEDGE_BASE.md](KNOWLEDGE_BASE.md)** - Règles d'or, solutions résolues, pièges évités
- **[SESSION_LOG_2025-10-12.md](SESSION_LOG_2025-10-12.md)** - Journal détaillé de la session de debug CSS

### **🚀 Déploiement**
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guide rapide de déploiement (staging/production)
- **[DEPLOYMENT_ANALYSIS.md](DEPLOYMENT_ANALYSIS.md)** - Analyse approfondie des logs de déploiement
- **[DEPLOIEMENT.md](DEPLOIEMENT.md)** - Documentation initiale de déploiement
- **[DEPLOIEMENT_RAPIDE.md](DEPLOIEMENT_RAPIDE.md)** - Procédure rapide de déploiement

### **📊 Performance & Optimisations**
- **[PERFORMANCE_REPORT.md](PERFORMANCE_REPORT.md)** - Rapport de performance après optimisations
- **[OPTIMIZATIONS_TODO.md](OPTIMIZATIONS_TODO.md)** - Liste des optimisations à implémenter
- **[ANALYSIS_SUMMARY.md](ANALYSIS_SUMMARY.md)** - Résumé exécutif de l'analyse

### **🎨 CSS & Frontend**
- **[CSS_MIGRATION_STRATEGY.md](CSS_MIGRATION_STRATEGY.md)** - Plan de migration CSS vers architecture propre

### **🏗️ Production**
- **[PRODUCTION_DEPLOYMENT_PLAN.md](PRODUCTION_DEPLOYMENT_PLAN.md)** - Plan de déploiement production avec mode maintenance

---

## 🎯 **Documents par Priorité**

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

