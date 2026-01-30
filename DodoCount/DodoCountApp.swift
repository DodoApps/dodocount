import SwiftUI
import AppKit

@main
struct DodoCountApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var analyticsService: AnalyticsService!
    private var alertService: AlertService!
    private var previousActiveUsers: Int = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services (they handle their own auth-based data fetching)
        analyticsService = AnalyticsService.shared
        alertService = AlertService.shared

        // Set activation policy to accessory (menubar only)
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar
        setupMenuBar()

        // Apply appearance
        SettingsManager.shared.applyAppearance()

        // Setup hotkey
        HotkeyService.shared.onTogglePopover = { [weak self] in
            self?.togglePopover()
        }
        HotkeyService.shared.registerHotkey()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar app should stay running even when all windows are closed
        return false
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateMenuBarButton()
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 720)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarView())

        // Create right-click menu
        setupContextMenu()

        // Observe analytics changes to update menubar
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuBarButton),
            name: NSNotification.Name("AnalyticsUpdated"),
            object: nil
        )

        // Start a timer to update the menubar button and check alerts
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentUsers = self.analyticsService.realtime.activeUsers
            self.updateMenuBarButton()

            // Check alert thresholds
            self.alertService.checkThresholds(activeUsers: currentUsers, previousUsers: self.previousActiveUsers)
            self.previousActiveUsers = currentUsers

            // Check goal progress
            self.alertService.checkGoalProgress(todayUsers: Int(self.analyticsService.daily.users.today))
        }
    }

    @objc private func updateMenuBarButton() {
        guard let button = statusItem.button else { return }

        let displayMode = SettingsManager.shared.settings.menubarDisplayMode
        let isConnected = analyticsService.isConnected
        let isAuthenticated = GoogleAuthService.shared.isAuthenticated
        let activeUsers = analyticsService.realtime.activeUsers

        // Determine what to display
        let displayValue: String
        if !isAuthenticated {
            displayValue = "-"  // Not signed in
        } else if !isConnected {
            displayValue = "X"  // Signed in but server unreachable
        } else {
            displayValue = "\(activeUsers)"
        }

        switch displayMode {
        case .iconOnly:
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            if let image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "DodoCount")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
            button.title = ""

        case .iconAndNumber:
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            if let image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "DodoCount")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
            button.title = " \(displayValue)"
            button.imagePosition = .imageLeading

        case .numberOnly:
            button.image = nil
            button.title = displayValue
        }
    }

    private func setupContextMenu() {
        // Context menu is shown on right-click
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        // Copy stats submenu
        let copyMenu = NSMenu()
        let copyQuickItem = NSMenuItem(title: "Quick stats", action: #selector(copyQuickStats), keyEquivalent: "")
        let copyDetailedItem = NSMenuItem(title: "Detailed stats", action: #selector(copyDetailedStats), keyEquivalent: "")
        let copySlackItem = NSMenuItem(title: "Slack format", action: #selector(copySlackStats), keyEquivalent: "")

        copyQuickItem.target = self
        copyDetailedItem.target = self
        copySlackItem.target = self

        copyMenu.addItem(copyQuickItem)
        copyMenu.addItem(copyDetailedItem)
        copyMenu.addItem(copySlackItem)

        let copyMenuItem = NSMenuItem(title: "Copy stats", action: nil, keyEquivalent: "c")
        copyMenuItem.submenu = copyMenu
        menu.addItem(copyMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Refresh item
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshData), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Appearance submenu
        let appearanceMenu = NSMenu()
        let darkItem = NSMenuItem(title: "Dark", action: #selector(setDarkMode), keyEquivalent: "")
        let lightItem = NSMenuItem(title: "Light", action: #selector(setLightMode), keyEquivalent: "")
        let systemItem = NSMenuItem(title: "System", action: #selector(setSystemMode), keyEquivalent: "")

        darkItem.target = self
        lightItem.target = self
        systemItem.target = self

        updateAppearanceMenuItems(darkItem: darkItem, lightItem: lightItem, systemItem: systemItem)

        appearanceMenu.addItem(darkItem)
        appearanceMenu.addItem(lightItem)
        appearanceMenu.addItem(systemItem)

        let appearanceMenuItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        appearanceMenuItem.submenu = appearanceMenu
        menu.addItem(appearanceMenuItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit DodoCount", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func updateAppearanceMenuItems(darkItem: NSMenuItem, lightItem: NSMenuItem, systemItem: NSMenuItem) {
        let currentMode = SettingsManager.shared.settings.appearanceMode
        darkItem.state = currentMode == .dark ? .on : .off
        lightItem.state = currentMode == .light ? .on : .off
        systemItem.state = currentMode == .system ? .on : .off
    }

    @objc private func refreshData() {
        analyticsService.refreshData()
        SearchConsoleService.shared.refreshData()
    }

    @objc private func copyQuickStats() {
        ShareService.shared.copyQuickStats()
    }

    @objc private func copyDetailedStats() {
        ShareService.shared.copyDetailedStats()
    }

    @objc private func copySlackStats() {
        ShareService.shared.copySlackStats()
    }

    @objc private func setDarkMode() {
        SettingsManager.shared.settings.appearanceMode = .dark
    }

    @objc private func setLightMode() {
        SettingsManager.shared.settings.appearanceMode = .light
    }

    @objc private func setSystemMode() {
        SettingsManager.shared.settings.appearanceMode = .system
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc func closePopover() {
        popover.performClose(nil)
    }

    @objc func openSettingsWindow() {
        // Close popover if open
        if popover.isShown {
            popover.performClose(nil)
        }

        // Create or show settings window
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "DodoCount Settings"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Appearance Extension
extension View {
    func applyAppTheme() -> some View {
        self.preferredColorScheme(SettingsManager.shared.settings.appearanceMode.colorScheme)
    }
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
