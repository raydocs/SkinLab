import SwiftUI

/// Visual streak badge displaying current and longest streak
struct StreakBadgeView: View {
    let currentStreak: Int
    let longestStreak: Int
    let freezesAvailable: Int
    let onFreezeTap: (() -> Void)?

    @State private var animateCounter = false
    @State private var displayCount: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            // Streak badge
            ZStack {
                // Glow effect for active streaks
                if currentStreak >= 3 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    glowColor.opacity(0.4),
                                    glowColor.opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 70
                            )
                        )
                        .frame(width: 120, height: 120)
                }

                // Background circle
                Circle()
                    .fill(streakGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: glowColor.opacity(0.4), radius: 8)

                // Streak count
                VStack(spacing: 2) {
                    Text("\(displayCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(value: Double(displayCount)))
                        .scaleEffect(animateCounter ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateCounter)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            // Info and freeze button
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续打卡")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text("\(currentStreak) 天")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("最长: \(longestStreak) 天")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Freeze button
                if currentStreak >= 3, freezesAvailable > 0 {
                    Button(action: {
                        onFreezeTap?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 12))

                            Text("冻结卡 (\(freezesAvailable))")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("使用连续打卡冻结卡，剩余\(freezesAvailable)个")
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            displayCount = currentStreak
            if currentStreak > 0 {
                animateCounter = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateCounter = false
                }
            }
        }
        .onChange(of: currentStreak) { oldValue, newValue in
            displayCount = newValue
            if newValue > oldValue {
                animateCounter = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateCounter = false
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("连续打卡\(currentStreak)天，最长\(longestStreak)天")
    }

    // MARK: - Computed Properties

    private var streakGradient: LinearGradient {
        let colors: [Color] = streakColors
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var streakColors: [Color] {
        if currentStreak >= 28 {
            [.purple, .pink] // Legendary
        } else if currentStreak >= 14 {
            [.orange, .red] // Epic
        } else if currentStreak >= 7 {
            [.yellow, .orange] // Great
        } else if currentStreak >= 3 {
            [.green, .mint] // Good
        } else {
            [.gray, .gray.opacity(0.7)] // Starting
        }
    }

    private var glowColor: Color {
        streakColors.first ?? .orange
    }
}

#Preview("Streak: 0 days") {
    StreakBadgeView(
        currentStreak: 0,
        longestStreak: 0,
        freezesAvailable: 1
    ) {
        // Preview action placeholder
    }
    .padding()
}

#Preview("Streak: 5 days") {
    StreakBadgeView(
        currentStreak: 5,
        longestStreak: 7,
        freezesAvailable: 1
    ) {
        // Preview action placeholder
    }
    .padding()
}

#Preview("Streak: 28 days") {
    StreakBadgeView(
        currentStreak: 28,
        longestStreak: 28,
        freezesAvailable: 1
    ) {
        // Preview action placeholder
    }
    .padding()
}
