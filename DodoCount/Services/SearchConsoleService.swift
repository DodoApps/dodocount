import Foundation

class SearchConsoleService: ObservableObject {
    static let shared = SearchConsoleService()

    // MARK: - Published Properties
    @Published var sites: [SearchConsoleSite] = []
    @Published var selectedSite: SearchConsoleSite?
    @Published var metrics: SearchConsoleMetrics = .empty
    @Published var topQueries: [SearchQuery] = []
    @Published var topPages: [SearchPage] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var lastUpdated: Date = Date()

    // API endpoint
    private let apiBase = "https://searchconsole.googleapis.com/webmasters/v3"
    private var authObserver: NSObjectProtocol?

    private init() {
        // Observe authentication changes
        authObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GoogleAuthStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if GoogleAuthService.shared.isAuthenticated {
                self?.sites = []
                self?.selectedSite = nil
                Task {
                    await self?.fetchData()
                }
            } else {
                self?.clearAllData()
            }
        }

        // Check authentication after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            if GoogleAuthService.shared.isAuthenticated {
                Task {
                    await self?.fetchData()
                }
            }
        }
    }

    private func clearAllData() {
        sites = []
        selectedSite = nil
        metrics = .empty
        topQueries = []
        topPages = []
        error = nil
    }

    deinit {
        if let observer = authObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    func selectSite(_ site: SearchConsoleSite) {
        selectedSite = site
        UserDefaults.standard.set(site.siteUrl, forKey: "selectedSearchConsoleSite")
        Task {
            await fetchSiteData()
        }
    }

    func refreshData() {
        guard !isLoading else { return }
        Task {
            await fetchData()
        }
    }

    // MARK: - API Methods

    @MainActor
    func fetchData() async {
        guard GoogleAuthService.shared.isAuthenticated else {
            return
        }

        isLoading = true
        error = nil

        do {
            try await fetchSites()

            if selectedSite != nil {
                await fetchSiteData()
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
        lastUpdated = Date()
    }

    @MainActor
    private func fetchSiteData() async {
        guard let site = selectedSite else { return }

        do {
            async let metricsTask = fetchMetrics(siteUrl: site.siteUrl)
            async let queriesTask = fetchTopQueries(siteUrl: site.siteUrl)
            async let pagesTask = fetchTopPages(siteUrl: site.siteUrl)

            let (fetchedMetrics, fetchedQueries, fetchedPages) = try await (metricsTask, queriesTask, pagesTask)

            metrics = fetchedMetrics
            topQueries = fetchedQueries
            topPages = fetchedPages
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func fetchSites() async throws {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        guard let url = URL(string: "\(apiBase)/sites") else {
            throw SearchConsoleError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SearchConsoleError.apiError("Failed to fetch sites")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let siteEntries = json?["siteEntry"] as? [[String: Any]] ?? []

        let fetchedSites = siteEntries.compactMap { entry -> SearchConsoleSite? in
            guard let siteUrl = entry["siteUrl"] as? String,
                  let permissionLevel = entry["permissionLevel"] as? String else { return nil }
            return SearchConsoleSite(siteUrl: siteUrl, permissionLevel: permissionLevel)
        }

        // Already on MainActor context via fetchData
        self.sites = fetchedSites

        // Select saved site or first site
        if selectedSite == nil {
            if let savedUrl = UserDefaults.standard.string(forKey: "selectedSearchConsoleSite"),
               let saved = fetchedSites.first(where: { $0.siteUrl == savedUrl }) {
                selectedSite = saved
            } else {
                selectedSite = fetchedSites.first
            }
        }
    }

    private func fetchMetrics(siteUrl: String) async throws -> SearchConsoleMetrics {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        // Current period: last 28 days
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -28, to: endDate),
              let prevEndDate = calendar.date(byAdding: .day, value: -1, to: startDate),
              let prevStartDate = calendar.date(byAdding: .day, value: -28, to: prevEndDate) else {
            throw SearchConsoleError.apiError("Failed to calculate date range")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Fetch current period with daily breakdown
        let currentData = try await fetchSearchAnalytics(
            token: token,
            siteUrl: siteUrl,
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate),
            dimensions: ["date"]
        )

        // Fetch previous period totals
        let previousData = try await fetchSearchAnalytics(
            token: token,
            siteUrl: siteUrl,
            startDate: dateFormatter.string(from: prevStartDate),
            endDate: dateFormatter.string(from: prevEndDate),
            dimensions: []
        )

        // Parse current period totals and trend
        var totalClicks = 0
        var totalImpressions = 0
        var totalCtr = 0.0
        var totalPosition = 0.0
        var trendPoints: [SearchConsoleTrendPoint] = []

        for row in currentData {
            let keys = row["keys"] as? [String] ?? []
            let clicks = row["clicks"] as? Int ?? 0
            let impressions = row["impressions"] as? Int ?? 0
            let ctr = row["ctr"] as? Double ?? 0
            let position = row["position"] as? Double ?? 0

            totalClicks += clicks
            totalImpressions += impressions

            if let dateStr = keys.first, let date = dateFormatter.date(from: dateStr) {
                trendPoints.append(SearchConsoleTrendPoint(
                    date: date,
                    clicks: clicks,
                    impressions: impressions,
                    ctr: ctr * 100,
                    position: position
                ))
            }
        }

        if !currentData.isEmpty {
            totalCtr = Double(totalClicks) / Double(max(1, totalImpressions)) * 100
            totalPosition = currentData.reduce(0.0) { $0 + ($1["position"] as? Double ?? 0) } / Double(currentData.count)
        }

        // Parse previous period
        var prevClicks = 0
        var prevImpressions = 0
        var prevCtr = 0.0
        var prevPosition = 0.0

        if let firstRow = previousData.first {
            prevClicks = firstRow["clicks"] as? Int ?? 0
            prevImpressions = firstRow["impressions"] as? Int ?? 0
            prevCtr = (firstRow["ctr"] as? Double ?? 0) * 100
            prevPosition = firstRow["position"] as? Double ?? 0
        }

        return SearchConsoleMetrics(
            clicks: MetricComparison(today: Double(totalClicks), yesterday: Double(prevClicks)),
            impressions: MetricComparison(today: Double(totalImpressions), yesterday: Double(prevImpressions)),
            ctr: MetricComparison(today: totalCtr, yesterday: prevCtr),
            position: MetricComparison(today: totalPosition, yesterday: prevPosition),
            trendData: trendPoints.sorted { $0.date < $1.date }
        )
    }

    private func fetchTopQueries(siteUrl: String) async throws -> [SearchQuery] {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -28, to: endDate) else {
            throw SearchConsoleError.apiError("Failed to calculate date range")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let data = try await fetchSearchAnalytics(
            token: token,
            siteUrl: siteUrl,
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate),
            dimensions: ["query"],
            rowLimit: 10
        )

        return data.compactMap { row -> SearchQuery? in
            guard let keys = row["keys"] as? [String],
                  let query = keys.first else { return nil }

            return SearchQuery(
                query: query,
                clicks: row["clicks"] as? Int ?? 0,
                impressions: row["impressions"] as? Int ?? 0,
                ctr: (row["ctr"] as? Double ?? 0) * 100,
                position: row["position"] as? Double ?? 0
            )
        }
    }

    private func fetchTopPages(siteUrl: String) async throws -> [SearchPage] {
        let token = try await GoogleAuthService.shared.getValidAccessToken()

        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -28, to: endDate) else {
            throw SearchConsoleError.apiError("Failed to calculate date range")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let data = try await fetchSearchAnalytics(
            token: token,
            siteUrl: siteUrl,
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate),
            dimensions: ["page"],
            rowLimit: 10
        )

        return data.compactMap { row -> SearchPage? in
            guard let keys = row["keys"] as? [String],
                  let page = keys.first else { return nil }

            return SearchPage(
                page: page,
                clicks: row["clicks"] as? Int ?? 0,
                impressions: row["impressions"] as? Int ?? 0,
                ctr: (row["ctr"] as? Double ?? 0) * 100,
                position: row["position"] as? Double ?? 0
            )
        }
    }

    private func fetchSearchAnalytics(
        token: String,
        siteUrl: String,
        startDate: String,
        endDate: String,
        dimensions: [String],
        rowLimit: Int = 1000
    ) async throws -> [[String: Any]] {
        // URL encode the site URL properly - need to encode the entire URL including special chars
        guard let encodedSiteUrl = siteUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) else {
            throw SearchConsoleError.apiError("Failed to encode site URL")
        }

        guard let url = URL(string: "\(apiBase)/sites/\(encodedSiteUrl)/searchAnalytics/query") else {
            throw SearchConsoleError.apiError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "startDate": startDate,
            "endDate": endDate,
            "rowLimit": rowLimit
        ]

        if !dimensions.isEmpty {
            body["dimensions"] = dimensions
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Try to get error details
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw SearchConsoleError.apiError(message)
            }
            throw SearchConsoleError.apiError("Failed to fetch search analytics (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["rows"] as? [[String: Any]] ?? []
    }
}

// MARK: - Errors
enum SearchConsoleError: LocalizedError {
    case apiError(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .notAuthenticated:
            return "Not authenticated. Please sign in with Google."
        }
    }
}
