import SwiftUI

/// Badge size options
enum BadgeSize {
    case small
    case medium
    case large

    var dimension: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 80
        case .large: return 120
        }
    }

    var iconScale: CGFloat {
        switch self {
        case .small: return 0.6
        case .medium: return 0.8
        case .large: return 1.0
        }
    }
}

/// Achievement badge view component
struct AchievementBadgeView: View {
    let badge: AchievementDefinition
    let progress: AchievementProgress?
    let size: BadgeSize
    var onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: size == .small ? 4 : 8) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isUnlocked ? unlockedGradient : lockedGradient)
                        .frame(width: size.dimension, height: size.dimension)

                    // Progress ring for locked badges
                    if !isUnlocked, let progress = progress?.progress {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: size.dimension, height: size.dimension)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    gradient: gradientColors,
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: size.dimension, height: size.dimension)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }

                    // Icon
                    Image(systemName: badge.iconName)
                        .font(.system(size: size.dimension * iconScale))
                        .foregroundColor(iconColor)
                        .opacity(isUnlocked ? 1.0 : 0.4)

                    // Lock overlay for locked badges
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: size.dimension * 0.25))
                            .foregroundColor(.white)
                            .opacity(0.8)
                    }
                }
                .shadow(color: shadowColor, radius: isUnlocked ? 8 : 2)

                // Title and progress
                if size != .small {
                    VStack(spacing: 2) {
                        Text(badge.title)
                            .font(.system(size: size == .medium ? 12 : 14, weight: .semibold))
                            .foregroundColor(isUnlocked ? .primary : .secondary)
                            .lineLimit(1)

                        if !isUnlocked, let progress = progress?.progress {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isUnlocked ? "已解锁" : "未解锁，点击查看详情")
    }

    // MARK: - Computed Properties

    private var isUnlocked: Bool {
        progress?.isUnlocked == true
    }

    private var iconScale: CGFloat {
        size.iconScale
    }

    private var unlockedGradient: LinearGradient {
        LinearGradient(
            colors: categoryColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lockedGradient: LinearGradient {
        LinearGradient(
            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradientColors: Gradient {
        Gradient(colors: categoryColors)
    }

    private var categoryColors: [Color] {
        switch badge.category {
        case .streaks:
            return [.orange, .red]
        case .completeness:
            return [.blue, .purple]
        case .social:
            return [.green, .mint]
        case .knowledge:
            return [.yellow, .orange]
        }
    }

    private var iconColor: Color {
        isUnlocked ? .white : .gray
    }

    private var shadowColor: Color {
        isUnlocked ? categoryColors.first?.opacity(0.5) ?? .clear : .clear
    }

    private var accessibilityLabel: String {
        var label = badge.title
        label += isUnlocked ? "，已解锁" : "，未解锁"
        if !isUnlocked, let progress = progress?.progress {
            label += "，进度\(Int(progress * 100))%"
        }
        return label
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AchievementBadgeView(
                badge: AchievementDefinitions.allBadges[0],
                progress: AchievementProgress(achievementID: "test"),
                size: .small
            )

            AchievementBadgeView(
                badge: AchievementDefinitions.allBadges[0],
                progress: {
                    let p = AchievementProgress(achievementID: "test")
                    p.isUnlocked = true
                    p.progress = 1.0
                    return p
                }(),
                size: .medium
            )

            AchievementBadgeView(
                badge: AchievementDefinitions.allBadges[0],
                progress: {
                    let p = AchievementProgress(achievementID: "test")
                    p.progress = 0.5
                    return p
                }(),
                size: .large
            )
        }
    }
    .padding()
}
