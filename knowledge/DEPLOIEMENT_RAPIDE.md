# Guide de Déploiement Rapide - Le Circographe

## 🚀 Déploiement Staging (Test)

### 1. **Préparation**
```bash
# S'assurer d'être sur la branche dev
git checkout dev
git pull origin dev

# Vérifier que tout fonctionne localement
./scripts/setup-environment.sh development
bundle exec rails test
```

### 2. **Merge vers Staging**
```bash
git checkout staging
git merge dev
git push origin staging
```

### 3. **Surveiller le Déploiement**
- Aller sur GitHub → Actions
- Surveiller le workflow "03 - Staging Deploy"
- Attendre ~5-10 minutes

### 4. **Vérifier le Déploiement**
```bash
curl -I https://staging.lecircographe.fr
# Doit retourner: HTTP/2 200 OK
```

### 5. **Debug si Problème**
```bash
# Voir les logs du conteneur
ssh deploy@<staging-vps-ip>
docker ps
docker logs <container-id> --tail 100
```

---

## 🚀 Déploiement Production

### ⚠️ **IMPORTANT: Toujours tester sur staging d'abord !**

### 1. **Validation Staging**
```bash
# Tester toutes les fonctionnalités sur staging
# Vérifier les emails, paiements, etc.
```

### 2. **Merge vers Production**
```bash
git checkout production
git merge staging
git push origin production
```

### 3. **Surveiller le Déploiement**
- Aller sur GitHub → Actions
- Surveiller le workflow "04 - Production Deploy"
- Attendre ~5-10 minutes

### 4. **Vérifier le Déploiement**
```bash
curl -I https://lecircographe.fr
# Doit retourner: HTTP/2 200 OK
```

---

## 🔧 Commandes Utiles

### **Rollback d'Urgence**
```bash
# Staging
kamal rollback -c config/deploy.staging.yml

# Production
kamal rollback -c config/deploy.production.yml
```

### **Accès au Conteneur**
```bash
# Staging
kamal app exec -c config/deploy.staging.yml --interactive bash

# Production
kamal app exec -c config/deploy.production.yml --interactive bash
```

### **Logs en Temps Réel**
```bash
# Staging
kamal app logs -c config/deploy.staging.yml --follow

# Production
kamal app logs -c config/deploy.production.yml --follow
```

### **Console Rails**
```bash
# Staging
kamal app exec -c config/deploy.staging.yml --interactive "bundle exec rails console"

# Production
kamal app exec -c config/deploy.production.yml --interactive "bundle exec rails console"
```

---

## 🚨 Troubleshooting

### **Erreur 500 sur le Site**
1. Vérifier les logs du conteneur
2. Vérifier que la base de données est accessible
3. Vérifier les credentials Rails

### **Assets Non Trouvés (Propshaft Error)**
1. Vérifier que les assets sont compilés dans l'image Docker
2. Vérifier le path des assets dans la configuration
3. Redéployer si nécessaire

### **Base de Données Lockée**
1. Arrêter l'application temporairement
2. Vérifier les processus SQLite
3. Redémarrer le conteneur

### **Problème de Credentials**
1. Vérifier que RAILS_MASTER_KEY est définie
2. Vérifier que le fichier credentials.yml.enc existe
3. Re-générer les credentials si nécessaire

---

## 📋 Checklist de Déploiement

### **Avant le Déploiement**
- [ ] Tests locaux passent
- [ ] Migration de base de données testée
- [ ] Assets compilés correctement
- [ ] Credentials à jour
- [ ] Documentation mise à jour

### **Après le Déploiement**
- [ ] Site accessible (HTTP 200)
- [ ] Fonctionnalités principales testées
- [ ] Emails fonctionnent
- [ ] Paiements fonctionnent (si applicable)
- [ ] Logs sans erreurs critiques

### **En Cas de Problème**
- [ ] Logs consultés
- [ ] Rollback effectué si nécessaire
- [ ] Problème documenté
- [ ] Solution appliquée et testée

---

## 🔐 Sécurité

### **Secrets**
- Jamais de credentials de production en local
- Utiliser des tokens temporaires pour les tests
- Rotation régulière des clés

### **Accès**
- Limiter l'accès SSH aux serveurs
- Utiliser des clés SSH, pas de mots de passe
- Logs d'accès surveillés

### **Backup**
- Base de données sauvegardée régulièrement
- Images Docker taguées et archivées
- Configuration versionnée
