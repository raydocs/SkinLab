// SkinLab/Features/Community/Views/Components/TwinMatchCard.swift
import SwiftUI

/// 皮肤双胞胎匹配卡片组件
struct TwinMatchCard: View {
    let twin: SkinTwin
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // 相似度圆环
                similarityBadge

                // 信息区域
                VStack(alignment: .leading, spacing: 8) {
                    // 匹配等级
                    Text(twin.matchLevel.rawValue)
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)

                    // 基本特征
                    HStack(spacing: 6) {
                        Text(twin.anonymousProfile.skinType.displayName)
                        Text("·")
                        Text(twin.anonymousProfile.ageRange.displayName)
                    }
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                    // 共同关注点标签
                    concernTags

                    // 有效产品数
                    if !twin.effectiveProducts.isEmpty {
                        effectiveProductsIndicator
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.skinLabPrimary.opacity(0.6))
            }
            .padding(16)
            .background(Color.skinLabCardBackground)
            .cornerRadius(18)
            .skinLabSoftShadow(radius: 8, y: 4)
        }
        .buttonStyle(.plain)

        // MARK: - Accessibility

        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("双击查看详情")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var label = "\(twin.matchLevel.rawValue)，相似度\(twin.similarityPercent)%"
        label += "，\(twin.anonymousProfile.skinType.displayName)"
        label += "，\(twin.anonymousProfile.ageRange.displayName)"
        if !twin.effectiveProducts.isEmpty {
            label += "，\(twin.effectiveProducts.count)个有效产品"
        }
        return label
    }

    // MARK: - Subviews

    private var similarityBadge: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.skinLabPrimary.opacity(0.15), lineWidth: 4)
                .frame(width: 60, height: 60)

            // 进度圆环
            Circle()
                .trim(from: 0, to: twin.similarity)
                .stroke(
                    LinearGradient.skinLabPrimaryGradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            // 百分比文字
            VStack(spacing: 0) {
                Text("\(twin.similarityPercent)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.skinLabSubtext)
            }
        }
    }

    private var concernTags: some View {
        HStack(spacing: 6) {
            ForEach(twin.anonymousProfile.mainConcerns.prefix(3), id: \.self) { concern in
                Text(concern.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.skinLabPrimary.opacity(0.1))
                    .foregroundColor(.skinLabPrimary)
                    .cornerRadius(8)
            }
        }
    }

    private var effectiveProductsIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
            Text("\(twin.effectiveProducts.count)个有效产品")
                .font(.skinLabCaption)
        }
        .foregroundColor(.skinLabSecondary)
    }
}

// MARK: - Compact Variant

/// 紧凑版匹配卡片 (用于列表)
struct TwinMatchCardCompact: View {
    let twin: SkinTwin

    var body: some View {
        HStack(spacing: 12) {
            // 相似度
            ZStack {
                Circle()
                    .fill(matchLevelColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text("\(twin.similarityPercent)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(matchLevelColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(twin.matchLevel.rawValue)
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)

                Text(
                    "\(twin.anonymousProfile.skinType.displayName) · \(twin.anonymousProfile.ageRange.displayName)"
                )
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
            }

            Spacer()

            if !twin.effectiveProducts.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("\(twin.effectiveProducts.count)")
                        .font(.skinLabCaption)
                }
                .foregroundColor(.skinLabAccent)
            }
        }
        .padding(12)
        .background(Color.skinLabCardBackground)
        .cornerRadius(14)

        // MARK: - Accessibility

        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(twin.matchLevel.rawValue)，相似度\(twin.similarityPercent)%，\(twin.anonymousProfile.skinType.displayName)"
        )
    }

    private var matchLevelColor: Color {
        switch twin.matchLevel {
        case .twin:
            .skinLabPrimary
        case .verySimilar:
            .skinLabSecondary
        case .similar:
            .skinLabAccent
        case .somewhatSimilar:
            .skinLabSubtext
        }
    }
}

// MARK: - Preview

#Preview("TwinMatchCard") {
    VStack(spacing: 16) {
        TwinMatchCard(twin: .mock)
        TwinMatchCardCompact(twin: .mock)
    }
    .padding()
    .background(Color.skinLabBackground)
}
