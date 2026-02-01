import SwiftUI

struct SourcesCard: View {
    let sources: [TrafficSource]

    private let maxBarWidth: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text(L10n.Sources.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(0.5)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Sources list (limit to 10 for menubar)
            VStack(spacing: 4) {
                ForEach(sources.prefix(10)) { source in
                    SourceRow(source: source, maxBarWidth: maxBarWidth)
                }
            }
            .padding(.horizontal, 10)
        }
    }
}

struct SourceRow: View {
    let source: TrafficSource
    let maxBarWidth: CGFloat

    @State private var isHovered = false

    private var barColor: Color {
        switch source.color {
        case .organic: return .purple
        case .direct: return .blue
        case .social: return .cyan
        case .email: return .orange
        case .other: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Source name
            HStack(spacing: 4) {
                Text(source.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.9))

                if source.medium != "(none)" {
                    Text("/ \(source.medium)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: maxBarWidth, height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor.opacity(isHovered ? 0.9 : 0.7))
                    .frame(width: maxBarWidth * max(0, min(source.percentage, 100)) / 100, height: 6)
            }

            // Percentage
            Text(AnalyticsService.formatPercentage(source.percentage))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
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

#Preview {
    SourcesCard(sources: [
        TrafficSource(source: "google", medium: "organic", percentage: 45),
        TrafficSource(source: "(direct)", medium: "(none)", percentage: 28),
        TrafficSource(source: "twitter", medium: "social", percentage: 12),
        TrafficSource(source: "newsletter", medium: "email", percentage: 8)
    ])
    .frame(width: 292)
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
