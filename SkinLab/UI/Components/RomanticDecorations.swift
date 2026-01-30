import SwiftUI

// MARK: - 浪漫风格装饰组件

struct FlowerPetalView: View {
    var size: CGFloat = 60
    var color: Color = .freshPrimaryLight
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        Image(systemName: "flower.fill")
            .font(.system(size: size * 0.8))
            .foregroundColor(color.opacity(0.15))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .blur(radius: size * 0.1)
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
            }
            .accessibilityHidden(true)
    }
}

struct HeartFloatingView: View {
    var size: CGFloat = 40
    var color: Color = .freshPrimary
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.6

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundColor(color.opacity(opacity))
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) {
                    offset = -60
                    opacity = 0
                }
            }
            .accessibilityHidden(true)
    }
}

struct RosePetalDecoration: View {
    let count: Int
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        ZStack {
            ForEach(0 ..< count, id: \.self) { index in
                RosePetal(
                    size: CGFloat.random(in: 30 ... 70),
                    rotation: Double(index) * (360 / Double(count)),
                    distance: CGFloat.random(in: 40 ... 100),
                    color: index % 2 == 0 ? primaryColor : secondaryColor
                )
                .opacity(Double.random(in: 0.15 ... 0.4))
                .rotationEffect(.degrees(Double.random(in: -30 ... 30)))
            }
        }
        .accessibilityHidden(true)
    }
}

struct RosePetal: View {
    let size: CGFloat
    let rotation: Double
    let distance: CGFloat
    let color: Color
    @State private var currentRotation: Double = 0

    var body: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: size))
            .foregroundColor(color)
            .rotationEffect(.degrees(rotation))
            .offset(x: distance * cos(rotation * .pi / 180), y: distance * sin(rotation * .pi / 180))
            .rotationEffect(.degrees(currentRotation))
            .onAppear {
                withAnimation(.easeInOut(duration: Double.random(in: 6 ... 10)).repeatForever(autoreverses: true)) {
                    currentRotation = 10
                }
            }
    }
}

struct RomanticCornerDecoration: View {
    var corner: UIRectCorner = [.topLeft]
    @State private var animated = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.freshPrimaryLight.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(
                    x: corner.contains(.topLeft) ? -50 : (corner.contains(.topRight) ? 50 : 0),
                    y: corner.contains(.topLeft) ? -50 : (corner.contains(.bottomLeft) ? 50 : 0)
                )

            FlowerPetalView(size: 50, color: .freshPrimary)
                .offset(
                    x: corner.contains(.topLeft) ? -40 : (corner.contains(.topRight) ? 40 : 0),
                    y: corner.contains(.topLeft) ? -40 : (corner.contains(.bottomLeft) ? 40 : 0)
                )

            HeartFloatingView(size: 30, color: .freshSecondary)
                .offset(
                    x: corner.contains(.topLeft) ? -60 : (corner.contains(.topRight) ? 60 : 0),
                    y: corner.contains(.topLeft) ? -20 : (corner.contains(.bottomLeft) ? 20 : 0)
                )
        }
        .accessibilityHidden(true)
    }
}

struct SparkleRomanticView: View {
    let size: CGFloat
    var color: Color = .freshAccent
    @State private var opacity: Double = 0.4
    @State private var scale: CGFloat = 0.7

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(color)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                    scale = 1.4
                }
            }
            .accessibilityHidden(true)
    }
}

struct RomanticBorder: ViewModifier {
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .freshPrimary.opacity(0.4),
                                .freshSecondary.opacity(0.4),
                                .freshAccent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
}

extension View {
    func romanticBorder(lineWidth: CGFloat = 1.5, cornerRadius: CGFloat = 20) -> some View {
        modifier(RomanticBorder(lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
}

struct RomanticGradientCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.freshWhite.opacity(0.9), .freshBackground.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.freshPrimary.opacity(0.3), .freshSecondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .freshPrimary.opacity(0.1), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func romanticGradientCard() -> some View {
        modifier(RomanticGradientCard())
    }
}
