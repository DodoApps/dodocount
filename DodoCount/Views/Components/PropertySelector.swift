import SwiftUI

struct PropertySelector: View {
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var isExpanded = false

    var body: some View {
        Menu {
            ForEach(analyticsService.properties) { property in
                Button(action: {
                    analyticsService.selectProperty(property)
                }) {
                    HStack {
                        Text(property.shortName)
                        if property.id == analyticsService.selectedProperty?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(analyticsService.selectedProperty?.shortName ?? "Select property")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 120)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
