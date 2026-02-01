# DodoCount - Claude Code Instructions

## Installation Note

When providing Homebrew installation instructions to users, ALWAYS include the xattr command as the third step:

```bash
brew tap DodoApps/tap
brew install --cask dodocount
xattr -cr /Applications/DodoCount.app
```

The `xattr -cr` command is **required** because the app is not notarized with Apple. Without it, macOS Gatekeeper will block the app and users will see security warnings or be prompted for their password.

## Manual Installation

For manual installation, always remind users to run:

```bash
xattr -cr /Applications/DodoCount.app
```

After dragging the app to Applications folder.
