# Migration des Rôles et Adhésions

## État Initial

### Rôles actuels
- guest
- membership
- circus_membership
- volunteer
- admin
- godmode

### Types d'adhésion/abonnement
- basic_membership (1€)
- circus_membership (10€)
- day_pass (4€)
- ten_sessions (30€)
- quarterly (65€)
- yearly (150€)

## Nouvelle Structure

### Nouveaux Rôles (permissions)
- guest (0) : Utilisateur inscrit basique
- member (1) : Membre avec droits basiques
- volunteer (2) : Peut gérer les présences et adhésions
- admin (3) : Accès complet admin
- godmode (4) : Super admin

### Types d'adhésion (inchangés)
- basic_membership (0)
- circus_membership (1)
- day_pass (2)
- ten_sessions (3)
- quarterly (4)
- yearly (5)

## Plan de Migration

### Correspondance des Rôles
- Ancien 'guest' -> Nouveau 'guest'
- Ancien 'membership' -> Nouveau 'member'
- Ancien 'circus_membership' -> Nouveau 'member'
- Ancien 'volunteer' -> Nouveau 'volunteer'
- Ancien 'admin' -> Nouveau 'admin'
- Ancien 'godmode' -> Nouveau 'godmode'

### Étapes de Migration
1. Ajouter nouvelle colonne role_new (integer)
2. Migrer les données selon la correspondance
3. Vérifier la cohérence
4. Remplacer l'ancienne colonne par la nouvelle
5. Mettre à jour le modèle User

### Points d'attention
- Préserver les adhésions existantes
- Maintenir la cohérence des permissions
- Assurer la continuité du service
- Prévoir une procédure de rollback 