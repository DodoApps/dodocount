<p align="center">
  <img src="dodocount.png" alt="DodoCount" width="200" />
</p>

<h1 align="center">DodoCount</h1>

<p align="center">
  A beautiful macOS menubar app for Google Analytics 4 and Search Console.
</p>

<img width="337" height="724" alt="image" src="https://github.com/user-attachments/assets/ee7dd7e5-9951-4157-94bb-29ccbf15edb6" />
<img width="348" height="763" alt="image" src="https://github.com/user-attachments/assets/59f64d9e-98e0-425a-9f5d-2851a5bc7dc2" />
<img width="350" height="763" alt="image" src="https://github.com/user-attachments/assets/0c583250-f83e-4da8-920a-d71761cc4ee7" />


<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

<p align="center">
  🌐 <strong>Translations:</strong> <a href="README.tr.md">Türkçe</a> | <a href="README.de.md">Deutsch</a> | <a href="README.fr.md">Français</a> | <a href="README.es.md">Español</a>
</p>

## Features

- **Real-time visitor tracking** - See active users directly in your menubar
- **Google Analytics 4 integration** - Full support for GA4 properties
- **Search Console data** - Track clicks, impressions, CTR, and position
- **Today vs Yesterday comparison** - Users, sessions, pageviews, bounce rate, duration
- **28-day overview** - Extended metrics with trend visualization
- **Top pages & traffic sources** - See what's working
- **Multiple properties** - Switch between GA4 properties easily
- **Beautiful dark theme** - Glass morphism design matching macOS aesthetics
- **Share stats** - Copy quick, detailed, or Slack-formatted stats
- **Alerts** - Get notified on traffic spikes, drops, and goal achievements
- **Global hotkey** - Quick access with Cmd+Shift+G
- **Multi-language support** - English, Turkish, German, French, Spanish

## Requirements

- macOS 14.0 or later
- Google Cloud project with OAuth 2.0 credentials
- Google Analytics 4 property
- (Optional) Google Search Console site

## Installation

### Homebrew (Recommended)

```bash
brew tap DodoApps/tap
brew install --cask dodocount
xattr -cr /Applications/DodoCount.app
```

### Manual Download

1. Download the latest release from [Releases](https://github.com/DodoApps/dodocount/releases)
2. Move DodoCount.app to your Applications folder
3. Run `xattr -cr /Applications/DodoCount.app` to remove quarantine
4. Launch DodoCount

## Setup

### 1. Create Google Cloud OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Google Analytics Data API
   - Google Analytics Admin API
   - Google Search Console API
4. Create OAuth 2.0 credentials:
   - Application type: **iOS** (required for desktop apps)
   - Bundle ID: `com.dodocount`
5. Copy your Client ID

### 2. Configure DodoCount

1. Click the DodoCount icon in your menubar
2. Click the gear icon to open Settings
3. Paste your Client ID in the "Google Cloud" section
4. Click "Sign in" to authenticate with Google
5. Select your GA4 property from the dropdown

## Usage

- **Left-click** the menubar icon to open the dashboard
- **Right-click** for quick actions (copy stats, refresh, settings, quit)
- **Cmd+Shift+G** to toggle the dashboard from anywhere

## Building from Source

```bash
git clone https://github.com/DodoApps/dodocount.git
cd dodocount
open DodoCount.xcodeproj
```

Build and run in Xcode (requires Xcode 15.0+).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

© 2026 DodoApps

