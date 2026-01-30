import Foundation
import AppKit

class ShareService {
    static let shared = ShareService()

    private init() {}

    // MARK: - Copy Stats to Clipboard

    func copyQuickStats() {
        let analytics = AnalyticsService.shared
        let settings = SettingsManager.shared.settings

        let propertyName = analytics.selectedProperty?.shortName ?? "My Site"
        let activeUsers = analytics.realtime.activeUsers
        let todayUsers = Int(analytics.daily.users.today)
        let userChange = analytics.daily.users.percentChange

        let changeSymbol = userChange >= 0 ? "↑" : "↓"
        let changeText = String(format: "%.1f%%", abs(userChange))

        let text = "📊 \(propertyName)\n👥 \(activeUsers) active now\n📈 \(todayUsers) today (\(changeSymbol)\(changeText))"

        copyToClipboard(text)
    }

    func copyDetailedStats() {
        let analytics = AnalyticsService.shared

        let propertyName = analytics.selectedProperty?.shortName ?? "My Site"
        let activeUsers = analytics.realtime.activeUsers
        let daily = analytics.daily

        let usersChange = formatChange(daily.users.percentChange)
        let sessionsChange = formatChange(daily.sessions.percentChange)
        let pageviewsChange = formatChange(daily.pageviews.percentChange)

        let topPage = analytics.topPages.first?.path ?? "/"
        let topPageViews = analytics.topPages.first.map { AnalyticsService.formatNumber(Double($0.views)) } ?? "0"

        let topSource = analytics.trafficSources.first?.displayName ?? "Direct"
        let topSourcePercent = analytics.trafficSources.first.map { String(format: "%.0f%%", $0.percentage) } ?? "0%"

        let text = """
📊 \(propertyName) - Analytics Update

🔴 Realtime: \(activeUsers) active users

📈 Today vs Yesterday:
• Users: \(AnalyticsService.formatNumber(daily.users.today)) (\(usersChange))
• Sessions: \(AnalyticsService.formatNumber(daily.sessions.today)) (\(sessionsChange))
• Pageviews: \(AnalyticsService.formatNumber(daily.pageviews.today)) (\(pageviewsChange))

🏆 Top page: \(topPage) (\(topPageViews) views)
🔗 Top source: \(topSource) (\(topSourcePercent))
"""

        copyToClipboard(text)
    }

    func copyRealtimeOnly() {
        let analytics = AnalyticsService.shared
        let propertyName = analytics.selectedProperty?.shortName ?? "My Site"
        let activeUsers = analytics.realtime.activeUsers

        let text = "👥 \(propertyName): \(activeUsers) active users right now"
        copyToClipboard(text)
    }

    // MARK: - Slack Format

    func copySlackStats() {
        let analytics = AnalyticsService.shared

        let propertyName = analytics.selectedProperty?.shortName ?? "My Site"
        let activeUsers = analytics.realtime.activeUsers
        let todayUsers = Int(analytics.daily.users.today)
        let userChange = analytics.daily.users.percentChange
        let changeEmoji = userChange >= 0 ? ":chart_with_upwards_trend:" : ":chart_with_downwards_trend:"

        let text = ":bar_chart: *\(propertyName) Update*\n:busts_in_silhouette: *\(activeUsers)* active now\n\(changeEmoji) *\(todayUsers)* users today (\(formatChange(userChange)))"

        copyToClipboard(text)
    }

    // MARK: - Helpers

    private func formatChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Show confirmation in menubar (brief flash or sound)
        NSSound(named: "Pop")?.play()
    }
}

// MARK: - Share Menu
enum ShareFormat: String, CaseIterable {
    case quick = "Quick stats"
    case detailed = "Detailed stats"
    case realtime = "Realtime only"
    case slack = "Slack format"

    var icon: String {
        switch self {
        case .quick: return "doc.on.clipboard"
        case .detailed: return "doc.text"
        case .realtime: return "person.2"
        case .slack: return "number.square"
        }
    }

    func copy() {
        switch self {
        case .quick: ShareService.shared.copyQuickStats()
        case .detailed: ShareService.shared.copyDetailedStats()
        case .realtime: ShareService.shared.copyRealtimeOnly()
        case .slack: ShareService.shared.copySlackStats()
        }
    }
}
