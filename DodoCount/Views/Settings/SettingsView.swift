import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @ObservedObject private var authService = GoogleAuthService.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)

                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Picker("", selection: $selectedTab) {
                    Text("General").tag(0)
                    Text("About").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            if selectedTab == 0 {
                generalTab
            } else {
                aboutTab
            }

            Divider()

            // Footer
            HStack {
                Text("DodoCount v1.0.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Reset settings") {
                    settingsManager.reset()
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 480, height: 620)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - General Tab

    private var generalTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Google Cloud Configuration
                SettingsSection(title: "Google Cloud") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter your OAuth Client ID from Google Cloud Console")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        TextField("Client ID", text: $settingsManager.settings.googleClientId)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))

                        Link(destination: URL(string: "https://console.cloud.google.com/apis/credentials")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 10))
                                Text("Open Google Cloud Console")
                                    .font(.system(size: 11))
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }

                // Account section
                SettingsSection(title: "Account") {
                    VStack(alignment: .leading, spacing: 12) {
                        if authService.isAuthenticated {
                            // Connected state
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Connected")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.green)

                                    if let email = authService.userEmail {
                                        Text(email)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button("Disconnect") {
                                    authService.signOut()
                                    analyticsService.refreshData()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                        } else {
                            // Not connected state
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Not connected")
                                        .font(.system(size: 13, weight: .medium))

                                    Text("Sign in with Google to connect GA4 & Search Console")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if authService.isAuthenticating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 80)
                                } else {
                                    Button(action: {
                                        authService.signIn()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "g.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Sign in")
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    .disabled(settingsManager.settings.googleClientId.isEmpty)
                                }
                            }

                            // Show warning if no client ID
                            if settingsManager.settings.googleClientId.isEmpty {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 12))

                                    Text("Enter your Client ID above to enable sign in")
                                        .font(.system(size: 11))
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 4)
                            }

                            // Show error if any
                            if let error = authService.error {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 12))

                                    Text(error)
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }

                // Property section
                SettingsSection(title: "Property") {
                    Picker("Selected property", selection: Binding(
                        get: { analyticsService.selectedProperty?.id ?? "" },
                        set: { newId in
                            if let property = analyticsService.properties.first(where: { $0.id == newId }) {
                                analyticsService.selectProperty(property)
                            }
                        }
                    )) {
                        ForEach(analyticsService.properties) { property in
                            Text(property.shortName).tag(property.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Refresh interval section
                SettingsSection(title: "Refresh interval") {
                    Picker("Refresh interval", selection: $settingsManager.settings.refreshInterval) {
                        ForEach(RefreshInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settingsManager.settings.refreshInterval) { _, _ in
                        analyticsService.startRefreshTimer()
                    }
                }

                // Menubar display section
                SettingsSection(title: "Menubar display") {
                    Picker("Display mode", selection: $settingsManager.settings.menubarDisplayMode) {
                        ForEach(MenubarDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Appearance section
                SettingsSection(title: "Appearance") {
                    Picker("Appearance", selection: $settingsManager.settings.appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Launch at login section
                SettingsSection(title: "Startup") {
                    Toggle("Launch at login", isOn: $settingsManager.settings.launchAtLogin)
                        .onChange(of: settingsManager.settings.launchAtLogin) { _, newValue in
                            setLaunchAtLogin(newValue)
                        }
                }

                Spacer()
            }
            .padding(20)
        }
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // App icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.teal.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // App name
                Text("DodoCount")
                    .font(.system(size: 24, weight: .bold))

                // Version
                Text("Version 1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                // Description
                VStack(spacing: 12) {
                    Text("Your Google Analytics companion for macOS")
                        .font(.system(size: 14, weight: .medium))

                    Text("DodoCount is a beautiful menubar app that gives you instant access to your Google Analytics 4 and Search Console data. Monitor real-time visitors, track daily metrics, and stay on top of your website's performance — all from your menubar.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 8)

                // Copyright
                Text("© 2026 DodoApps")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            content
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
