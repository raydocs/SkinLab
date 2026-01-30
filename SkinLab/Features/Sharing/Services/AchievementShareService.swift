import SwiftUI

/// Service for generating shareable achievement images
@MainActor
final class AchievementShareService {
    // MARK: - Constants

    private let imageSize = CGSize(width: 1080, height: 1080)
    private let cardPadding: CGFloat = 80
    private let cornerRadius: CGFloat = 40

    // MARK: - Public Methods

    /// Generate share image for an achievement badge
    /// - Parameters:
    ///   - badge: The achievement definition
    ///   - streak: Current streak count (optional)
    /// - Returns: UIImage for sharing
    func generateShareImage(for badge: AchievementDefinition, streak: Int? = nil) -> UIImage? {
        let renderer = ImageRenderer(content: shareCard(badge: badge, streak: streak))
        renderer.scale = 3 // For high resolution
        renderer.proposedSize = ProposedViewSize(imageSize)
        return renderer.uiImage
    }

    /// Generate share image for streak milestone
    /// - Parameter milestone: The milestone number (7, 14, 28)
    /// - Returns: UIImage for sharing
    func generateStreakShareImage(for milestone: Int) -> UIImage? {
        let renderer = ImageRenderer(content: streakCard(milestone: milestone))
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(imageSize)
        return renderer.uiImage
    }

    // MARK: - Card Views

    private func shareCard(badge: AchievementDefinition, streak: Int?) -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.4, blue: 0.6),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("SkinLab")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                // Badge icon
                ZStack {
                    Circle()
                        .fill(cardBackgroundGradient)
                        .frame(width: 300, height: 300)

                    Image(systemName: badge.iconName)
                        .font(.system(size: 120))
                        .foregroundColor(.white)
                }
                .shadow(color: .white.opacity(0.3), radius: 20)

                // Badge info
                VStack(spacing: 12) {
                    Text(badge.title)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text(badge.description)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Streak info (if provided)
                if let streak {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("连续打卡 \(streak) 天")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                // CTA
                VStack(spacing: 8) {
                    Text("用 AI 发现你的肌肤之美")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Download SkinLab")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 40)
            }
            .padding(cardPadding)
        }
        .frame(width: imageSize.width, height: imageSize.height)
    }

    private func streakCard(milestone: Int) -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.4, blue: 0.3),
                    Color(red: 1.0, green: 0.6, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.white)

                    Text("SkinLab")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }

                // Milestone number
                VStack(spacing: 16) {
                    Text("\(milestone)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("天连续打卡")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Milestone message
                Text(milestoneMessage(for: milestone))
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)

                Spacer()

                // CTA
                Text("Download SkinLab")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
            .padding(cardPadding)
        }
        .frame(width: imageSize.width, height: imageSize.height)
    }

    // MARK: - Helper Methods

    private var cardBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.3, blue: 1.0),
                Color(red: 0.6, green: 0.4, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func milestoneMessage(for milestone: Int) -> String {
        switch milestone {
        case 7:
            "一周坚持，美丽可见"
        case 14:
            "两周养成，习惯成自然"
        case 28:
            "28天周期，蜕变完成"
        default:
            "继续加油，保持美丽"
        }
    }
}

#Preview {
    VStack {
        Image(uiImage: AchievementShareService().generateShareImage(
            for: AchievementDefinitions.allBadges[0],
            streak: 7
        ) ?? UIImage())
            .frame(width: 400, height: 400)
    }
}
