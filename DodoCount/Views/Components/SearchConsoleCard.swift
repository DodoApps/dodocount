import SwiftUI
import Charts

struct SearchConsoleCard: View {
    @ObservedObject var searchConsole = SearchConsoleService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.purple)

                Text(L10n.Search.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()

                // Site selector if multiple sites
                if searchConsole.sites.count > 1 {
                    Menu {
                        ForEach(searchConsole.sites) { site in
                            Button(action: { searchConsole.selectSite(site) }) {
                                HStack {
                                    Text(site.displayName)
                                    if site.siteUrl == searchConsole.selectedSite?.siteUrl {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(searchConsole.selectedSite?.displayName ?? L10n.Search.selectSite)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                    .menuStyle(.borderlessButton)
                }
            }

            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                SearchMetricBox(
                    label: L10n.Search.clicks,
                    value: formatNumber(searchConsole.metrics.clicks.today),
                    change: searchConsole.metrics.clicks.percentChange,
                    color: .purple
                )

                SearchMetricBox(
                    label: L10n.Search.impressions,
                    value: formatNumber(searchConsole.metrics.impressions.today),
                    change: searchConsole.metrics.impressions.percentChange,
                    color: .cyan
                )

                SearchMetricBox(
                    label: L10n.Search.ctr,
                    value: String(format: "%.1f%%", searchConsole.metrics.ctr.today),
                    change: searchConsole.metrics.ctr.percentChange,
                    color: .green
                )

                SearchMetricBox(
                    label: L10n.Search.position,
                    value: String(format: "%.1f", searchConsole.metrics.position.today),
                    change: -searchConsole.metrics.position.percentChange, // Lower is better
                    color: .orange,
                    invertColor: true
                )
            }

            // Trend chart
            if !searchConsole.metrics.trendData.isEmpty {
                SearchConsoleTrendChart(data: searchConsole.metrics.trendData)
                    .frame(height: 80)
            }

            // Top queries preview
            if !searchConsole.topQueries.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                Text(L10n.Search.topQueries)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                ForEach(searchConsole.topQueries.prefix(3)) { query in
                    HStack {
                        Text(query.query)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(query.clicks)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
        .padding(.horizontal, 14)
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

struct SearchMetricBox: View {
    let label: String
    let value: String
    let change: Double
    let color: Color
    var invertColor: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 8, weight: .bold))

                Text(String(format: "%.1f%%", abs(change)))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(changeColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }

    private var changeColor: Color {
        if invertColor {
            return change >= 0 ? .red : .green
        }
        return change >= 0 ? .green : .red
    }
}

struct SearchConsoleTrendChart: View {
    let data: [SearchConsoleTrendPoint]

    var body: some View {
        Chart {
            ForEach(data) { point in
                // Clicks line (purple)
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Clicks", point.clicks),
                    series: .value("Metric", "Clicks")
                )
                .foregroundStyle(Color.purple)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }

            ForEach(data) { point in
                // Impressions line (cyan) - scaled down
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Impressions", point.impressions / 5),
                    series: .value("Metric", "Impressions")
                )
                .foregroundStyle(Color.cyan)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }
}

#Preview {
    SearchConsoleCard()
        .preferredColorScheme(.dark)
        .padding()
}
