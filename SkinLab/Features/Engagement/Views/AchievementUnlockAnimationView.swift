import SwiftUI

/// Achievement unlock celebration animation
struct AchievementUnlockAnimationView: View {
    let badge: AchievementDefinition
    let isVisible: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var glowIntensity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Badge
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    categoryColor.opacity(0.8 * glowIntensity),
                                    categoryColor.opacity(0.4 * glowIntensity),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)

                    // Badge
                    AchievementBadgeView(
                        badge: badge,
                        progress: {
                            let p = AchievementProgress(achievementID: badge.id)
                            p.isUnlocked = true
                            p.progress = 1.0
                            return p
                        }(),
                        size: .large
                    ) {}
                    .scaleEffect(scale)
                }

                // Text
                VStack(spacing: 8) {
                    Text("成就解锁!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(badge.title)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Dismiss button
                Button(action: dismiss) {
                    Text("太棒了!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .opacity(opacity)
        }
        .onAppear {
            playAnimation()
        }
        .accessibilityIdentifier("achievement_unlock_animation")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("成就解锁动画，\(badge.title)")
    }

    // MARK: - Animation

    private func playAnimation() {
        // Haptic feedback
        if !reduceMotion {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        if reduceMotion {
            // Simplified animation for reduced motion
            opacity = 1
            scale = 1.0
        } else {
            // Full animation sequence
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }

            // Glow animation
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                glowIntensity = 1.0
            }

            // Confetti
            showConfetti = true
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    // MARK: - Computed Properties

    private var categoryColor: Color {
        switch badge.category {
        case .streaks:
            return .orange
        case .completeness:
            return .blue
        case .social:
            return .green
        case .knowledge:
            return .yellow
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: View {
    let position: CGPoint
    let color: Color
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(x: position.x - UIScreen.main.bounds.width / 2,
                    y: position.y - UIScreen.main.bounds.height / 2 + offset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 2).delay(Double.random(in: 0...0.3))) {
                    offset = UIScreen.main.bounds.height / 2 + 100
                }

                withAnimation(.linear(duration: 2).delay(Double.random(in: 0...0.3))) {
                    rotation = Double.random(in: 0...720)
                }

                withAnimation(.easeOut(duration: 1).delay(Double.random(in: 0...0.5))) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    AchievementUnlockAnimationView(
        badge: AchievementDefinitions.allBadges[0],
        isVisible: true
    ) {
        // Preview action placeholder
    }
}
