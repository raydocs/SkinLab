import SwiftUI

// MARK: - Key Metric Card

/// A visually prominent card for displaying key metrics.
/// Uses large font, high contrast, and gradient styling for emphasis.
struct KeyMetricCard: View {
    let value: String
    let label: String
    let icon: String
    let trend: TrendDirection?
    let trendLabel: String?
    let gradient: LinearGradient

    enum TrendDirection {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .skinLabSuccess
            case .down: return .skinLabError
            case .neutral: return .skinLabSubtext
            }
        }
    }

    init(
        value: String,
        label: String,
        icon: String,
        trend: TrendDirection? = nil,
        trendLabel: String? = nil,
        gradient: LinearGradient = .skinLabPrimaryGradient
    ) {
        self.value = value
        self.label = label
        self.icon = icon
        self.trend = trend
        self.trendLabel = trendLabel
        self.gradient = gradient
    }

    var body: some View {
        VStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(gradient)
            }

            // Primary value - large and prominent
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.skinLabText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Label
            Text(label)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabSubtext)

            // Trend indicator (optional)
            if let trend = trend, let trendLabel = trendLabel {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(trendLabel)
                        .font(.skinLabCaption)
                }
                .foregroundColor(trend.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(trend.color.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityValue(trendLabel ?? "")
    }
}

// MARK: - Summary Stat Row

/// A compact horizontal stat row for secondary metrics
struct SummaryStatRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    init(
        icon: String,
        label: String,
        value: String,
        iconColor: Color = .skinLabPrimary
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            // Label
            Text(label)
                .font(.skinLabBody)
                .foregroundColor(.skinLabText)

            Spacer()

            // Value
            Text(value)
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Progressive Disclosure Card

/// A card that shows a summary and reveals details on tap
struct ProgressiveDisclosureCard<Summary: View, Detail: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let summary: () -> Summary
    @ViewBuilder let detail: () -> Detail

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                        .frame(width: 24)

                    Text(title)
                        .font(.skinLabTitle3)
                        .foregroundColor(.skinLabText)

                    Spacer()

                    // Summary badge (always visible when collapsed)
                    if !isExpanded {
                        summary()
                            .transition(.opacity)
                    }

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.skinLabSubtext)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")

            // Detail content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal)

                    detail()
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
}

// MARK: - Quick Insight Card

/// A compact card for displaying a single key insight prominently
struct QuickInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color

    init(
        icon: String,
        title: String,
        value: String,
        subtitle: String? = nil,
        accentColor: Color = .skinLabPrimary
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                Text(value)
                    .font(.skinLabTitle2)
                    .foregroundColor(.skinLabText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Metric Grid

/// A grid layout for displaying multiple key metrics
struct MetricGrid<Content: View>: View {
    let columns: Int
    @ViewBuilder let content: () -> Content

    init(columns: Int = 2, @ViewBuilder content: @escaping () -> Content) {
        self.columns = columns
        self.content = content
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            content()
        }
    }
}

// MARK: - Auxiliary Info Text

/// Small, subtle text for auxiliary information (timestamps, sources, etc.)
struct AuxiliaryInfoText: View {
    let text: String
    let icon: String?

    init(_ text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(text)
                .font(.system(size: 11))
        }
        .foregroundColor(.skinLabSubtext.opacity(0.7))
        .accessibilityLabel(text)
    }
}

// MARK: - Section Divider

/// A styled divider for separating visual sections
struct SectionDivider: View {
    let title: String?

    init(_ title: String? = nil) {
        self.title = title
    }

    var body: some View {
        if let title = title {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.skinLabSubtext.opacity(0.2))
                    .frame(height: 1)

                Text(title)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                Rectangle()
                    .fill(Color.skinLabSubtext.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
        } else {
            Rectangle()
                .fill(Color.skinLabSubtext.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview

#Preview("Key Metric Card") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            KeyMetricCard(
                value: "+12",
                label: "Score Change",
                icon: "chart.line.uptrend.xyaxis",
                trend: .up,
                trendLabel: "Improving"
            )

            KeyMetricCard(
                value: "-2",
                label: "Skin Age",
                icon: "sparkles",
                trend: .up,
                trendLabel: "Younger",
                gradient: .skinLabLavenderGradient
            )
        }

        KeyMetricCard(
            value: "85%",
            label: "Completion Rate",
            icon: "checkmark.circle",
            gradient: .skinLabGoldGradient
        )
    }
    .padding()
}

#Preview("Quick Insight Card") {
    VStack(spacing: 12) {
        QuickInsightCard(
            icon: "face.smiling",
            title: "Overall Score",
            value: "78",
            subtitle: "Above average"
        )

        QuickInsightCard(
            icon: "clock.fill",
            title: "Skin Age",
            value: "25 years",
            subtitle: "2 years younger than actual",
            accentColor: .skinLabSecondary
        )
    }
    .padding()
}

#Preview("Progressive Disclosure") {
    ProgressiveDisclosureCard(
        title: "Detailed Metrics",
        systemImage: "chart.bar.fill"
    ) {
        Text("5 items")
            .font(.skinLabCaption)
            .foregroundColor(.skinLabSubtext)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.skinLabSubtext.opacity(0.1))
            .cornerRadius(6)
    } detail: {
        VStack(spacing: 12) {
            SummaryStatRow(icon: "drop.fill", label: "Hydration", value: "72%")
            SummaryStatRow(icon: "sun.max.fill", label: "Sun Damage", value: "Low", iconColor: .orange)
            SummaryStatRow(icon: "leaf.fill", label: "Elasticity", value: "Good", iconColor: .green)
        }
    }
    .padding()
}
