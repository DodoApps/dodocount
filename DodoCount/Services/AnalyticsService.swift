import Foundation
import Combine

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    // MARK: - Published Properties
    @Published var properties: [GA4Property] = []
    @Published var selectedProperty: GA4Property?
    @Published var realtime: RealtimeData = .empty
    @Published var daily: DailyMetrics = .empty
    @Published var extended: ExtendedMetrics = .empty  // 28-day metrics
    @Published var topPages: [TopPage] = []
    @Published var trafficSources: [TrafficSource] = []
    @Published var countries: [CountryData] = []
    @Published var devices: DeviceBreakdown = .empty
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isConnected: Bool = false  // True when successfully fetched data

    private var refreshTimer: Timer?
    private var sparklineHistory: [Int] = []
    private let maxSparklinePoints = 30
    private var authObserver: NSObjectProtocol?

    // GA4 API endpoints
    private let adminAPIBase = "https://analyticsadmin.googleapis.com/v1beta"
    private let dataAPIBase = "https://analyticsdata.googleapis.com/v1beta"

    private init() {
        startRefreshTimer()

        // Observe authentication changes
        observeAuthChanges()

        // Check authentication after a brief delay to ensure GoogleAuthService has loaded tokens
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if GoogleAuthService.shared.isAuthenticated {
                Task {
                    await self?.fetchRealData()
                }
            }
        }
    }

    private func observeAuthChanges() {
        // Observe changes to GoogleAuthService.isAuthenticated
        authObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GoogleAuthStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if GoogleAuthService.shared.isAuthenticated {
                // Clear and fetch real data
                self?.properties = []
                self?.selectedProperty = nil
                self?.sparklineHistory = []
                self?.isConnected = false
                Task {
                    await self?.fetchRealData()
                }
            } else {
                // Clear all data when signed out
                self?.clearAllData()
            }
        }
    }

    private func clearAllData() {
        properties = []
        selectedProperty = nil
        realtime = .empty
        daily = .empty
        extended = .empty
        topPages = []
        trafficSources = []
        countries = []
        devices = .empty
        sparklineHistory = []
        isConnected = false
        error = nil
    }

    deinit {
        if let observer = authObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    func selectProperty(_ property: GA4Property) {
        selectedProperty = property
        SettingsManager.shared.settings.selectedPropertyId = property.id
        refreshData()
    }

    func refreshData() {
        // Prevent overlapping refreshes
        guard !isLoading else { return }

        if GoogleAuthService.shared.isAuthenticated {
            Task {
                await fetchRealData()
            }
        }
        // No action if not authenticated - user must sign in first
    }

    // MARK: - Real GA4 API Methods

    @MainActor
    func fetchRealData() async {
        isLoading = true
        error = nil

        do {
            // Fetch properties if empty
            if properties.isEmpty {
                try await fetchProperties()
            }

            guard let property = selectedProperty else {
                isLoading = false
                return
            }

            // Fetch all data in parallel
            async let realtimeTask = fetchRealtimeData(propertyId: property.id)
            async let dailyTask = fetchDailyMetrics(propertyId: property.id)
            async let extendedTask = fetchExtendedMetrics(propertyId: property.id)
            async let pagesTask = fetchTopPages(propertyId: property.id)
            async let sourcesTask = fetchTrafficSources(propertyId: property.id)
            async let countriesTask = fetchCountries(propertyId: property.id)
            async let devicesTask = fetchDevices(propertyId: property.id)

            let (realtimeResult, dailyResult, extendedResult, pagesResult, sourcesResult, countriesResult, devicesResult) =
                try await (realtimeTask, dailyTask, extendedTask, pagesTask, sourcesTask, countriesTask, devicesTask)

            realtime = realtimeResult
            daily = dailyResult
            extended = extendedResult
            topPages = pagesResult
            trafficSources = sourcesResult
            countries = countriesResult
            devices = devicesResult

            // Update sparkline history
            sparklineHistory.append(realtimeResult.activeUsers)
            if sparklineHistory.count > maxSparklinePoints {
                sparklineHistory.removeFirst()
            }
            realtime = RealtimeData(activeUsers: realtimeResult.activeUsers, sparklineHistory: sparklineHistory)

            lastUpdated = Date()
            isConnected = true
            error = nil
        } catch {
            self.error = error.localizedDescription
            isConnected = false
        }

        isLoading = false
    }

    private func fetchProperties() async throws {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(adminAPIBase)/accountSummaries") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalyticsError.apiError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            throw AnalyticsError.apiError("Failed to fetch properties: \(httpResponse.statusCode)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let accountSummaries = json?["accountSummaries"] as? [[String: Any]] ?? []

        var fetchedProperties: [GA4Property] = []

        for account in accountSummaries {
            let propertySummaries = account["propertySummaries"] as? [[String: Any]] ?? []
            for prop in propertySummaries {
                if let property = prop["property"] as? String,
                   let displayName = prop["displayName"] as? String {
                    fetchedProperties.append(GA4Property(
                        id: property,
                        displayName: displayName,
                        websiteUrl: nil
                    ))
                }
            }
        }

        // Already on MainActor, no need for MainActor.run
        self.properties = fetchedProperties

        // Select first property if none selected
        if selectedProperty == nil {
            if let savedId = SettingsManager.shared.settings.selectedPropertyId,
               let saved = fetchedProperties.first(where: { $0.id == savedId }) {
                selectedProperty = saved
            } else {
                selectedProperty = fetchedProperties.first
            }
        }
    }

    private func fetchRealtimeData(propertyId: String) async throws -> RealtimeData {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runRealtimeReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "metrics": [["name": "activeUsers"]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch realtime data")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []
        let activeUsers = rows.first?["metricValues"] as? [[String: Any]]
        let value = activeUsers?.first?["value"] as? String ?? "0"

        return RealtimeData(activeUsers: Int(value) ?? 0, sparklineHistory: sparklineHistory)
    }

    private func fetchExtendedMetrics(propertyId: String) async throws -> ExtendedMetrics {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        // Date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Current 28-day period
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -28, to: endDate),
              let prevEndDate = calendar.date(byAdding: .day, value: -1, to: startDate),
              let prevStartDate = calendar.date(byAdding: .day, value: -28, to: prevEndDate) else {
            throw AnalyticsError.apiError("Failed to calculate date range")
        }

        // Fetch current period with daily breakdown
        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "dateRanges": [
                ["startDate": dateFormatter.string(from: startDate), "endDate": dateFormatter.string(from: endDate)],
                ["startDate": dateFormatter.string(from: prevStartDate), "endDate": dateFormatter.string(from: prevEndDate)]
            ],
            "dimensions": [["name": "date"]],
            "metrics": [
                ["name": "active28DayUsers"],
                ["name": "eventCount"],
                ["name": "screenPageViews"]
            ],
            "orderBys": [["dimension": ["dimensionName": "date"]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch extended metrics")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []

        // Aggregate current and previous period
        var currentUsers = 0.0
        var currentEvents = 0.0
        var currentPageviews = 0.0
        var prevUsers = 0.0
        var prevEvents = 0.0
        var prevPageviews = 0.0
        var trendData: [TrendDataPoint] = []

        for row in rows {
            let dimensionValues = row["dimensionValues"] as? [[String: Any]] ?? []
            let metricValues = row["metricValues"] as? [[String: Any]] ?? []

            // GA4 API returns date in first dimension, dateRange indicator may be separate
            let dateStr = dimensionValues.first?["value"] as? String ?? ""

            let users = Double(metricValues[safe: 0]?["value"] as? String ?? "0") ?? 0
            let events = Double(metricValues[safe: 1]?["value"] as? String ?? "0") ?? 0
            let pageviews = Double(metricValues[safe: 2]?["value"] as? String ?? "0") ?? 0

            // Check if date is in current period (last 28 days) or previous period
            if let date = dateFormatter.date(from: dateStr) {
                if date >= startDate && date <= endDate {
                    currentUsers += users
                    currentEvents += events
                    currentPageviews += pageviews
                    trendData.append(TrendDataPoint(date: date, value: users, previousValue: nil))
                } else if date >= prevStartDate && date <= prevEndDate {
                    prevUsers += users
                    prevEvents += events
                    prevPageviews += pageviews
                }
            }
        }

        return ExtendedMetrics(
            activeUsers28Day: MetricComparison(today: currentUsers, yesterday: prevUsers),
            eventCount: MetricComparison(today: currentEvents, yesterday: prevEvents),
            pageviews: MetricComparison(today: currentPageviews, yesterday: prevPageviews),
            trendData: trendData.sorted { $0.date < $1.date }
        )
    }

    private func fetchDailyMetrics(propertyId: String) async throws -> DailyMetrics {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "dateRanges": [
                ["startDate": "yesterday", "endDate": "yesterday"],
                ["startDate": "today", "endDate": "today"]
            ],
            "metrics": [
                ["name": "activeUsers"],
                ["name": "sessions"],
                ["name": "screenPageViews"],
                ["name": "bounceRate"],
                ["name": "averageSessionDuration"]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch daily metrics")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []

        // Parse yesterday (dateRangeIndex 0) and today (dateRangeIndex 1)
        var yesterday: [Double] = [0, 0, 0, 0, 0]
        var today: [Double] = [0, 0, 0, 0, 0]

        for row in rows {
            let dimensionValues = row["dimensionValues"] as? [[String: Any]] ?? []
            let dateRangeIndex = dimensionValues.first?["value"] as? String ?? "0"
            let metricValues = row["metricValues"] as? [[String: Any]] ?? []

            let values = metricValues.compactMap { ($0["value"] as? String).flatMap { Double($0) } }

            if dateRangeIndex == "date_range_0" {
                yesterday = values
            } else {
                today = values
            }
        }

        return DailyMetrics(
            users: MetricComparison(today: today[safe: 0] ?? 0, yesterday: yesterday[safe: 0] ?? 0),
            sessions: MetricComparison(today: today[safe: 1] ?? 0, yesterday: yesterday[safe: 1] ?? 0),
            pageviews: MetricComparison(today: today[safe: 2] ?? 0, yesterday: yesterday[safe: 2] ?? 0),
            bounceRate: MetricComparison(today: (today[safe: 3] ?? 0) * 100, yesterday: (yesterday[safe: 3] ?? 0) * 100),
            avgSessionDuration: MetricComparison(today: today[safe: 4] ?? 0, yesterday: yesterday[safe: 4] ?? 0)
        )
    }

    private func fetchTopPages(propertyId: String) async throws -> [TopPage] {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "dateRanges": [["startDate": "today", "endDate": "today"]],
            "dimensions": [["name": "pagePath"], ["name": "pageTitle"]],
            "metrics": [["name": "screenPageViews"]],
            "limit": 5,
            "orderBys": [["metric": ["metricName": "screenPageViews"], "desc": true]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch top pages")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []

        return rows.compactMap { row -> TopPage? in
            let dimensions = row["dimensionValues"] as? [[String: Any]] ?? []
            let metrics = row["metricValues"] as? [[String: Any]] ?? []

            guard dimensions.count >= 2,
                  let path = dimensions[0]["value"] as? String,
                  let title = dimensions[1]["value"] as? String,
                  let viewsStr = metrics.first?["value"] as? String,
                  let views = Int(viewsStr) else { return nil }

            return TopPage(path: path, title: title, views: views)
        }
    }

    private func fetchTrafficSources(propertyId: String) async throws -> [TrafficSource] {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "dateRanges": [["startDate": "today", "endDate": "today"]],
            "dimensions": [["name": "sessionSource"], ["name": "sessionMedium"]],
            "metrics": [["name": "sessions"]],
            "limit": 5,
            "orderBys": [["metric": ["metricName": "sessions"], "desc": true]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch traffic sources")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []

        // Calculate total for percentages
        let totalSessions = rows.reduce(0.0) { sum, row in
            let metrics = row["metricValues"] as? [[String: Any]] ?? []
            let sessions = Double(metrics.first?["value"] as? String ?? "0") ?? 0
            return sum + sessions
        }

        return rows.compactMap { row -> TrafficSource? in
            let dimensions = row["dimensionValues"] as? [[String: Any]] ?? []
            let metrics = row["metricValues"] as? [[String: Any]] ?? []

            guard dimensions.count >= 2,
                  let source = dimensions[0]["value"] as? String,
                  let medium = dimensions[1]["value"] as? String,
                  let sessionsStr = metrics.first?["value"] as? String,
                  let sessions = Double(sessionsStr) else { return nil }

            let percentage = totalSessions > 0 ? (sessions / totalSessions) * 100 : 0
            return TrafficSource(source: source, medium: medium, percentage: percentage)
        }
    }

    private func fetchCountries(propertyId: String) async throws -> [CountryData] {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "dateRanges": [["startDate": "today", "endDate": "today"]],
            "dimensions": [["name": "country"], ["name": "countryId"]],
            "metrics": [["name": "activeUsers"]],
            "limit": 5,
            "orderBys": [["metric": ["metricName": "activeUsers"], "desc": true]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch countries")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []

        // Calculate total for percentages
        let totalUsers = rows.reduce(0) { sum, row in
            let metrics = row["metricValues"] as? [[String: Any]] ?? []
            let users = Int(metrics.first?["value"] as? String ?? "0") ?? 0
            return sum + users
        }

        return rows.compactMap { row -> CountryData? in
            let dimensions = row["dimensionValues"] as? [[String: Any]] ?? []
            let metrics = row["metricValues"] as? [[String: Any]] ?? []

            guard dimensions.count >= 2,
                  let countryName = dimensions[0]["value"] as? String,
                  let countryCode = dimensions[1]["value"] as? String,
                  let usersStr = metrics.first?["value"] as? String,
                  let users = Int(usersStr) else { return nil }

            let percentage = totalUsers > 0 ? Double(users) / Double(totalUsers) * 100 : 0
            return CountryData(countryCode: countryCode, countryName: countryName, users: users, percentage: percentage)
        }
    }

    private func fetchDevices(propertyId: String) async throws -> DeviceBreakdown {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(dataAPIBase)/\(propertyId):runReport") else {
            throw AnalyticsError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "dateRanges": [["startDate": "today", "endDate": "today"]],
            "dimensions": [["name": "deviceCategory"]],
            "metrics": [["name": "activeUsers"]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnalyticsError.apiError("Failed to fetch devices")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = json?["rows"] as? [[String: Any]] ?? []

        var deviceMap: [String: Int] = [:]
        var total = 0

        for row in rows {
            let dimensions = row["dimensionValues"] as? [[String: Any]] ?? []
            let metrics = row["metricValues"] as? [[String: Any]] ?? []

            if let device = dimensions.first?["value"] as? String,
               let usersStr = metrics.first?["value"] as? String,
               let users = Int(usersStr) {
                deviceMap[device.lowercased()] = users
                total += users
            }
        }

        let desktop = total > 0 ? Double(deviceMap["desktop"] ?? 0) / Double(total) * 100 : 0
        let mobile = total > 0 ? Double(deviceMap["mobile"] ?? 0) / Double(total) * 100 : 0
        let tablet = total > 0 ? Double(deviceMap["tablet"] ?? 0) / Double(total) * 100 : 0

        return DeviceBreakdown(desktop: desktop, mobile: mobile, tablet: tablet)
    }

    func startRefreshTimer() {
        stopRefreshTimer()

        let interval = SettingsManager.shared.settings.refreshInterval.seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            if GoogleAuthService.shared.isAuthenticated {
                // Fetch real data when authenticated
                self?.refreshData()
            }
            // No action if not authenticated
        }
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Formatting Helpers
extension AnalyticsService {
    static func formatNumber(_ value: Double) -> String {
        // Handle NaN, infinity, or negative values
        guard value.isFinite && value >= 0 else { return "0" }

        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    static func formatDuration(_ seconds: Double) -> String {
        // Handle NaN, infinity, or negative values
        guard seconds.isFinite && seconds >= 0 else { return "0m 00s" }

        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%dm %02ds", minutes, secs)
    }

    static func formatPercentage(_ value: Double) -> String {
        // Handle NaN, infinity
        guard value.isFinite else { return "0.0%" }
        // Clamp to reasonable range for display
        let clamped = max(0, min(value, 100))
        return String(format: "%.1f%%", clamped)
    }

    static func formatChange(_ value: Double) -> String {
        // Handle NaN, infinity
        guard value.isFinite else { return "+0.0%" }
        // Clamp to reasonable range (-999% to +999%)
        let clamped = max(-999, min(value, 999))
        let sign = clamped >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, clamped)
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Analytics Errors
enum AnalyticsError: LocalizedError {
    case apiError(String)
    case notAuthenticated
    case networkError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .notAuthenticated:
            return "Not authenticated. Please sign in with Google."
        case .networkError(let message):
            return "Network error: \(message)"
        case .noData:
            return "No data available"
        }
    }
}

// MARK: - Network Helpers
extension AnalyticsService {
    /// Create a URLRequest with standard timeout and headers
    private static func createRequest(url: URL, token: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        return request
    }

    /// Parse error message from Google API response
    private static func parseErrorMessage(from data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return "Request failed with status \(statusCode)"
    }
}
