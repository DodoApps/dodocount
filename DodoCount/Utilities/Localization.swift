import Foundation

/// Localization helper for DodoCount
extension String {
    /// Returns a localized string for the given key
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns a localized string with format arguments
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

/// Localization keys organized by category
enum L10n {
    // MARK: - App
    enum App {
        static let name = "app.name".localized
        static func version(_ v: String) -> String { "app.version".localized(v) }
        static let copyright = "app.copyright".localized
        static let tagline = "app.tagline".localized
        static let description = "app.description".localized
    }

    // MARK: - Menu Bar
    enum MenuBar {
        static func updated(_ time: String) -> String { "menubar.updated".localized(time) }
        static let justNow = "menubar.just_now".localized
        static func minutesAgo(_ m: Int) -> String { "menubar.minutes_ago".localized(m) }
        static func hoursAgo(_ h: Int) -> String { "menubar.hours_ago".localized(h) }
        static let refresh = "menubar.refresh".localized
        static let settings = "menubar.settings".localized
        static let quit = "menubar.quit".localized
    }

    // MARK: - Realtime
    enum Realtime {
        static let title = "realtime.title".localized
        static let activeUsers = "realtime.active_users".localized
    }

    // MARK: - Goal
    enum Goal {
        static let title = "goal.title".localized
        static func progress(_ current: Int, _ goal: Int) -> String { "goal.progress".localized(current, goal) }
        static let achieved = "goal.achieved".localized
    }

    // MARK: - Alerts
    enum Alerts {
        static let title = "alerts.title".localized
        static let noAlerts = "alerts.no_alerts".localized
        static func spike(_ users: Int) -> String { "alerts.spike".localized(users) }
        static func drop(_ users: Int) -> String { "alerts.drop".localized(users) }
        static let goalReached = "alerts.goal_reached".localized
        static func threshold(_ users: Int) -> String { "alerts.threshold".localized(users) }
    }

    // MARK: - Metrics
    enum Metrics {
        static let title = "metrics.title".localized
        static let users = "metrics.users".localized
        static let sessions = "metrics.sessions".localized
        static let pageviews = "metrics.pageviews".localized
        static let bounceRate = "metrics.bounce_rate".localized
        static let avgDuration = "metrics.avg_duration".localized
        static let today = "metrics.today".localized
        static let yesterday = "metrics.yesterday".localized
    }

    // MARK: - Extended Metrics
    enum Extended {
        static let title = "extended.title".localized
        static let users = "extended.users".localized
        static let sessions = "extended.sessions".localized
        static let pageviews = "extended.pageviews".localized
        static let avgDuration = "extended.avg_duration".localized
    }

    // MARK: - Pages
    enum Pages {
        static let title = "pages.title".localized
        static func views(_ count: Int) -> String { "pages.views".localized(count) }
    }

    // MARK: - Sources
    enum Sources {
        static let title = "sources.title".localized
    }

    // MARK: - Countries
    enum Countries {
        static let title = "countries.title".localized
    }

    // MARK: - Devices
    enum Devices {
        static let title = "devices.title".localized
        static let desktop = "devices.desktop".localized
        static let mobile = "devices.mobile".localized
        static let tablet = "devices.tablet".localized
    }

    // MARK: - Search Console
    enum Search {
        static let title = "search.title".localized
        static let clicks = "search.clicks".localized
        static let impressions = "search.impressions".localized
        static let ctr = "search.ctr".localized
        static let position = "search.position".localized
        static let topQueries = "search.top_queries".localized
        static let selectSite = "search.select_site".localized
    }

    // MARK: - Settings
    enum Settings {
        static let title = "settings.title".localized
        static let general = "settings.general".localized
        static let about = "settings.about".localized
        static let reset = "settings.reset".localized

        // Google Cloud
        static let googleCloud = "settings.google_cloud".localized
        static let clientId = "settings.client_id".localized
        static let clientIdHint = "settings.client_id_hint".localized
        static let openConsole = "settings.open_console".localized

        // Account
        static let account = "settings.account".localized
        static let connected = "settings.connected".localized
        static let notConnected = "settings.not_connected".localized
        static let signIn = "settings.sign_in".localized
        static let disconnect = "settings.disconnect".localized
        static let signInHint = "settings.sign_in_hint".localized
        static let clientIdRequired = "settings.client_id_required".localized

        // Property
        static let property = "settings.property".localized
        static let selectedProperty = "settings.selected_property".localized

        // Refresh
        static let refreshInterval = "settings.refresh_interval".localized

        // Menubar
        static let menubarDisplay = "settings.menubar_display".localized
        static let displayIconOnly = "settings.display_icon_only".localized
        static let displayIconNumber = "settings.display_icon_number".localized
        static let displayNumberOnly = "settings.display_number_only".localized

        // Appearance
        static let appearance = "settings.appearance".localized
        static let appearanceSystem = "settings.appearance_system".localized
        static let appearanceLight = "settings.appearance_light".localized
        static let appearanceDark = "settings.appearance_dark".localized

        // Startup
        static let startup = "settings.startup".localized
        static let launchAtLogin = "settings.launch_at_login".localized
    }

    // MARK: - Share
    enum Share {
        static let copyStats = "share.copy_stats".localized
        static let quick = "share.quick".localized
        static let detailed = "share.detailed".localized
        static let slack = "share.slack".localized
    }

    // MARK: - Errors
    enum Error {
        static let notAuthenticated = "error.not_authenticated".localized
        static let apiFailed = "error.api_failed".localized
        static let tokenRefresh = "error.token_refresh".localized
    }
}
