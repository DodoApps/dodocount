import SwiftUI

struct PagesSection: View {
    let dateRange: DateRange
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\TopPage.views, order: .reverse)]

    private var filteredPages: [TopPage] {
        if searchText.isEmpty {
            return analyticsService.topPages
        }
        return analyticsService.topPages.filter {
            $0.path.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Pages")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Stats
                HStack(spacing: 16) {
                    StatBadge(
                        label: "Total Pages",
                        value: "\(analyticsService.topPages.count)"
                    )
                    StatBadge(
                        label: "Total Views",
                        value: AnalyticsService.formatNumber(Double(analyticsService.topPages.reduce(0) { $0 + $1.views }))
                    )
                }

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search pages...", text: $searchText)
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
            Table(filteredPages, sortOrder: $sortOrder) {
                TableColumn("Path") { page in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(page.path)
                            .font(.system(size: 13, design: .monospaced))
                            .lineLimit(1)
                        if !page.title.isEmpty && page.title != page.path {
                            Text(page.title)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .width(min: 250, ideal: 400)

                TableColumn("Views", value: \.views) { page in
                    HStack {
                        // Mini bar
                        let maxViews = analyticsService.topPages.first?.views ?? 1
                        let percentage = Double(page.views) / Double(maxViews)

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: geometry.size.width * percentage, height: 4)
                        }
                        .frame(width: 60, height: 4)

                        Text(AnalyticsService.formatNumber(Double(page.views)))
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .width(min: 140, ideal: 160)
            }
            .tableStyle(.inset)
            .onChange(of: sortOrder) { _, newOrder in
                // Sort handled by Table
            }

            // Footer
            if !analyticsService.topPages.isEmpty {
                Divider()
                HStack {
                    Text("\(filteredPages.count) of \(analyticsService.topPages.count) pages")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Showing last \(dateRange.days) days")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

#Preview {
    PagesSection(dateRange: .twentyEightDays)
        .frame(width: 800, height: 500)
        .preferredColorScheme(.dark)
}
