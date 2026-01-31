import Foundation

/// Date formatting utilities used across the app
enum DateUtilities {
    /// Format a date as relative time (e.g., "just now", "5m ago", "2h ago")
    static func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 {
            return L10n.MenuBar.justNow
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return L10n.MenuBar.minutesAgo(minutes)
        } else {
            let hours = seconds / 3600
            return L10n.MenuBar.hoursAgo(hours)
        }
    }

    /// Format a date as compact relative time (e.g., "now", "5m", "2h", "3d")
    static func timeAgoCompact(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h"
        } else {
            return "\(seconds / 86400)d"
        }
    }

    /// Calculate date range for API requests
    /// Returns (startDate, endDate) tuple or nil if calculation fails
    static func dateRange(daysBack: Int, from date: Date = Date()) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: date),
              let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate) else {
            return nil
        }
        return (startDate, endDate)
    }
}
