import SwiftUI

/// Milestone streak celebration view
struct StreakCelebrationView: View {
    let milestone: Int
    let isVisible: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var counterValue: Int = 0

    private let milestones = [7, 14, 28]

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

                // Milestone number with animation
                VStack(spacing: 16) {
                    Text("\(counterValue)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(value: Double(counterValue)))
                        .scaleEffect(scale)

                    Text("天连续打卡!")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text(milestoneMessage)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Dismiss button
                Button(action: dismiss) {
                    Text("继续")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
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
        .accessibilityIdentifier("streak_celebration")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("连续打卡里程碑，\(milestone)天")
    }

    // MARK: - Animation

    private func playAnimation() {
        // Haptic feedback
        if !reduceMotion {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Multiple haptics for big milestones
            if milestone == 28 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    generator.notificationOccurred(.success)
                }
            }
        }

        if reduceMotion {
            // Simplified animation
            opacity = 1
            scale = 1.0
            counterValue = milestone
        } else {
            // Full animation sequence
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
            }

            // Scale up
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                scale = 1.2
            }

            // Count up animation
            animateCounter(from: 0, to: milestone, duration: 1.5)

            // Scale to final
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }

            // Confetti
            showConfetti = true
        }
    }

    private func animateCounter(from: Int, to: Int, duration: Double) {
        let steps = Double(to - from)
        let stepDuration = duration / steps

        for i in from..<to {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                withAnimation(.easeOut(duration: stepDuration * 0.8)) {
                    counterValue = i + 1
                }
            }
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

    private var milestoneMessage: String {
        switch milestone {
        case 7:
            return "你已经坚持了一周！继续保持这个势头！"
        case 14:
            return "两周了！你正在建立一个很好的习惯！"
        case 28:
            return "28天！你完成了整个护肤周期！太棒了！"
        default:
            return "太棒了！继续保持！"
        }
    }
}

#Preview("7 days") {
    StreakCelebrationView(
        milestone: 7,
        isVisible: true
    ) {
        // Preview action placeholder
    }
}

#Preview("28 days") {
    StreakCelebrationView(
        milestone: 28,
        isVisible: true
    ) {
        // Preview action placeholder
    }
}
