import SwiftUI

// MARK: - Fresh Glassmorphism Modifiers

struct FreshGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 15
    var shadowOpacity: Double = 0.04

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial) // Native frosted glass
            .background(Color.freshWhite.opacity(0.4)) // Tint
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 5) // Soft shadow
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct FreshGlassButton: ButtonStyle {
    var color: Color = .freshPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.skinLabHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(28)
            .shadow(color: color.opacity(0.25), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FreshSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.skinLabHeadline)
            .foregroundColor(.skinLabText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(0.6))
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func freshGlassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(FreshGlassCard(cornerRadius: cornerRadius))
    }

    func freshGradientForeground(colors: [Color] = [.freshPrimary, .freshSecondary]) -> some View {
        self.overlay(
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .mask(self)
        )
    }
}

// MARK: - Decorative Elements

struct FreshBackgroundMesh: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.freshBackground.ignoresSafeArea()

            // Mint Blob
            Circle()
                .fill(Color.freshPrimaryLight)
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: animate ? -100 : 0, y: animate ? -200 : -300)
                .opacity(0.4)

            // Blue Blob
            Circle()
                .fill(Color.freshSecondaryLight)
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: animate ? 150 : 200, y: animate ? 100 : 200)
                .opacity(0.3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
