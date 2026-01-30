import Charts
import SwiftUI

// MARK: - Share Card Renderer

@MainActor
final class ShareCardRenderer {
    func render(_ view: some View) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - Share Card View

struct ShareCardView: View {
    let report: EnhancedTrackingReport

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Main Stats
            statsSection

            // Chart Preview
            chartSection

            // Footer
            footerSection
        }
        .frame(width: 400, height: 700)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "FFF5F7"),
                    Color(hex: "FFF0F5"),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            // Background
            LinearGradient.skinLabRoseGradient
                .frame(height: 120)

            VStack(spacing: 8) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(LinearGradient.skinLabRoseGradient)
                }

                Text("SkinLab 追踪报告")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(report.duration) 天护肤追踪")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 20) {
            ShareStatCard(
                value: report.scoreChange > 0 ? "+\(report.scoreChange)" : "\(report.scoreChange)",
                label: "评分变化",
                color: report.scoreChange > 0 ? Color.skinLabSuccess : Color.skinLabError
            )

            ShareStatCard(
                value: report.skinAgeChange > 0 ? "+\(report.skinAgeChange)" : "\(report.skinAgeChange)",
                label: "皮肤年龄",
                color: report.skinAgeChange < 0 ? Color.skinLabSuccess : Color.skinLabError
            )

            ShareStatCard(
                value: "\(Int(report.completionRate * 100))%",
                label: "完成度",
                color: Color.skinLabPrimary
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    // MARK: - Chart Preview

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("改善趋势")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Color.skinLabText)
                .padding(.horizontal, 20)

            // Mini chart
            if !report.timeline.isEmpty {
                Chart(report.timeline.prefix(5)) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Score", point.overallScore)
                    )
                    .foregroundStyle(LinearGradient.skinLabRoseGradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("Score", point.overallScore)
                    )
                    .foregroundStyle(LinearGradient.skinLabRoseGradient.opacity(0.3))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 150)
                .padding(.horizontal, 20)
            }

            // Improvement Label
            HStack {
                Spacer()
                Text(report.improvementLabel)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.skinLabRoseGradient)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.skinLabPrimary.opacity(0.15))
                    .cornerRadius(20)
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            // Top Improvements
            if let topImprovement = report.topImprovements.first {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.skinLabAccent)
                    Text("\(topImprovement.dimension) 改善 \(Int(topImprovement.improvement))%")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.skinLabText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.skinLabAccent.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()

            // QR or App Promotion
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("用 SkinLab 追踪你的护肤效果")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color.skinLabSubtext)

                Text("科学护肤·效果可见")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(Color.skinLabSubtext.opacity(0.7))
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}

// MARK: - Share Stat Card

struct ShareStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.skinLabSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
