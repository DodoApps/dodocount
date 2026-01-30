import SwiftUI

struct GoalProgressCard: View {
    let currentUsers: Int
    let goalUsers: Int

    @State private var isHovered = false
    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard goalUsers > 0 else { return 0 }
        return min(Double(currentUsers) / Double(goalUsers), 1.5) // Cap at 150%
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .yellow
        } else {
            return .orange
        }
    }

    private var statusText: String {
        if progress >= 1.5 {
            return "Goal crushed!"
        } else if progress >= 1.0 {
            return "Goal reached!"
        } else if progress >= 0.7 {
            return "Almost there"
        } else {
            return "Keep going"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: progress >= 1.0 ? "flag.checkered" : "flag")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(progressColor)

                    Text("DAILY GOAL")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }

                Spacer()

                Text(statusText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(progressColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.8), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(animatedProgress, 1.0), height: 8)

                    // Goal marker at 100%
                    if progress < 1.0 {
                        Rectangle()
                            .fill(Color.primary.opacity(0.3))
                            .frame(width: 2, height: 12)
                            .offset(x: geometry.size.width - 1)
                    }
                }
            }
            .frame(height: 8)

            // Stats
            HStack {
                Text("\(AnalyticsService.formatNumber(Double(currentUsers)))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("/ \(AnalyticsService.formatNumber(Double(goalUsers)))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(progressPercentage)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(progressColor.opacity(isHovered ? 0.12 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(progressColor.opacity(isHovered ? 0.25 : 0.15), lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: currentUsers) { _, _ in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        GoalProgressCard(currentUsers: 450, goalUsers: 1000)
        GoalProgressCard(currentUsers: 850, goalUsers: 1000)
        GoalProgressCard(currentUsers: 1200, goalUsers: 1000)
    }
    .frame(width: 292)
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
