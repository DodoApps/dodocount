import SwiftUI

struct MetricRow: View {
    let label: String
    let value: String
    let comparison: MetricComparison
    let isInverted: Bool // For metrics like bounce rate where lower is better

    @State private var isHovered = false

    init(label: String, value: String, comparison: MetricComparison, isInverted: Bool = false) {
        self.label = label
        self.value = value
        self.comparison = comparison
        self.isInverted = isInverted
    }

    private var effectiveIsPositive: Bool {
        isInverted ? !comparison.isPositive : comparison.isPositive
    }

    private var changeColor: Color {
        if abs(comparison.percentChange) < 0.1 {
            return .secondary
        }
        return effectiveIsPositive ? .green : .red
    }

    var body: some View {
        HStack(spacing: 0) {
            // Label
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Today's value
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 70, alignment: .trailing)

            // Change percentage
            HStack(spacing: 3) {
                Image(systemName: effectiveIsPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .semibold))

                Text(AnalyticsService.formatChange(comparison.percentChange))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(changeColor)
            .frame(width: 65, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(isHovered ? 0.05 : 0))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

struct MetricsSection: View {
    let daily: DailyMetrics

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text(L10n.Metrics.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(0.5)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Metrics
            VStack(spacing: 2) {
                MetricRow(
                    label: L10n.Metrics.users,
                    value: AnalyticsService.formatNumber(daily.users.today),
                    comparison: daily.users
                )

                MetricRow(
                    label: L10n.Metrics.sessions,
                    value: AnalyticsService.formatNumber(daily.sessions.today),
                    comparison: daily.sessions
                )

                MetricRow(
                    label: L10n.Metrics.pageviews,
                    value: AnalyticsService.formatNumber(daily.pageviews.today),
                    comparison: daily.pageviews
                )

                MetricRow(
                    label: L10n.Metrics.bounceRate,
                    value: AnalyticsService.formatPercentage(daily.bounceRate.today),
                    comparison: daily.bounceRate,
                    isInverted: true
                )

                MetricRow(
                    label: L10n.Metrics.avgDuration,
                    value: AnalyticsService.formatDuration(daily.avgSessionDuration.today),
                    comparison: daily.avgSessionDuration
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    MetricsSection(daily: DailyMetrics(
        users: MetricComparison(today: 2341, yesterday: 2082),
        sessions: MetricComparison(today: 3892, yesterday: 3596),
        pageviews: MetricComparison(today: 12450, yesterday: 10817),
        bounceRate: MetricComparison(today: 42.3, yesterday: 43.5),
        avgSessionDuration: MetricComparison(today: 185, yesterday: 172)
    ))
    .frame(width: 292)
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
