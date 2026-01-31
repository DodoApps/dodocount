import SwiftUI

// MARK: - Dashboard Window Controller

class DashboardWindowController: NSWindowController {
    static let shared = DashboardWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DodoCount Dashboard"
        window.minSize = NSSize(width: 800, height: 500)
        window.center()
        window.setFrameAutosaveName("DashboardWindow")
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: DashboardView())

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Dashboard Sidebar Item

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case traffic = "Traffic"
    case search = "Search"
    case pages = "Pages"
    case audience = "Audience"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .traffic: return "arrow.up.right"
        case .search: return "magnifyingglass"
        case .pages: return "doc.text.fill"
        case .audience: return "globe"
        }
    }
}

// MARK: - Date Range

enum DateRange: String, CaseIterable {
    case sevenDays = "7d"
    case twentyEightDays = "28d"
    case ninetyDays = "90d"

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .twentyEightDays: return 28
        case .ninetyDays: return 90
        }
    }

    var displayName: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .twentyEightDays: return "28 Days"
        case .ninetyDays: return "90 Days"
        }
    }
}

// MARK: - Main Dashboard View

struct DashboardView: View {
    @State private var selectedSection: DashboardSection = .overview
    @State private var selectedDateRange: DateRange = .twentyEightDays
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @ObservedObject private var searchConsole = SearchConsoleService.shared

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(DashboardSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            // Main content
            VStack(spacing: 0) {
                // Header with date range picker
                dashboardHeader

                Divider()

                // Content based on selected section
                Group {
                    switch selectedSection {
                    case .overview:
                        OverviewSection(dateRange: selectedDateRange)
                    case .traffic:
                        TrafficSection(dateRange: selectedDateRange)
                    case .search:
                        SearchSection(dateRange: selectedDateRange)
                    case .pages:
                        PagesSection(dateRange: selectedDateRange)
                    case .audience:
                        AudienceSection(dateRange: selectedDateRange)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .preferredColorScheme(.dark)
    }

    private var dashboardHeader: some View {
        HStack {
            // Property name
            if let property = analyticsService.selectedProperty {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    Text(property.shortName)
                        .font(.headline)
                }
            }

            Spacer()

            // Date range picker
            Picker("Date Range", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)

            // Refresh button
            Button(action: {
                analyticsService.refreshData()
                searchConsole.refreshData()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(analyticsService.isLoading)
        }
        .padding()
    }
}

#Preview {
    DashboardView()
        .frame(width: 1000, height: 700)
}
