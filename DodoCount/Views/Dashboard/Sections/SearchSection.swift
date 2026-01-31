import SwiftUI
import Charts

struct SearchSection: View {
    let dateRange: DateRange
    @ObservedObject private var searchConsole = SearchConsoleService.shared
    @State private var selectedTab = 0 // 0 = Queries, 1 = Pages
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header with metrics
            searchMetricsHeader

            Divider()

            // Tab picker
            Picker("View", selection: $selectedTab) {
                Text("Queries").tag(0)
                Text("Pages").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(selectedTab == 0 ? "Search queries..." : "Search pages...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal)

            // Content
            if searchConsole.topQueries.isEmpty && searchConsole.topPages.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Search Console data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if let error = searchConsole.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if searchConsole.selectedSite == nil {
                        Text("No Search Console site selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Site: \(searchConsole.selectedSite?.siteUrl ?? "None")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedTab == 0 {
                queriesTable
            } else {
                pagesTable
            }
        }
    }

    // MARK: - Metrics Header

    private var searchMetricsHeader: some View {
        HStack(spacing: 24) {
            SearchMetricItem(
                label: "Clicks",
                value: AnalyticsService.formatNumber(searchConsole.metrics.clicks.today),
                change: searchConsole.metrics.clicks.percentChange,
                color: .purple
            )

            SearchMetricItem(
                label: "Impressions",
                value: AnalyticsService.formatNumber(searchConsole.metrics.impressions.today),
                change: searchConsole.metrics.impressions.percentChange,
                color: .cyan
            )

            SearchMetricItem(
                label: "CTR",
                value: String(format: "%.2f%%", searchConsole.metrics.ctr.today),
                change: searchConsole.metrics.ctr.percentChange,
                color: .green
            )

            SearchMetricItem(
                label: "Avg. Position",
                value: String(format: "%.1f", searchConsole.metrics.position.today),
                change: -searchConsole.metrics.position.percentChange, // Lower is better
                color: .orange
            )

            Spacer()

            // Trend mini chart
            if !searchConsole.metrics.trendData.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CLICKS TREND")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)

                    Chart {
                        ForEach(searchConsole.metrics.trendData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Clicks", point.clicks)
                            )
                            .foregroundStyle(Color.purple)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(width: 120, height: 40)
                }
            }
        }
        .padding()
    }

    // MARK: - Queries Table

    private var queriesTable: some View {
        let filtered = searchText.isEmpty
            ? searchConsole.topQueries
            : searchConsole.topQueries.filter { $0.query.localizedCaseInsensitiveContains(searchText) }

        return Table(filtered) {
            TableColumn("Query") { query in
                Text(query.query)
                    .font(.system(size: 13))
                    .lineLimit(2)
            }
            .width(min: 200, ideal: 300)

            TableColumn("Clicks") { query in
                Text("\(query.clicks)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.purple)
            }
            .width(80)

            TableColumn("Impressions") { query in
                Text(AnalyticsService.formatNumber(Double(query.impressions)))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .width(100)

            TableColumn("CTR") { query in
                HStack(spacing: 4) {
                    Text(String(format: "%.2f%%", query.ctr))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ctrColor(query.ctr))
                }
            }
            .width(80)

            TableColumn("Position") { query in
                HStack(spacing: 4) {
                    positionBadge(query.position)
                    Text(String(format: "%.1f", query.position))
                        .font(.system(size: 13))
                }
            }
            .width(100)
        }
        .tableStyle(.inset)
    }

    // MARK: - Pages Table

    private var pagesTable: some View {
        let filtered = searchText.isEmpty
            ? searchConsole.topPages
            : searchConsole.topPages.filter { $0.page.localizedCaseInsensitiveContains(searchText) }

        return Table(filtered) {
            TableColumn("Page") { page in
                VStack(alignment: .leading, spacing: 2) {
                    Text(page.shortPath)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Text(page.page)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .width(min: 200, ideal: 300)

            TableColumn("Clicks") { page in
                Text("\(page.clicks)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.purple)
            }
            .width(80)

            TableColumn("Impressions") { page in
                Text(AnalyticsService.formatNumber(Double(page.impressions)))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .width(100)

            TableColumn("CTR") { page in
                Text(String(format: "%.2f%%", page.ctr))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ctrColor(page.ctr))
            }
            .width(80)

            TableColumn("Position") { page in
                HStack(spacing: 4) {
                    positionBadge(page.position)
                    Text(String(format: "%.1f", page.position))
                        .font(.system(size: 13))
                }
            }
            .width(100)
        }
        .tableStyle(.inset)
    }

    // MARK: - Helpers

    private func ctrColor(_ ctr: Double) -> Color {
        if ctr >= 5 { return .green }
        if ctr >= 2 { return .yellow }
        return .red
    }

    private func positionBadge(_ position: Double) -> some View {
        let color: Color = {
            if position <= 3 { return .green }
            if position <= 10 { return .yellow }
            return .red
        }()

        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Search Metric Item

struct SearchMetricItem: View {
    let label: String
    let value: String
    let change: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                Text(String(format: "%.1f%%", abs(change)))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(change >= 0 ? .green : .red)
        }
    }
}

#Preview {
    SearchSection(dateRange: .twentyEightDays)
        .frame(width: 800, height: 600)
        .preferredColorScheme(.dark)
}
