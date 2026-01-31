<p align="center">
  <img src="dodocount.png" alt="DodoCount" width="200" />
</p>

<h1 align="center">DodoCount</h1>

<p align="center">
  Une élégante application de barre de menus macOS pour Google Analytics 4 et Search Console.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift" />
  <img src="https://img.shields.io/badge/Licence-MIT-green" alt="License" />
</p>

<p align="center">
  🌐 <strong>Traductions :</strong> <a href="README.md">English</a> | <a href="README.tr.md">Türkçe</a> | <a href="README.de.md">Deutsch</a> | <a href="README.es.md">Español</a>
</p>

## Fonctionnalités

- **Suivi des visiteurs en temps réel** - Voyez les utilisateurs actifs directement dans votre barre de menus
- **Intégration Google Analytics 4** - Support complet des propriétés GA4
- **Données Search Console** - Suivez les clics, impressions, CTR et position
- **Comparaison Aujourd'hui vs Hier** - Utilisateurs, sessions, pages vues, taux de rebond, durée
- **Aperçu 28 jours** - Métriques étendues avec visualisation des tendances
- **Pages populaires & sources de trafic** - Voyez ce qui fonctionne
- **Propriétés multiples** - Basculez facilement entre les propriétés GA4
- **Beau thème sombre** - Design glass morphism adapté à l'esthétique macOS
- **Partager les statistiques** - Copiez des statistiques rapides, détaillées ou au format Slack
- **Alertes** - Notifications pour les pics de trafic, baisses et objectifs atteints
- **Raccourci global** - Accès rapide avec Cmd+Shift+G
- **Support multilingue** - Anglais, Turc, Allemand, Français, Espagnol

## Prérequis

- macOS 14.0 ou ultérieur
- Projet Google Cloud avec identifiants OAuth 2.0
- Propriété Google Analytics 4
- (Optionnel) Site Google Search Console

## Installation

### Homebrew (Recommandé)

```bash
brew tap DodoApps/tap
brew install --cask dodocount
xattr -cr /Applications/DodoCount.app
```

### Téléchargement Manuel

1. Téléchargez la dernière version depuis [Releases](https://github.com/DodoApps/dodocount/releases)
2. Déplacez DodoCount.app dans votre dossier Applications
3. Exécutez `xattr -cr /Applications/DodoCount.app` pour supprimer la quarantaine
4. Lancez DodoCount

## Configuration

### 1. Créer des identifiants OAuth Google Cloud

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Créez un nouveau projet ou sélectionnez-en un existant
3. Activez les APIs suivantes :
   - Google Analytics Data API
   - Google Analytics Admin API
   - Google Search Console API
4. Créez des identifiants OAuth 2.0 :
   - Type d'application : **iOS** (requis pour les apps de bureau)
   - Bundle ID : `com.dodocount`
5. Copiez votre ID client

### 2. Configurer DodoCount

1. Cliquez sur l'icône DodoCount dans votre barre de menus
2. Cliquez sur l'icône d'engrenage pour ouvrir les Paramètres
3. Collez votre ID client dans la section "Google Cloud"
4. Cliquez sur "Se connecter" pour vous authentifier avec Google
5. Sélectionnez votre propriété GA4 dans le menu déroulant

## Utilisation

- **Clic gauche** sur l'icône de la barre de menus pour ouvrir le tableau de bord
- **Clic droit** pour les actions rapides (copier les stats, actualiser, paramètres, quitter)
- **Cmd+Shift+G** pour afficher/masquer le tableau de bord de n'importe où

## Compilation depuis les sources

```bash
git clone https://github.com/DodoApps/dodocount.git
cd dodocount
open DodoCount.xcodeproj
```

Compilez et exécutez dans Xcode (nécessite Xcode 15.0+).

## Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à soumettre une Pull Request.

## Licence

Licence MIT - voir [LICENSE](LICENSE) pour les détails.

## Droits d'auteur

© 2026 DodoApps

