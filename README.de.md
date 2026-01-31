# DodoCount

Eine elegante macOS Menüleisten-App für Google Analytics 4 und Search Console.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/Lizenz-MIT-green)

🌐 **Übersetzungen:** [English](README.md) | [Türkçe](README.tr.md) | [Français](README.fr.md) | [Español](README.es.md)

## Funktionen

- **Echtzeit-Besucherverfolgung** - Aktive Nutzer direkt in Ihrer Menüleiste sehen
- **Google Analytics 4 Integration** - Volle Unterstützung für GA4 Properties
- **Search Console Daten** - Klicks, Impressionen, CTR und Position verfolgen
- **Heute vs Gestern Vergleich** - Nutzer, Sitzungen, Seitenaufrufe, Absprungrate, Dauer
- **28-Tage Übersicht** - Erweiterte Metriken mit Trendvisualisierung
- **Top-Seiten & Traffic-Quellen** - Sehen Sie was funktioniert
- **Mehrere Properties** - Einfach zwischen GA4 Properties wechseln
- **Schönes dunkles Theme** - Glasmorphismus-Design passend zur macOS Ästhetik
- **Statistiken teilen** - Kurze, detaillierte oder Slack-formatierte Statistiken kopieren
- **Warnungen** - Benachrichtigungen bei Traffic-Spitzen, -Einbrüchen und Zielerreichungen
- **Globale Tastenkombination** - Schneller Zugriff mit Cmd+Shift+G
- **Mehrsprachige Unterstützung** - Englisch, Türkisch, Deutsch, Französisch, Spanisch

## Anforderungen

- macOS 14.0 oder neuer
- Google Cloud Projekt mit OAuth 2.0 Anmeldedaten
- Google Analytics 4 Property
- (Optional) Google Search Console Website

## Installation

### Homebrew (Empfohlen)

```bash
brew tap DodoApps/tap
brew install --cask dodocount
xattr -cr /Applications/DodoCount.app
```

### Manueller Download

1. Laden Sie die neueste Version von [Releases](https://github.com/DodoApps/dodocount/releases) herunter
2. Verschieben Sie DodoCount.app in Ihren Programme-Ordner
3. Führen Sie `xattr -cr /Applications/DodoCount.app` aus, um die Quarantäne zu entfernen
4. Starten Sie DodoCount

## Einrichtung

### 1. Google Cloud OAuth Anmeldedaten erstellen

1. Gehen Sie zur [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Erstellen Sie ein neues Projekt oder wählen Sie ein bestehendes
3. Aktivieren Sie folgende APIs:
   - Google Analytics Data API
   - Google Analytics Admin API
   - Google Search Console API
4. Erstellen Sie OAuth 2.0 Anmeldedaten:
   - Anwendungstyp: **iOS** (erforderlich für Desktop-Apps)
   - Bundle ID: `com.dodocount`
5. Kopieren Sie Ihre Client-ID

### 2. DodoCount konfigurieren

1. Klicken Sie auf das DodoCount-Symbol in Ihrer Menüleiste
2. Klicken Sie auf das Zahnrad-Symbol um die Einstellungen zu öffnen
3. Fügen Sie Ihre Client-ID im Abschnitt "Google Cloud" ein
4. Klicken Sie auf "Anmelden" um sich bei Google zu authentifizieren
5. Wählen Sie Ihre GA4 Property aus dem Dropdown-Menü

## Verwendung

- **Linksklick** auf das Menüleisten-Symbol öffnet das Dashboard
- **Rechtsklick** für Schnellaktionen (Statistiken kopieren, Aktualisieren, Einstellungen, Beenden)
- **Cmd+Shift+G** um das Dashboard von überall zu öffnen/schließen

## Aus Quellcode kompilieren

```bash
git clone https://github.com/DodoApps/dodocount.git
cd dodocount
open DodoCount.xcodeproj
```

In Xcode kompilieren und ausführen (erfordert Xcode 15.0+).

## Mitwirken

Beiträge sind willkommen! Fühlen Sie sich frei einen Pull Request einzureichen.

## Lizenz

MIT Lizenz - siehe [LICENSE](LICENSE) für Details.

## Urheberrecht

© 2026 DodoApps

