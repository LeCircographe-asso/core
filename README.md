# Le Circographe 🎪

**Le Circographe** est une application de gestion pour une association de cirque basée à Toulouse, France.

## 🎯 Objectif

Réaliser un site web en Ruby on Rails pour gérer :
- Les adhésions et abonnements
- Les entraînements quotidiens
- Les événements de l'association

## 🛠 Technologies

- **Backend**: Ruby on Rails 8.0.1
- **Frontend**: Hotwire (Turbo & Stimulus)
- **Base de données**: SQLite3
- **Paiements**: Stripe
- **Déploiement**: Ionos VPS

## 💻 Installation

1. Cloner le repository:
```bash
git clone https://github.com/Team-stash/le_circographe.git
cd le_circographe
```

2. Installation des dépendances :
```bash
bundle install
```

3. Configuration de la base de données :
```bash
rails db:create db:migrate db:seed
```

4. Lancer l'application :
```bash
rails assets:clobber
./bin/dev
rails server
```

5. Accédez à l'application : http://localhost:3000

## 🎨 Design

- [Maquette Figma](https://www.figma.com/design/EDzWXstQDroP9qsXQeDJ0n/Untitled?node-id=0-1&t=L5nyuxxAHArehDCo-0)
- [Parcours Utilisateur](https://github.com/user-attachments/assets/1cd3617d-61bd-4ad7-bd50-9029877bcb8b)
- [Schéma Base de données](https://github.com/user-attachments/assets/04ab7878-7da6-48bf-95f4-8f11bdd28eda)

## 🚀 Démo

- URL: [http://87.106.173.45:3000/](http://87.106.173.45:3000/)
- Admin: admin@rails.com
- Password: 123456

## 👥 Équipe

- Mentor : Hadrien SAMOUILLAN
- Membres :
  - [Christophe Alaterre](https://github.com/AkaKwak)
  - [Thierry Corlieto](https://github.com/hellijah)
  - [Florian Elie](https://github.com/Elie-Kauptairr)
  - [Luc Ramassamy](https://github.com/Warzieram)
  - [Sacha Courbé](https://github.com/Sachathp)

### Maquette

[Maquette Figma](https://www.figma.com/design/EDzWXstQDroP9qsXQeDJ0n/Untitled?node-id=0-1&t=L5nyuxxAHArehDCo-0)

### Parcours Utilisateur

french version
![image](https://github.com/user-attachments/assets/1cd3617d-61bd-4ad7-bd50-9029877bcb8b)

### Base de données

![image](https://github.com/user-attachments/assets/04ab7878-7da6-48bf-95f4-8f11bdd28eda)

### Captures d'écran et démo

[lien](http://87.106.173.45:3000/)
Utilisateur Admin : admin@rails.com
mot de passe : 123456
