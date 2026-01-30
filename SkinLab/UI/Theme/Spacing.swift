import SwiftUI

// MARK: - 间距系统 - 8pt基础网格

enum Spacing {
    // 基础间距
    static let xs: CGFloat = 4 // 极小间距
    static let sm: CGFloat = 8 // 小间距
    static let md: CGFloat = 12 // 中间距
    static let lg: CGFloat = 16 // 标准间距
    static let xl: CGFloat = 20 // 大间距
    static let xl2: CGFloat = 24 // 超大间距
    static let xl3: CGFloat = 32 // 特大间距
    static let xl4: CGFloat = 48 // 巨大间距
    static let xl5: CGFloat = 64 // 最大间距

    // 组件内边距
    static let cardPadding: CGFloat = lg
    static let buttonPadding: (horizontal: CGFloat, vertical: CGFloat) = (lg, md)
    static let sectionPadding: CGFloat = xl2

    // 卡片间距
    static let cardSpacing: CGFloat = lg
    static let cardRowSpacing: CGFloat = md

    // 章节间距
    static let sectionSpacing: CGFloat = xl3
    static let sectionTitleSpacing: CGFloat = md

    /// 列表项间距
    static let listItemSpacing: CGFloat = md

    // 圆角
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 20
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusXL: CGFloat = 28
}

// MARK: - 字体排版系统 - 浪漫风格优化

enum Typography {
    // 字体层级
    static let largeTitle = Font.system(size: 36, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 14, weight: .regular, design: .rounded)
    static let footnote = Font.system(size: 12, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 11, weight: .medium, design: .rounded)

    // 特殊字体
    static let scoreLarge = Font.system(size: 56, weight: .black, design: .rounded)
    static let scoreMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    static let scoreSmall = Font.system(size: 26, weight: .bold, design: .rounded)

    // 行高
    static let lineHeightTitle: CGFloat = 1.2
    static let lineHeightBody: CGFloat = 1.5
    static let lineHeightCaption: CGFloat = 1.3
}

// MARK: - 间距扩展

extension View {
    func paddingS() -> some View {
        padding(Spacing.sm)
    }

    func paddingM() -> some View {
        padding(Spacing.md)
    }

    func paddingL() -> some View {
        padding(Spacing.lg)
    }

    func paddingXL() -> some View {
        padding(Spacing.xl)
    }

    func horizontalSpacing(_ spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            self
        }
    }

    func verticalSpacing(_ spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            self
        }
    }
}

// MARK: - 快捷排版修饰符

struct CompactSpacingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.romanticWhite)
            .cornerRadius(Spacing.cornerRadiusMedium)
            .shadow(color: .romanticPink.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

struct ComfortableSpacingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.xl2)
            .background(Color.romanticWhite)
            .cornerRadius(Spacing.cornerRadiusLarge)
            .shadow(color: .romanticPink.opacity(0.08), radius: 14, x: 0, y: 7)
    }
}

extension View {
    func compactCard() -> some View {
        modifier(CompactSpacingModifier())
    }

    func comfortableCard() -> some View {
        modifier(ComfortableSpacingModifier())
    }
}

// MARK: - 排版辅助工具

extension Text {
    func romanticStyle() -> Text {
        self
            .font(Typography.body)
            .foregroundColor(.skinLabText)
    }

    func romanticHeading() -> Text {
        self
            .font(Typography.title3)
            .foregroundStyle(
                LinearGradient(
                    colors: [.romanticPink, .romanticPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    func romanticCaption() -> Text {
        self
            .font(Typography.caption)
            .foregroundColor(.skinLabSubtext)
    }
}

// MARK: - 布局系统辅助

enum LayoutMetrics {
    // 屏幕尺寸相关
    static let cardAspectRatio: CGFloat = 1.2
    static let imageAspectRatio: CGFloat = 0.8

    // 动画时长
    static let animationFast: Double = 0.25
    static let animationNormal: Double = 0.35
    static let animationSlow: Double = 0.5

    // 弹簧动画参数
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.65

    // 缩放效果
    static let pressedScale: CGFloat = 0.97
    static let hoverScale: CGFloat = 1.02
}
