import Foundation
import UserNotifications
import AppKit

class AlertService: ObservableObject {
    static let shared = AlertService()

    @Published var recentAlerts: [AlertItem] = []
    @Published var hasUnreadAlerts: Bool = false

    private var lastHighAlertTime: Date?
    private var lastLowAlertTime: Date?
    private let alertCooldown: TimeInterval = 300 // 5 minutes between same alerts

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Permission

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // MARK: - Check Thresholds

    func checkThresholds(activeUsers: Int, previousUsers: Int) {
        let settings = SettingsManager.shared.settings
        guard settings.alertsEnabled else { return }

        // Check high threshold
        if settings.alertOnTrafficSpike && activeUsers >= settings.alertThresholdHigh {
            if shouldSendAlert(lastAlertTime: lastHighAlertTime) {
                sendTrafficSpikeAlert(users: activeUsers)
                lastHighAlertTime = Date()
            }
        }

        // Check low threshold
        if settings.alertOnTrafficDrop && activeUsers <= settings.alertThresholdLow && previousUsers > settings.alertThresholdLow {
            if shouldSendAlert(lastAlertTime: lastLowAlertTime) {
                sendTrafficDropAlert(users: activeUsers)
                lastLowAlertTime = Date()
            }
        }

        // Check for sudden spike (50% increase)
        if settings.alertOnTrafficSpike && previousUsers > 0 {
            let percentIncrease = Double(activeUsers - previousUsers) / Double(previousUsers) * 100
            if percentIncrease >= 50 && activeUsers > 50 {
                if shouldSendAlert(lastAlertTime: lastHighAlertTime) {
                    sendSuddenSpikeAlert(users: activeUsers, percentIncrease: Int(percentIncrease))
                    lastHighAlertTime = Date()
                }
            }
        }

        // Check for sudden drop (50% decrease)
        if settings.alertOnTrafficDrop && previousUsers > 0 {
            let percentDecrease = Double(previousUsers - activeUsers) / Double(previousUsers) * 100
            if percentDecrease >= 50 && previousUsers > 50 {
                if shouldSendAlert(lastAlertTime: lastLowAlertTime) {
                    sendSuddenDropAlert(users: activeUsers, percentDecrease: Int(percentDecrease))
                    lastLowAlertTime = Date()
                }
            }
        }
    }

    private func shouldSendAlert(lastAlertTime: Date?) -> Bool {
        guard let lastTime = lastAlertTime else { return true }
        return Date().timeIntervalSince(lastTime) >= alertCooldown
    }

    // MARK: - Send Alerts

    private func sendTrafficSpikeAlert(users: Int) {
        let alert = AlertItem(
            type: .spike,
            title: "Traffic spike!",
            message: "You have \(users) active users right now",
            timestamp: Date()
        )
        addAlert(alert)
        sendNotification(title: alert.title, body: alert.message)
    }

    private func sendTrafficDropAlert(users: Int) {
        let alert = AlertItem(
            type: .drop,
            title: "Low traffic",
            message: "Only \(users) active users - is everything OK?",
            timestamp: Date()
        )
        addAlert(alert)
        sendNotification(title: alert.title, body: alert.message)
    }

    private func sendSuddenSpikeAlert(users: Int, percentIncrease: Int) {
        let alert = AlertItem(
            type: .spike,
            title: "You're trending!",
            message: "Traffic up \(percentIncrease)% - \(users) users now",
            timestamp: Date()
        )
        addAlert(alert)
        sendNotification(title: alert.title, body: alert.message)
    }

    private func sendSuddenDropAlert(users: Int, percentDecrease: Int) {
        let alert = AlertItem(
            type: .drop,
            title: "Traffic dropped",
            message: "Down \(percentDecrease)% to \(users) users",
            timestamp: Date()
        )
        addAlert(alert)
        sendNotification(title: alert.title, body: alert.message)
    }

    // MARK: - Goal Alerts

    func checkGoalProgress(todayUsers: Int) {
        let settings = SettingsManager.shared.settings
        guard settings.showGoalProgress else { return }

        let goal = settings.dailyUserGoal
        let progress = Double(todayUsers) / Double(goal)

        // Alert at 50%, 100%, and 150%
        if progress >= 1.5 && !hasRecentAlert(ofType: .goalExceeded) {
            let alert = AlertItem(
                type: .goalExceeded,
                title: "Goal crushed!",
                message: "150% of daily goal reached (\(todayUsers)/\(goal))",
                timestamp: Date()
            )
            addAlert(alert)
            sendNotification(title: alert.title, body: alert.message)
        } else if progress >= 1.0 && !hasRecentAlert(ofType: .goalReached) {
            let alert = AlertItem(
                type: .goalReached,
                title: "Goal reached!",
                message: "Daily goal of \(goal) users achieved!",
                timestamp: Date()
            )
            addAlert(alert)
            sendNotification(title: alert.title, body: alert.message)
        }
    }

    private func hasRecentAlert(ofType type: AlertType) -> Bool {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return recentAlerts.contains { $0.type == type && $0.timestamp > oneHourAgo }
    }

    // MARK: - Alert Management

    private func addAlert(_ alert: AlertItem) {
        DispatchQueue.main.async {
            self.recentAlerts.insert(alert, at: 0)
            self.hasUnreadAlerts = true

            // Keep only last 20 alerts
            if self.recentAlerts.count > 20 {
                self.recentAlerts = Array(self.recentAlerts.prefix(20))
            }
        }
    }

    func markAllAsRead() {
        hasUnreadAlerts = false
    }

    func clearAlerts() {
        recentAlerts.removeAll()
        hasUnreadAlerts = false
    }

    // MARK: - System Notification

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Alert Models

struct AlertItem: Identifiable {
    let id = UUID()
    let type: AlertType
    let title: String
    let message: String
    let timestamp: Date

    var icon: String {
        type.icon
    }

    var color: String {
        type.color
    }
}

enum AlertType {
    case spike
    case drop
    case goalReached
    case goalExceeded

    var icon: String {
        switch self {
        case .spike: return "arrow.up.right.circle.fill"
        case .drop: return "arrow.down.right.circle.fill"
        case .goalReached: return "flag.checkered"
        case .goalExceeded: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .spike, .goalReached, .goalExceeded: return "green"
        case .drop: return "red"
        }
    }
}
