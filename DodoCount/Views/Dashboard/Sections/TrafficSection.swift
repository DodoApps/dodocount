import SwiftUI

struct TrafficSection: View {
    let dateRange: DateRange
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var sortOrder = [KeyPathComparator(\TrafficSource.percentage, order: .reverse)]
    @State private var searchText = ""

    private var filteredSources: [TrafficSource] {
        if searchText.isEmpty {
            return analyticsService.trafficSources
        }
        return analyticsService.trafficSources.filter {
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.medium.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Traffic Sources")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search sources...", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 200)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
            .padding()

            Divider()

            // Table
            Table(filteredSources, sortOrder: $sortOrder) {
                TableColumn("Source") { source in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorForSource(source))
                            .frame(width: 8, height: 8)
                        Text(source.displayName)
                            .font(.system(size: 13))
                    }
                }
                .width(min: 150, ideal: 200)

                TableColumn("Medium") { source in
                    Text(source.medium)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .width(min: 100, ideal: 120)

                TableColumn("Share", value: \.percentage) { source in
                    HStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorForSource(source))
                                    .frame(width: geometry.size.width * (source.percentage / 100), height: 6)
                            }
                        }
                        .frame(width: 80, height: 6)

                        Text(AnalyticsService.formatPercentage(source.percentage))
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .width(min: 150, ideal: 180)
            }
            .tableStyle(.inset)

            // Summary footer
            if !analyticsService.trafficSources.isEmpty {
                Divider()
                HStack {
                    Text("\(analyticsService.trafficSources.count) sources")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    // Source breakdown
                    HStack(spacing: 16) {
                        sourceBreakdownItem("Organic", color: .purple, sources: ["organic"])
                        sourceBreakdownItem("Direct", color: .blue, sources: ["(none)"])
                        sourceBreakdownItem("Social", color: .cyan, sources: ["social"])
                        sourceBreakdownItem("Other", color: .gray, sources: [])
                    }
                }
                .padding()
            }
        }
    }

    private func colorForSource(_ source: TrafficSource) -> Color {
        switch source.color {
        case .organic: return .purple
        case .direct: return .blue
        case .social: return .cyan
        case .email: return .orange
        case .other: return .gray
        }
    }

    private func sourceBreakdownItem(_ label: String, color: Color, sources: [String]) -> some View {
        let total = analyticsService.trafficSources
            .filter { sources.isEmpty ? !["organic", "(none)", "social", "email"].contains($0.medium.lowercased()) : sources.contains($0.medium.lowercased()) }
            .reduce(0.0) { $0 + $1.percentage }

        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f%%", total))
                .font(.system(size: 11, weight: .medium))
        }
    }
}

#Preview {
    TrafficSection(dateRange: .twentyEightDays)
        .frame(width: 800, height: 500)
        .preferredColorScheme(.dark)
}
