import SwiftUI
import Charts

struct RealtimeCard: View {
    let activeUsers: Int
    let sparklineHistory: [Int]

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                                .scaleEffect(1.5)
                        )

                    Text(L10n.Realtime.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }

                Spacer()

                Text(L10n.Realtime.last30Min)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            // Main content
            HStack(alignment: .bottom, spacing: 16) {
                // Large number
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(activeUsers)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(L10n.Realtime.activeUsers)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Sparkline chart
                if !sparklineHistory.isEmpty {
                    SparklineChart(data: sparklineHistory)
                        .frame(width: 100, height: 40)
                        .clipped()
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(isHovered ? 0.12 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(isHovered ? 0.25 : 0.15), lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

struct SparklineChart: View {
    let data: [Int]

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Users", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", index),
                    y: .value("Users", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: {
            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 100
            // Ensure valid range even when all values are the same
            if minVal == maxVal {
                return max(0, minVal - 10) ... maxVal + 10
            }
            return max(0, minVal - 10) ... maxVal + 10
        }())
    }
}

#Preview {
    RealtimeCard(
        activeUsers: 142,
        sparklineHistory: [120, 135, 142, 128, 156, 142, 138, 145, 150, 148, 142]
    )
    .frame(width: 292)
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
