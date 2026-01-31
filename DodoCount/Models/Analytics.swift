import Foundation

/// Represents a Google Analytics 4 property
struct GA4Property: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let websiteUrl: String?

    var shortName: String {
        if let url = websiteUrl {
            return url.replacingOccurrences(of: "https://", with: "")
                      .replacingOccurrences(of: "http://", with: "")
                      .replacingOccurrences(of: "www.", with: "")
        }
        return displayName
    }
}

/// Real-time analytics data
struct RealtimeData {
    let activeUsers: Int
    let sparklineHistory: [Int]

    static var empty: RealtimeData {
        RealtimeData(activeUsers: 0, sparklineHistory: [])
    }
}

/// Daily metrics comparison (today vs yesterday)
struct DailyMetrics {
    let users: MetricComparison
    let sessions: MetricComparison
    let pageviews: MetricComparison
    let bounceRate: MetricComparison
    let avgSessionDuration: MetricComparison

    static var empty: DailyMetrics {
        DailyMetrics(
            users: .empty,
            sessions: .empty,
            pageviews: .empty,
            bounceRate: .empty,
            avgSessionDuration: .empty
        )
    }
}

/// Comparison between today and yesterday values
struct MetricComparison {
    let today: Double
    let yesterday: Double

    var percentChange: Double {
        guard yesterday > 0 else { return today > 0 ? 100 : 0 }
        return ((today - yesterday) / yesterday) * 100
    }

    var isPositive: Bool {
        percentChange >= 0
    }

    static var empty: MetricComparison {
        MetricComparison(today: 0, yesterday: 0)
    }
}

/// Top page data
struct TopPage: Identifiable {
    let id = UUID()
    let path: String
    let title: String
    let views: Int
}

/// Traffic source data
struct TrafficSource: Identifiable {
    let id = UUID()
    let source: String
    let medium: String
    let percentage: Double

    var displayName: String {
        if source == "(direct)" {
            return "Direct"
        }
        return source
    }

    var color: SourceColor {
        switch medium.lowercased() {
        case "organic":
            return .organic
        case "social":
            return .social
        case "email":
            return .email
        case "(none)":
            return .direct
        default:
            return .other
        }
    }

    enum SourceColor {
        case organic, direct, social, email, other

        var name: String {
            switch self {
            case .organic: return "purple"
            case .direct: return "blue"
            case .social: return "cyan"
            case .email: return "orange"
            case .other: return "gray"
            }
        }
    }
}

/// Country data
struct CountryData: Identifiable {
    let id = UUID()
    let countryCode: String
    let countryName: String
    let users: Int
    let percentage: Double

    var flag: String {
        // Handle empty or invalid country codes
        guard countryCode.count == 2 else { return "🌍" }

        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            // Only process ASCII letters (A-Z)
            guard scalar.value >= 65 && scalar.value <= 90 else { return "🌍" }
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag.isEmpty ? "🌍" : flag
    }
}

/// Device breakdown data
struct DeviceBreakdown {
    let desktop: Double
    let mobile: Double
    let tablet: Double

    static var empty: DeviceBreakdown {
        DeviceBreakdown(desktop: 0, mobile: 0, tablet: 0)
    }
}

// MARK: - 28-Day Metrics

/// Extended metrics for 28-day period (like GA4 overview)
struct ExtendedMetrics {
    let activeUsers28Day: MetricComparison
    let eventCount: MetricComparison
    let pageviews: MetricComparison
    let trendData: [TrendDataPoint]

    static var empty: ExtendedMetrics {
        ExtendedMetrics(
            activeUsers28Day: .empty,
            eventCount: .empty,
            pageviews: .empty,
            trendData: []
        )
    }
}

/// Data point for trend charts
struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let previousValue: Double? // For comparison with previous period
}

// MARK: - Search Console Models

/// Google Search Console site
struct SearchConsoleSite: Identifiable, Codable, Hashable {
    let siteUrl: String
    let permissionLevel: String

    var id: String { siteUrl }

    var displayName: String {
        siteUrl.replacingOccurrences(of: "sc-domain:", with: "")
               .replacingOccurrences(of: "https://", with: "")
               .replacingOccurrences(of: "http://", with: "")
    }
}

/// Search Console performance metrics
struct SearchConsoleMetrics {
    let clicks: MetricComparison
    let impressions: MetricComparison
    let ctr: MetricComparison  // Click-through rate (as percentage)
    let position: MetricComparison  // Average position
    let trendData: [SearchConsoleTrendPoint]

    static var empty: SearchConsoleMetrics {
        SearchConsoleMetrics(
            clicks: .empty,
            impressions: .empty,
            ctr: .empty,
            position: .empty,
            trendData: []
        )
    }
}

/// Trend data point for Search Console
struct SearchConsoleTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let clicks: Int
    let impressions: Int
    let ctr: Double
    let position: Double
}

/// Top search queries
struct SearchQuery: Identifiable {
    let id = UUID()
    let query: String
    let clicks: Int
    let impressions: Int
    let ctr: Double
    let position: Double
}

/// Top pages in search results
struct SearchPage: Identifiable {
    let id = UUID()
    let page: String
    let clicks: Int
    let impressions: Int
    let ctr: Double
    let position: Double

    var shortPath: String {
        if let url = URL(string: page) {
            return url.path.isEmpty ? "/" : url.path
        }
        return page
    }
}

/// Complete analytics snapshot
struct AnalyticsSnapshot {
    let property: GA4Property
    let realtime: RealtimeData
    let daily: DailyMetrics
    let topPages: [TopPage]
    let trafficSources: [TrafficSource]
    let countries: [CountryData]
    let devices: DeviceBreakdown
    let lastUpdated: Date
}
