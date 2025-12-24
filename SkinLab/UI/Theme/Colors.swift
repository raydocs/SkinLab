import SwiftUI

// MARK: - 浪漫粉紫金色系 Color System
extension Color {
    // 主色调 - 浪漫粉紫
    static let romanticPink = Color(red: 1.0, green: 0.68, blue: 0.78)
    static let romanticPinkLight = Color(red: 1.0, green: 0.82, blue: 0.87)
    static let romanticPinkDark = Color(red: 1.0, green: 0.52, blue: 0.68)

    static let romanticPurple = Color(red: 0.78, green: 0.65, blue: 0.95)
    static let romanticPurpleLight = Color(red: 0.88, green: 0.82, blue: 0.98)
    static let romanticPurpleDark = Color(red: 0.65, green: 0.50, blue: 0.88)

    // 辅助色 - 优雅金与白
    static let romanticGold = Color(red: 1.0, green: 0.85, blue: 0.65)
    static let romanticGoldLight = Color(red: 1.0, green: 0.92, blue: 0.80)
    static let romanticCream = Color(red: 1.0, green: 0.98, blue: 0.96)
    static let romanticWhite = Color(red: 1.0, green: 0.99, blue: 0.98)

    // 渐变色起点
    static let romanticGradientStart = Color(red: 1.0, green: 0.85, blue: 0.90)
    static let romanticGradientEnd = Color(red: 0.92, green: 0.82, blue: 0.95)

    // 品牌色 (兼容原有API)
    static let skinLabPrimary = Color.romanticPink
    static let skinLabSecondary = Color.romanticPurple
    static let skinLabAccent = Color.romanticGold
    static let skinLabMint = Color(red: 0.72, green: 0.88, blue: 0.82)
    static let skinLabGradientStart = Color.romanticPinkLight
    static let skinLabGradientEnd = Color.romanticPurpleLight
    static let skinLabLavenderStart = Color.romanticPurpleLight
    static let skinLabLavenderEnd = Color.romanticPinkLight
    static let skinLabBackground = Color.romanticCream
    static let skinLabCardBackground = Color.romanticWhite
    static let skinLabText = Color(red: 0.25, green: 0.25, blue: 0.28)
    static let skinLabSubtext = Color(red: 0.55, green: 0.55, blue: 0.58)

    // 语义色 - 浪漫风格
    static let skinLabSuccess = Color(red: 0.60, green: 0.88, blue: 0.75)
    static let skinLabWarning = Color(red: 1.0, green: 0.78, blue: 0.55)
    static let skinLabError = Color(red: 1.0, green: 0.60, blue: 0.65)
    static let skinLabScoreExcellent = Color(red: 0.60, green: 0.88, blue: 0.75)
    static let skinLabScoreGood = Color(red: 0.82, green: 0.88, blue: 0.95)
    static let skinLabScoreFair = Color(red: 1.0, green: 0.88, blue: 0.70)
    static let skinLabScorePoor = Color(red: 1.0, green: 0.78, blue: 0.68)
    static let skinLabScoreBad = Color(red: 1.0, green: 0.60, blue: 0.65)
    
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .skinLabScoreExcellent
        case 60..<80: return .skinLabScoreGood
        case 40..<60: return .skinLabScoreFair
        case 20..<40: return .skinLabScorePoor
        default: return .skinLabScoreBad
        }
    }
}

extension LinearGradient {
    // 浪漫渐变系统
    static let skinLabRoseGradient = LinearGradient(
        colors: [Color.romanticPinkLight, Color.romanticPinkDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let skinLabLavenderGradient = LinearGradient(
        colors: [Color.romanticPurpleLight, Color.romanticPurpleDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let skinLabPrimaryGradient = LinearGradient(
        colors: [Color.romanticPink, Color.romanticPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let skinLabGoldGradient = LinearGradient(
        colors: [Color.romanticGoldLight, Color.romanticGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let romanticBlushGradient = LinearGradient(
        colors: [Color.romanticPinkLight, Color.romanticPink, Color.romanticPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let romanticSunsetGradient = LinearGradient(
        colors: [Color.romanticGold, Color.romanticPink, Color.romanticPurpleLight],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )

    // Accent gradient for tracking reports
    static let skinLabAccentGradient = LinearGradient(
        colors: [Color.skinLabAccent, Color.skinLabAccent.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Success gradient (green tones)
    static let skinLabSuccessGradient = LinearGradient(
        colors: [Color.skinLabSuccess, Color.skinLabSuccess.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Warning gradient (orange/yellow tones)
    static let skinLabWarningGradient = LinearGradient(
        colors: [Color.orange, Color.orange.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
