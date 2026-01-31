import SwiftUI
import Charts

struct OverviewSection: View {
    let dateRange: DateRange
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @ObservedObject private var searchConsole = SearchConsoleService.shared
    @ObservedObject private var alertService = AlertService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Key Metrics Cards
                metricsCardsRow

                // Trend Chart
                trendChartSection

                // Quick Stats Grid
                HStack(alignment: .top, spacing: 20) {
                    // Top Pages Preview
                    topPagesCard

                    // Top Sources Preview
                    topSourcesCard

                    // Search Performance
                    searchPerformanceCard
                }

                // Recent Alerts
                if !alertService.recentAlerts.isEmpty {
                    alertsSection
                }
            }
            .padding(24)
        }
    }

    // MARK: - Metrics Cards Row

    private var metricsCardsRow: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: "Active Users",
                value: "\(analyticsService.realtime.activeUsers)",
                subtitle: "Right now",
                icon: "person.fill",
                color: .green
            )

            MetricCard(
                title: "Users Today",
                value: AnalyticsService.formatNumber(analyticsService.daily.users.today),
                change: analyticsService.daily.users.percentChange,
                icon: "person.2.fill",
                color: .blue
            )

            MetricCard(
                title: "Sessions",
                value: AnalyticsService.formatNumber(analyticsService.daily.sessions.today),
                change: analyticsService.daily.sessions.percentChange,
                icon: "arrow.up.right",
                color: .purple
            )

            MetricCard(
                title: "Pageviews",
                value: AnalyticsService.formatNumber(analyticsService.daily.pageviews.today),
                change: analyticsService.daily.pageviews.percentChange,
                icon: "doc.text.fill",
                color: .orange
            )

            MetricCard(
                title: "Bounce Rate",
                value: AnalyticsService.formatPercentage(analyticsService.daily.bounceRate.today),
                change: -analyticsService.daily.bounceRate.percentChange, // Inverted
                icon: "arrow.uturn.left",
                color: .red
            )
        }
    }

    // MARK: - Trend Chart

    private var filteredTrendData: [TrendDataPoint] {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -dateRange.days, to: Date()) else {
            return analyticsService.extended.trendData
        }
        return analyticsService.extended.trendData.filter { $0.date >= cutoffDate }
    }

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("USERS TREND (\(dateRange.displayName.uppercased()))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            if !filteredTrendData.isEmpty {
                Chart {
                    ForEach(filteredTrendData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Users", point.value)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Users", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: dateRange == .sevenDays ? 1 : 7)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 200)
                    .overlay(
                        Text("No trend data available")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }

    // MARK: - Top Pages Card

    private var topPagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP PAGES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                Spacer()
                Text("Views")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            ForEach(analyticsService.topPages.prefix(5)) { page in
                HStack {
                    Text(page.path)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(AnalyticsService.formatNumber(Double(page.views)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            if analyticsService.topPages.isEmpty {
                Text("No data")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }

    // MARK: - Top Sources Card

    private var topSourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP SOURCES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                Spacer()
                Text("%")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            ForEach(analyticsService.trafficSources.prefix(5)) { source in
                HStack {
                    Text(source.displayName)
                        .font(.system(size: 12))
                        .lineLimit(1)

                    Spacer()

                    Text(AnalyticsService.formatPercentage(source.percentage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            if analyticsService.trafficSources.isEmpty {
                Text("No data")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }

    // MARK: - Search Performance Card

    private var searchPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEARCH CONSOLE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clicks")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(AnalyticsService.formatNumber(searchConsole.metrics.clicks.today))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Impressions")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(AnalyticsService.formatNumber(searchConsole.metrics.impressions.today))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cyan)
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CTR")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", searchConsole.metrics.ctr.today))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Position")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", searchConsole.metrics.position.today))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT ALERTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            ForEach(alertService.recentAlerts.prefix(3)) { alert in
                HStack(spacing: 12) {
                    Image(systemName: alert.icon)
                        .foregroundColor(alert.color == "green" ? .green : .red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.system(size: 12, weight: .medium))
                        Text(alert.message)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(DateUtilities.timeAgoCompact(alert.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

// MARK: - Metric Card Component

struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var change: Double? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))

                Spacer()

                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text(String(format: "%.1f%%", abs(change)))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                }
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OverviewSection(dateRange: .twentyEightDays)
        .frame(width: 800, height: 700)
        .preferredColorScheme(.dark)
}
