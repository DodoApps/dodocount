import SwiftUI

struct AudienceSection: View {
    let dateRange: DateRange
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var selectedTab = 0 // 0 = Countries, 1 = Devices
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Audience")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Tab picker
                Picker("View", selection: $selectedTab) {
                    Text("Countries").tag(0)
                    Text("Devices").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding()

            Divider()

            // Content
            if selectedTab == 0 {
                countriesView
            } else {
                devicesView
            }
        }
    }

    // MARK: - Countries View

    private var countriesView: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search countries...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding()

            let filtered = searchText.isEmpty
                ? analyticsService.countries
                : analyticsService.countries.filter {
                    $0.countryName.localizedCaseInsensitiveContains(searchText) ||
                    $0.countryCode.localizedCaseInsensitiveContains(searchText)
                }

            // Table
            Table(filtered) {
                TableColumn("Country") { country in
                    HStack(spacing: 10) {
                        Text(country.flag)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.countryName)
                                .font(.system(size: 13))
                            Text(country.countryCode)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .width(min: 200, ideal: 250)

                TableColumn("Users") { country in
                    Text(AnalyticsService.formatNumber(Double(country.users)))
                        .font(.system(size: 13, weight: .medium))
                }
                .width(100)

                TableColumn("Share") { country in
                    HStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * (country.percentage / 100), height: 6)
                            }
                        }
                        .frame(width: 100, height: 6)

                        Text(AnalyticsService.formatPercentage(country.percentage))
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .width(min: 170, ideal: 200)
            }
            .tableStyle(.inset)

            // Footer
            if !analyticsService.countries.isEmpty {
                Divider()
                HStack {
                    Text("\(analyticsService.countries.count) countries")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    // Top 3 summary
                    HStack(spacing: 12) {
                        ForEach(analyticsService.countries.prefix(3)) { country in
                            HStack(spacing: 4) {
                                Text(country.flag)
                                Text(String(format: "%.0f%%", country.percentage))
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Devices View

    private var devicesView: some View {
        VStack(spacing: 24) {
            // Device breakdown cards
            HStack(spacing: 20) {
                DeviceCard(
                    icon: "desktopcomputer",
                    label: "Desktop",
                    percentage: analyticsService.devices.desktop,
                    color: .blue
                )

                DeviceCard(
                    icon: "iphone",
                    label: "Mobile",
                    percentage: analyticsService.devices.mobile,
                    color: .green
                )

                DeviceCard(
                    icon: "ipad",
                    label: "Tablet",
                    percentage: analyticsService.devices.tablet,
                    color: .orange
                )
            }
            .padding()

            // Visual breakdown
            deviceBreakdownChart
                .padding()

            Spacer()
        }
    }

    private var deviceBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DEVICE BREAKDOWN")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            // Horizontal stacked bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if analyticsService.devices.desktop > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (analyticsService.devices.desktop / 100))
                    }
                    if analyticsService.devices.mobile > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: geometry.size.width * (analyticsService.devices.mobile / 100))
                    }
                    if analyticsService.devices.tablet > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * (analyticsService.devices.tablet / 100))
                    }
                }
            }
            .frame(height: 24)

            // Legend
            HStack(spacing: 24) {
                LegendItem(color: .blue, label: "Desktop", value: analyticsService.devices.desktop)
                LegendItem(color: .green, label: "Mobile", value: analyticsService.devices.mobile)
                LegendItem(color: .orange, label: "Tablet", value: analyticsService.devices.tablet)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

// MARK: - Device Card

struct DeviceCard: View {
    let icon: String
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)

            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(String(format: "%.1f%%", value))
                .font(.system(size: 12, weight: .medium))
        }
    }
}

#Preview {
    AudienceSection(dateRange: .twentyEightDays)
        .frame(width: 800, height: 600)
        .preferredColorScheme(.dark)
}
