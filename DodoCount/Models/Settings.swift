import Foundation

/// App settings model for DodoCount
struct AppSettings: Codable {
    var selectedPropertyId: String?
    var refreshInterval: RefreshInterval
    var appearanceMode: AppearanceMode
    var launchAtLogin: Bool
    var menubarDisplayMode: MenubarDisplayMode

    // Google OAuth
    var googleClientId: String

    // Alerts
    var alertsEnabled: Bool
    var alertThresholdHigh: Int
    var alertThresholdLow: Int
    var alertOnTrafficSpike: Bool
    var alertOnTrafficDrop: Bool

    // Goals
    var dailyUserGoal: Int
    var showGoalProgress: Bool

    // Keyboard shortcut
    var globalHotkeyEnabled: Bool

    static var `default`: AppSettings {
        AppSettings(
            selectedPropertyId: nil,
            refreshInterval: .thirtySeconds,
            appearanceMode: .dark,
            launchAtLogin: false,
            menubarDisplayMode: .iconAndNumber,
            googleClientId: "",
            alertsEnabled: true,
            alertThresholdHigh: 500,
            alertThresholdLow: 10,
            alertOnTrafficSpike: true,
            alertOnTrafficDrop: true,
            dailyUserGoal: 1000,
            showGoalProgress: true,
            globalHotkeyEnabled: true
        )
    }
}

/// Refresh interval for analytics data
enum RefreshInterval: String, Codable, CaseIterable {
    case fifteenSeconds = "15s"
    case thirtySeconds = "30s"
    case oneMinute = "1m"
    case fiveMinutes = "5m"

    var seconds: TimeInterval {
        switch self {
        case .fifteenSeconds: return 15
        case .thirtySeconds: return 30
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        }
    }

    var displayName: String {
        switch self {
        case .fifteenSeconds: return "15 seconds"
        case .thirtySeconds: return "30 seconds"
        case .oneMinute: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        }
    }
}

/// App appearance mode
enum AppearanceMode: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        }
    }
}

/// Menubar display mode
enum MenubarDisplayMode: String, Codable, CaseIterable {
    case iconOnly = "Icon only"
    case iconAndNumber = "Icon + number"
    case numberOnly = "Number only"

    var displayName: String {
        rawValue
    }
}
