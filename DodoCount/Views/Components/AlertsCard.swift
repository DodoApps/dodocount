import SwiftUI

struct AlertsCard: View {
    @ObservedObject var alertService = AlertService.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    alertService.markAllAsRead()
                }
            }) {
                HStack {
                    HStack(spacing: 6) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(alertService.hasUnreadAlerts ? .orange : .secondary)

                            if alertService.hasUnreadAlerts {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 5, y: -5)
                            }
                        }

                        Text("ALERTS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)

                        if !alertService.recentAlerts.isEmpty {
                            Text("(\(alertService.recentAlerts.count))")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                if alertService.recentAlerts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No recent alerts")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 4) {
                        ForEach(alertService.recentAlerts.prefix(5)) { alert in
                            AlertRow(alert: alert)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

struct AlertRow: View {
    let alert: AlertItem

    @State private var isHovered = false

    private var alertColor: Color {
        switch alert.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: alert.icon)
                .font(.system(size: 12))
                .foregroundColor(alertColor)
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)

                Text(alert.message)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Time
            Text(timeAgo(alert.timestamp))
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
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

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h"
        } else {
            return "\(seconds / 86400)d"
        }
    }
}

#Preview {
    AlertsCard()
        .frame(width: 292)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
