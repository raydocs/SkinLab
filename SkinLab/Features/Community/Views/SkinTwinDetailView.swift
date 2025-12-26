// SkinLab/Features/Community/Views/SkinTwinDetailView.swift
import SwiftUI

/// 皮肤双胞胎详情页
struct SkinTwinDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let twin: SkinTwin
    let recommendations: [ProductRecommendationScore]
    var onFeedback: ((UUID) -> Void)?

    var body: some View {
        ZStack {
            // 背景
            Color.skinLabBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 相似度展示
                    similarityHeader

                    // 共同特征卡片
                    commonFeaturesCard

                    // TA验证有效的产品
                    if !twin.effectiveProducts.isEmpty {
                        effectiveProductsSection
                    }

                    // 推荐产品
                    if !recommendations.isEmpty {
                        recommendationsSection
                    }

                    // 反馈按钮
                    feedbackSection
                }
                .padding()
            }
        }
        .navigationTitle("肌肤双胞胎详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
                .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }
        }
    }

    // MARK: - Similarity Header

    private var similarityHeader: some View {
        VStack(spacing: 16) {
            // 大号相似度圆环
            ZStack {
                Circle()
                    .stroke(Color.skinLabPrimary.opacity(0.12), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: twin.similarity)
                    .stroke(
                        AngularGradient(
                            colors: [.skinLabPrimary, .skinLabSecondary, .skinLabPrimary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(twin.similarityPercent)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                    Text("相似度")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
            .padding(.top, 8)

            // 匹配等级标签
            Text(twin.matchLevel.rawValue)
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            // 匹配时间
            Text("匹配于 \(twin.matchedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
    }

    // MARK: - Common Features Card

    private var commonFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("共同特征")
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)

            VStack(spacing: 12) {
                featureRow(
                    icon: "drop.fill",
                    title: "肤质类型",
                    value: twin.anonymousProfile.skinType.displayName,
                    gradient: .skinLabRoseGradient
                )

                Divider()
                    .background(Color.skinLabPrimary.opacity(0.1))

                featureRow(
                    icon: "calendar",
                    title: "年龄段",
                    value: twin.anonymousProfile.ageRange.displayName,
                    gradient: .skinLabLavenderGradient
                )

                Divider()
                    .background(Color.skinLabPrimary.opacity(0.1))

                featureRow(
                    icon: "target",
                    title: "主要关注",
                    value: twin.anonymousProfile.mainConcerns.map(\.displayName).joined(separator: "、"),
                    gradient: .skinLabGoldGradient
                )

                if let region = twin.anonymousProfile.region {
                    Divider()
                        .background(Color.skinLabPrimary.opacity(0.1))

                    featureRow(
                        icon: "mappin.circle",
                        title: "地区",
                        value: region,
                        gradient: .skinLabPrimaryGradient
                    )
                }
            }
        }
        .padding(20)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow(radius: 10, y: 5)
    }

    private func featureRow(icon: String, title: String, value: String, gradient: LinearGradient) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(gradient)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                Text(value)
                    .font(.skinLabBody)
                    .foregroundColor(.skinLabText)
            }

            Spacer()
        }
    }

    // MARK: - Effective Products Section

    private var effectiveProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TA验证有效的产品")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Spacer()

                Text("\(twin.effectiveProducts.count)个产品")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            ForEach(twin.effectiveProducts) { effectiveProduct in
                EffectiveProductCard(effectiveProduct: effectiveProduct)
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("为你推荐")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Spacer()

                Text("基于相似度加权")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            ForEach(recommendations.prefix(5)) { recommendation in
                RecommendationDetailCard(recommendation: recommendation)
            }
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        VStack(spacing: 12) {
            Text("这个匹配对你有帮助吗？")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)

            Button {
                onFeedback?(twin.id)
            } label: {
                HStack {
                    Image(systemName: "hand.thumbsup")
                    Text("提供反馈")
                }
            }
            .buttonStyle(SkinLabSecondaryButtonStyle())
            .frame(width: 180)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Effective Product Card

struct EffectiveProductCard: View {
    let effectiveProduct: EffectiveProduct

    var body: some View {
        HStack(spacing: 14) {
            // 产品图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.skinLabLavenderGradient.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: effectiveProduct.product.category.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }

            // 产品信息
            VStack(alignment: .leading, spacing: 6) {
                Text(effectiveProduct.product.name)
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)

                Text(effectiveProduct.product.brand)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                // 效果标签
                HStack(spacing: 8) {
                    effectLabel(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "改善\(Int(effectiveProduct.improvementPercent * 100))%"
                    )

                    effectLabel(
                        icon: "clock",
                        text: "使用\(effectiveProduct.usageDuration)天"
                    )
                }
            }

            Spacer()

            // 有效性指示
            VStack {
                Image(systemName: effectiveProduct.effectiveness.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.skinLabSuccess)

                Text(effectiveProduct.effectiveness.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.skinLabSuccess)
            }
        }
        .padding(14)
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow(radius: 6, y: 3)
    }

    private func effectLabel(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.skinLabSecondary)
    }
}

// MARK: - Recommendation Detail Card

struct RecommendationDetailCard: View {
    let recommendation: ProductRecommendationScore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                // 产品图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient.skinLabRoseGradient.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: recommendation.product.category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                }

                // 产品信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.product.name)
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabText)

                    Text(recommendation.product.brand)
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                Spacer()

                // 推荐分数
                VStack(spacing: 2) {
                    Text("\(recommendation.scorePercent)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                    Text("分")
                        .font(.system(size: 10))
                        .foregroundColor(.skinLabSubtext)
                }
            }

            // 推荐理由
            if !recommendation.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recommendation.reasons.prefix(2), id: \.self) { reason in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.skinLabSuccess)

                            Text(reason)
                                .font(.skinLabCaption)
                                .foregroundColor(.skinLabSubtext)
                        }
                    }
                }
            }

            // 证据数据
            if recommendation.evidence.effectiveUserCount > 0 {
                HStack(spacing: 16) {
                    evidenceItem(
                        value: "\(recommendation.evidence.effectiveUserCount)",
                        label: "验证用户"
                    )

                    evidenceItem(
                        value: "\(Int(recommendation.evidence.avgSimilarity * 100))%",
                        label: "平均相似"
                    )

                    evidenceItem(
                        value: "\(recommendation.evidence.usageDuration)天",
                        label: "平均使用"
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow(radius: 6, y: 3)
    }

    private func evidenceItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.skinLabText)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.skinLabSubtext)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SkinTwinDetailView(
            twin: .mock,
            recommendations: [.mock]
        )
    }
}
