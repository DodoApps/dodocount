import SwiftUI
import Charts

struct ExtendedMetricsCard: View {
    let metrics: ExtendedMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(L10n.Extended.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()
            }

            // Metrics row
            HStack(spacing: 0) {
                ExtendedMetricItem(
                    label: L10n.Extended.users,
                    value: AnalyticsService.formatNumber(metrics.activeUsers28Day.today),
                    change: metrics.activeUsers28Day.percentChange,
                    color: .blue
                )

                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 8)

                ExtendedMetricItem(
                    label: L10n.Extended.events,
                    value: AnalyticsService.formatNumber(metrics.eventCount.today),
                    change: metrics.eventCount.percentChange,
                    color: .green
                )

                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 8)

                ExtendedMetricItem(
                    label: L10n.Extended.views,
                    value: AnalyticsService.formatNumber(metrics.pageviews.today),
                    change: metrics.pageviews.percentChange,
                    color: .orange
                )
            }

            // Trend chart
            if !metrics.trendData.isEmpty {
                TrendChart(data: metrics.trendData)
                    .frame(height: 60)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
        .padding(.horizontal, 14)
    }
}

struct ExtendedMetricItem: View {
    let label: String
    let value: String
    let change: Double
    let color: Color

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
            .foregroundColor(change >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TrendChart: View {
    let data: [TrendDataPoint]

    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.blue.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
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
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }
}

#Preview {
    ExtendedMetricsCard(metrics: ExtendedMetrics(
        activeUsers28Day: MetricComparison(today: 809000, yesterday: 930000),
        eventCount: MetricComparison(today: 802000, yesterday: 795000),
        pageviews: MetricComparison(today: 322000, yesterday: 331000),
        trendData: []
    ))
    .preferredColorScheme(.dark)
    .padding()
}
