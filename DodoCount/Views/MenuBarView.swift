import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var alertService = AlertService.shared
    @ObservedObject private var searchConsole = SearchConsoleService.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Error banner (if any)
                if let error = analyticsService.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                }

                // Realtime card
                RealtimeCard(
                    activeUsers: analyticsService.realtime.activeUsers,
                    sparklineHistory: analyticsService.realtime.sparklineHistory
                )
                .padding(.horizontal, 14)
                .padding(.top, 8)

                // Goal progress (if enabled)
                if settingsManager.settings.showGoalProgress {
                    GoalProgressCard(
                        currentUsers: Int(analyticsService.daily.users.today),
                        goalUsers: settingsManager.settings.dailyUserGoal
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                }

                // Alerts section
                AlertsCard()
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                // 28-Day Overview
                ExtendedMetricsCard(metrics: analyticsService.extended)
                    .padding(.top, 8)

                // Today vs Yesterday metrics
                MetricsSection(daily: analyticsService.daily)
                    .padding(.top, 12)

                // Search Console section
                SearchConsoleCard()
                    .padding(.top, 8)

                // Top Pages
                TopPagesCard(pages: analyticsService.topPages)
                    .padding(.top, 8)

                // Traffic Sources
                SourcesCard(sources: analyticsService.trafficSources)
                    .padding(.top, 8)

                // Countries & Devices side by side
                HStack(alignment: .top, spacing: 8) {
                    CountriesCard(countries: analyticsService.countries)
                    DevicesCard(devices: analyticsService.devices)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                // Footer
                footerSection
                    .padding(.top, 12)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 340, height: 720)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                Color.black.opacity(0.3)
            }
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 10) {
            // App icon with glow effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .blur(radius: 4)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("DodoCount")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                PropertySelector()
            }

            Spacer()

            // Refresh button
            HeaderButton(icon: "arrow.clockwise", tooltip: "Refresh") {
                analyticsService.refreshData()
                searchConsole.refreshData()
            }

            // Settings button
            HeaderButton(icon: "gearshape", tooltip: "Settings") {
                openSettings()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        HStack {
            // Last updated
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text("Updated \(DateUtilities.timeAgo(analyticsService.lastUpdated))")
                    .font(.system(size: 10))
            }
            .foregroundColor(.secondary.opacity(0.7))

            Spacer()

            // Share button
            Menu {
                ForEach(ShareFormat.allCases, id: \.self) { format in
                    Button(action: { format.copy() }) {
                        Label(format.rawValue, systemImage: format.icon)
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 9, weight: .medium))
                    Text(L10n.Share.copyStats)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .help(L10n.Share.copyStats)

            // Refresh button
            Button(action: { analyticsService.refreshData() }) {
                HStack(spacing: 4) {
                    if analyticsService.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .medium))
                    }
                    Text("Refresh")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(analyticsService.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - Helper Methods

    private func openSettings() {
        NSApp.sendAction(#selector(AppDelegate.openSettingsWindow), to: nil, from: nil)
    }
}

// MARK: - Header Button
struct HeaderButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isHovered ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(isHovered ? 0.1 : 0.05))
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    MenuBarView()
}
