## Mode maintenance

Activer une page unique « En maintenance » pour l’ensemble du site:

1. Définir la variable d’environnement:

   ```bash
   export MAINTENANCE_MODE=true
   # ou dans production: MAINTENANCE_MODE=true systemd/ENV/Dokku/Heroku variables
   ```

2. Désactiver:

   ```bash
   export MAINTENANCE_MODE=false
   ```

3. L’endpoint `/up` reste accessible (healthcheck).


