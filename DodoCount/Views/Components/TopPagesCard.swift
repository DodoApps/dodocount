import SwiftUI

struct TopPagesCard: View {
    let pages: [TopPage]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text(L10n.Pages.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .tracking(0.5)

                Spacer()

                Text(L10n.Metrics.pageviews)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Pages list (limit to 10 for menubar)
            VStack(spacing: 2) {
                ForEach(pages.prefix(10)) { page in
                    TopPageRow(page: page)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct TopPageRow: View {
    let page: TopPage

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Path
            Text(page.path)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary.opacity(0.9))
                .lineLimit(1)
                .truncationMode(.middle)

            // Title (secondary)
            Text(page.title)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.6))
                .lineLimit(1)

            Spacer()

            // Views count
            Text(AnalyticsService.formatNumber(Double(page.views)))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
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

#Preview {
    TopPagesCard(pages: [
        TopPage(path: "/", title: "Home", views: 1234),
        TopPage(path: "/pricing", title: "Pricing", views: 567),
        TopPage(path: "/about", title: "About us", views: 432),
        TopPage(path: "/blog/ai-tools", title: "Blog post", views: 321),
        TopPage(path: "/contact", title: "Contact", views: 198)
    ])
    .frame(width: 292)
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
