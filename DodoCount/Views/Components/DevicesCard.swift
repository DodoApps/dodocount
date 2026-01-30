import SwiftUI

struct DevicesCard: View {
    let devices: DeviceBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text(L10n.Devices.title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
                .tracking(0.5)
                .padding(.bottom, 6)

            // Device breakdown
            VStack(spacing: 4) {
                DeviceRow(
                    icon: "desktopcomputer",
                    label: L10n.Devices.desktop,
                    percentage: devices.desktop
                )

                DeviceRow(
                    icon: "iphone",
                    label: L10n.Devices.mobile,
                    percentage: devices.mobile
                )

                DeviceRow(
                    icon: "ipad",
                    label: L10n.Devices.tablet,
                    percentage: devices.tablet
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

struct DeviceRow: View {
    let icon: String
    let label: String
    let percentage: Double

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 14)

            // Label
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 4)

            // Percentage
            Text(AnalyticsService.formatPercentage(percentage))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
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
    DevicesCard(devices: DeviceBreakdown(desktop: 58, mobile: 35, tablet: 7))
        .frame(width: 140)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
