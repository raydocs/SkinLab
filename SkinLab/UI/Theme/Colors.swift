import SwiftUI

// MARK: - 浪漫粉紫金色系 Color System
extension Color {
    // MARK: - 清新高级感 Color System (Fresh & Airy)
    
    // 清新主色 - 薄荷绿/青色系
    static let freshPrimary = Color(red: 0.24, green: 0.76, blue: 0.68) // 清新薄荷绿
    static let freshPrimaryLight = Color(red: 0.85, green: 0.96, blue: 0.94) // 极淡薄荷背景
    static let freshPrimaryDark = Color(red: 0.15, green: 0.55, blue: 0.48) // 深薄荷绿

    // 清新辅色 - 天空蓝/淡紫系
    static let freshSecondary = Color(red: 0.45, green: 0.68, blue: 0.92) // 清透天空蓝
    static let freshSecondaryLight = Color(red: 0.90, green: 0.95, blue: 0.99) // 极淡蓝背景
    static let freshAccent = Color(red: 0.98, green: 0.85, blue: 0.55) // 淡雅暖黄

    // 玻璃质感背景色
    static let freshWhite = Color(red: 0.99, green: 0.99, blue: 1.0) // 纯净白
    static let freshBackground = Color(red: 0.98, green: 0.99, blue: 0.99) // 极淡灰白背景
    
    // 暗黑模式适配
    static let freshBackgroundDark = Color(red: 0.08, green: 0.10, blue: 0.12)
    static let freshCardDark = Color(red: 0.12, green: 0.15, blue: 0.18)

    // MARK: - Legacy Compatibility (Mapped to New Theme)
    
    static let romanticPink = freshPrimary
    static let romanticPinkLight = freshPrimaryLight
    static let romanticPinkDark = freshPrimaryDark

    static let romanticPurple = freshSecondary
    static let romanticPurpleLight = freshSecondaryLight
    static let romanticPurpleDark = Color(red: 0.30, green: 0.50, blue: 0.75)

    static let romanticGold = freshAccent
    static let romanticGoldLight = Color(red: 1.0, green: 0.95, blue: 0.85)
    static let romanticCream = freshBackground
    static let romanticWhite = freshWhite

    static let romanticCreamDark = freshBackgroundDark
    static let romanticWhiteDark = freshCardDark
    static let romanticTextDark = Color(red: 0.94, green: 0.96, blue: 0.98)
    static let romanticSubtextDark = Color(red: 0.60, green: 0.65, blue: 0.70)

    static let romanticGradientStart = freshPrimaryLight
    static let romanticGradientEnd = freshSecondaryLight

    // Brand Colors
    static let skinLabPrimary = Color.freshPrimary
    static let skinLabSecondary = Color.freshSecondary
    static let skinLabAccent = Color.freshAccent
    static let skinLabMint = Color.freshPrimary
    static let skinLabGradientStart = Color.freshPrimaryLight
    static let skinLabGradientEnd = Color.freshSecondaryLight
    static let skinLabLavenderStart = Color.freshSecondaryLight
    static let skinLabLavenderEnd = Color.freshPrimaryLight

    // Base Colors
    static let skinLabBackground = Color.freshBackground
    static let skinLabCardBackground = Color.freshWhite
    static let skinLabText = Color(red: 0.15, green: 0.20, blue: 0.25) // 深灰蓝
    static let skinLabSubtext = Color(red: 0.50, green: 0.55, blue: 0.60) // 中灰蓝

    // MARK: - 暗黑模式自适应颜色

    /// 根据颜色模式返回适当的背景色
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .romanticCreamDark : .romanticCream
    }

    /// 根据颜色模式返回适当的卡片背景色
    static func adaptiveCardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .romanticWhiteDark : .romanticWhite
    }

    /// 根据颜色模式返回适当的文字色
    static func adaptiveText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .romanticTextDark : Color(red: 0.25, green: 0.25, blue: 0.28)
    }

    /// 根据颜色模式返回适当的副文字色
    static func adaptiveSubtext(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .romanticSubtextDark : Color(red: 0.55, green: 0.55, blue: 0.58)
    }

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
    // 清新渐变系统
    static let skinLabRoseGradient = LinearGradient(
        colors: [Color.freshPrimaryLight, Color.freshPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let skinLabLavenderGradient = LinearGradient(
        colors: [Color.freshSecondaryLight, Color.freshSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let skinLabPrimaryGradient = LinearGradient(
        colors: [Color.freshPrimary, Color.freshSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let skinLabGoldGradient = LinearGradient(
        colors: [Color.freshAccent.opacity(0.6), Color.freshAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let romanticBlushGradient = LinearGradient(
        colors: [Color.freshPrimaryLight.opacity(0.5), Color.freshSecondaryLight.opacity(0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let romanticSunsetGradient = LinearGradient(
        colors: [Color.freshAccent, Color.freshPrimaryLight, Color.freshSecondaryLight],
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
