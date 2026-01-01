import SwiftUI

// MARK: - Fonts (Enhanced Hierarchy)
extension Font {
    static let skinLabLargeTitle = Font.system(size: 36, weight: .heavy, design: .rounded)
    static let skinLabTitle = Font.system(size: 30, weight: .heavy, design: .rounded)
    static let skinLabTitle2 = Font.system(size: 24, weight: .bold, design: .rounded)
    static let skinLabTitle3 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let skinLabHeadline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let skinLabBody = Font.system(size: 17, weight: .medium, design: .rounded)
    static let skinLabCallout = Font.system(size: 16, weight: .medium, design: .rounded)
    static let skinLabSubheadline = Font.system(size: 15, weight: .medium, design: .rounded)
    static let skinLabFootnote = Font.system(size: 13, weight: .medium, design: .rounded)
    static let skinLabCaption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let skinLabScoreLarge = Font.system(size: 56, weight: .black, design: .rounded)
    static let skinLabScoreMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    static let skinLabScoreSmall = Font.system(size: 26, weight: .bold, design: .rounded)
}

// MARK: - Card Styles
struct SkinLabCardStyle: ViewModifier {
    var elevated: Bool = false
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(24)
            .shadow(color: Color.skinLabPrimary.opacity(elevated ? 0.12 : 0.06), radius: elevated ? 20 : 12, x: 0, y: elevated ? 10 : 6)
    }
}

struct SkinLabGlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
    }
}

struct SkinLabPremiumCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 24).fill(.regularMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(colors: [Color.skinLabPrimary.opacity(0.2), Color.skinLabSecondary.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.skinLabPrimary.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Button Styles (浪漫风格)
struct SkinLabPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.skinLabHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.freshPrimary, Color.freshPrimary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .cornerRadius(22)
            .shadow(color: Color.freshPrimary.opacity(0.25), radius: configuration.isPressed ? 6 : 14, x: 0, y: configuration.isPressed ? 3 : 7)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct SkinLabSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.skinLabHeadline)
            .foregroundColor(.freshPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Color.white.opacity(0.6)
            )
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct SkinLabGradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .skinLabRoseGradient
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.skinLabHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(gradient.opacity(configuration.isPressed ? 0.85 : 1.0))
            .cornerRadius(22)
            .shadow(color: Color.freshPrimary.opacity(0.25), radius: configuration.isPressed ? 6 : 14, x: 0, y: configuration.isPressed ? 3 : 7)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct SkinLabIconButtonStyle: ButtonStyle {
    var size: CGFloat = 52
    var backgroundColor: Color = Color.freshPrimary.opacity(0.1)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.freshPrimary)
            .frame(width: size, height: size)
            .background(
                backgroundColor
            )
            .clipShape(Circle())
            .shadow(color: Color.freshPrimary.opacity(0.1), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func skinLabCard(elevated: Bool = false) -> some View {
        modifier(SkinLabCardStyle(elevated: elevated))
    }

    func skinLabGlassCard() -> some View {
        modifier(FreshGlassCard())
    }

    func skinLabPremiumCard() -> some View {
        modifier(FreshGlassCard())
    }

    func skinLabSoftShadow(radius: CGFloat = 12, y: CGFloat = 6) -> some View {
        shadow(color: Color.black.opacity(0.04), radius: radius, x: 0, y: y)
    }

    func skinLabGradientBorder(lineWidth: CGFloat = 2, cornerRadius: CGFloat = 20) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    Color.freshPrimary.opacity(0.3),
                    lineWidth: lineWidth
                )
        )
    }
}

// MARK: - Decorative Elements (浪漫风格)
struct SparkleView: View {
    let size: CGFloat
    @State private var opacity: Double = 0.3
    @State private var scale: CGFloat = 0.8

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundStyle(LinearGradient.romanticSunsetGradient)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                    scale = 1.4
                }
            }
    }
}

struct FloatingBubble: View {
    let size: CGFloat
    let color: Color
    @State private var offset: CGFloat = 0
    @State private var horizontalOffset: CGFloat = 0

    var body: some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: size, height: size)
            .blur(radius: size / 3)
            .offset(x: horizontalOffset, y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    offset = -35
                    horizontalOffset = 18
                }
            }
    }
}

// MARK: - Animated Background (浪漫风格)
struct AnimatedGradientBackground: View {
    @State private var animated = false

    var body: some View {
        ZStack {
            Color.romanticCream.ignoresSafeArea()

            Circle()
                .fill(LinearGradient.romanticBlushGradient)
                .frame(width: 350, height: 350)
                .blur(radius: 130)
                .offset(x: animated ? 50 : -100, y: animated ? -100 : -200)
                .opacity(0.35)

            Circle()
                .fill(LinearGradient.romanticSunsetGradient)
                .frame(width: 280, height: 280)
                .blur(radius: 110)
                .offset(x: animated ? -80 : 120, y: animated ? 150 : 50)
                .opacity(0.3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animated = true
            }
        }
    }
}

// MARK: - Premium Score Ring (浪漫风格)
struct PremiumScoreRing: View {
    let score: Int
    let size: CGFloat
    var lineWidth: CGFloat = 16

    private var color: Color {
        Color.scoreColor(for: score)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.4), value: score)

            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: size * 0.45, weight: .light, design: .rounded))
                    .foregroundStyle(color)
                Text("综合评分")
                    .font(.system(size: size * 0.1, weight: .medium, design: .rounded))
                    .foregroundColor(.skinLabSubtext)
            }
        }
    }
}

// MARK: - Staggered Animation (浪漫风格)
struct StaggeredAnimationModifier: ViewModifier {
    let delay: Double
    @State private var visible = false
    @State private var scale: CGFloat = 0.9

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 25)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(delay)) {
                    visible = true
                    scale = 1.0
                }
            }
    }
}

extension View {
    func staggered(delay: Double) -> some View {
        modifier(StaggeredAnimationModifier(delay: delay))
    }
}
