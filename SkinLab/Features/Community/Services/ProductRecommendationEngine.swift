// SkinLab/Features/Community/Services/ProductRecommendationEngine.swift
import Foundation
import SwiftData

/// 产品推荐引擎 - 基于皮肤双胞胎的有效产品推荐
///
/// 评分公式:
/// - 相似用户有效率 (40%)
/// - 成分适配度 (30%)
/// - 问题匹配度 (20%)
/// - 刺激风险扣分 (-10%)
@MainActor
class ProductRecommendationEngine {
    private let historyStore: UserHistoryStore
    private let modelContext: ModelContext

    init(historyStore: UserHistoryStore, modelContext: ModelContext) {
        self.historyStore = historyStore
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 为用户生成产品推荐
    /// - Parameters:
    ///   - user: 用户皮肤指纹
    ///   - twins: 匹配的皮肤双胞胎列表
    ///   - limit: 返回推荐数量限制
    /// - Returns: 产品推荐分数列表，按分数降序
    func rankProducts(
        for user: SkinFingerprint,
        basedOn twins: [SkinTwin],
        limit: Int = 10
    ) async -> [ProductRecommendationScore] {
        // 1. 聚合所有双胞胎的有效产品
        let candidateProducts = collectCandidateProducts(from: twins)

        guard !candidateProducts.isEmpty else {
            return []
        }

        // 2. 并行计算每个产品的推荐分数
        let scores = await withTaskGroup(of: ProductRecommendationScore?.self) { group in
            for product in candidateProducts {
                group.addTask {
                    await self.calculateScore(
                        for: product,
                        userFingerprint: user,
                        skinTwins: twins
                    )
                }
            }

            var results: [ProductRecommendationScore] = []
            for await score in group {
                if let score = score {
                    results.append(score)
                }
            }
            return results
        }

        // 3. 排序并限制数量
        return
            scores
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    /// 获取特定双胞胎推荐的产品
    /// - Parameters:
    ///   - twin: 特定的皮肤双胞胎
    ///   - user: 用户皮肤指纹
    /// - Returns: 该双胞胎验证有效的产品推荐
    func getProductsFromTwin(
        _ twin: SkinTwin,
        for user: SkinFingerprint
    ) async -> [ProductRecommendationScore] {
        var scores: [ProductRecommendationScore] = []

        for effectiveProduct in twin.effectiveProducts {
            if let score = await calculateScore(
                for: effectiveProduct.product,
                userFingerprint: user,
                skinTwins: [twin]
            ) {
                scores.append(score)
            }
        }

        return scores.sorted { $0.score > $1.score }
    }

    // MARK: - Private Methods

    /// 收集候选产品
    private func collectCandidateProducts(from twins: [SkinTwin]) -> Set<Product> {
        var products = Set<Product>()
        for twin in twins {
            for effectiveProduct in twin.effectiveProducts {
                products.insert(effectiveProduct.product)
            }
        }
        return products
    }

    /// 计算单个产品的推荐分数
    private func calculateScore(
        for product: Product,
        userFingerprint: SkinFingerprint,
        skinTwins: [SkinTwin]
    ) async -> ProductRecommendationScore? {
        var score: Double = 0
        var reasons: [String] = []

        // 筛选使用过此产品的双胞胎
        let relevantTwins = skinTwins.filter { twin in
            twin.effectiveProducts.contains { $0.product.id == product.id }
        }

        // 1. 相似用户有效率 (权重 40%)
        let (twinScore, twinReasons, evidence) = calculateTwinEffectiveness(
            product: product,
            relevantTwins: relevantTwins
        )
        score += twinScore * 0.4
        reasons.append(contentsOf: twinReasons)

        // 2. 成分适配度 (权重 30%)
        let ingredientMatch = calculateIngredientMatch(product, userFingerprint)
        score += ingredientMatch * 0.3
        if ingredientMatch > 0.7 {
            reasons.append("成分适合你的\(userFingerprint.skinType.displayName)肤质")
        }

        // 3. 问题匹配度 (权重 20%)
        let concernMatch = calculateConcernMatch(product, userFingerprint)
        score += concernMatch * 0.2
        if concernMatch > 0.7 {
            let topConcerns = userFingerprint.concerns.prefix(2).map(\.displayName).joined(
                separator: "、")
            if !topConcerns.isEmpty {
                reasons.append("针对\(topConcerns)问题")
            }
        }

        // 4. 刺激风险扣分 (权重 -10%)
        let riskPenalty = calculateRiskPenalty(product, userFingerprint)
        score -= riskPenalty * 0.1
        if riskPenalty > 0.3 {
            reasons.append("部分成分可能刺激，建议小面积测试")
        }

        // 确保分数在 [0, 1] 范围内
        let finalScore = min(1.0, max(0, score))

        // 分数太低则不推荐
        guard finalScore >= 0.3 else { return nil }

        return ProductRecommendationScore(
            product: product,
            score: finalScore,
            reasons: reasons,
            evidence: evidence
        )
    }

    /// 计算双胞胎有效性分数
    private func calculateTwinEffectiveness(
        product: Product,
        relevantTwins: [SkinTwin]
    ) -> (score: Double, reasons: [String], evidence: ProductRecommendationScore.Evidence) {
        guard !relevantTwins.isEmpty else {
            return (0, [], ProductRecommendationScore.Evidence.empty)
        }

        var reasons: [String] = []

        // 加权计算有效性 (按相似度加权)
        var totalWeight: Double = 0
        var weightedImprovement: Double = 0
        var totalUsageDuration: Int = 0

        for twin in relevantTwins {
            guard
                let productEffect = twin.effectiveProducts.first(where: {
                    $0.product.id == product.id
                })
            else {
                continue
            }

            let weight = twin.similarity
            totalWeight += weight
            weightedImprovement += weight * productEffect.improvementPercent
            totalUsageDuration += productEffect.usageDuration
        }

        let avgImprovement = totalWeight > 0 ? weightedImprovement / totalWeight : 0
        let avgSimilarity =
            relevantTwins.map(\.similarity).reduce(0, +) / Double(relevantTwins.count)
        let avgUsageDuration = relevantTwins.isEmpty ? 0 : totalUsageDuration / relevantTwins.count

        // 生成推荐理由
        if !relevantTwins.isEmpty {
            let improvementPercent = Int(avgImprovement * 100)
            reasons.append("\(relevantTwins.count)位相似用户验证有效，平均改善\(improvementPercent)%")
        }

        let evidence = ProductRecommendationScore.Evidence(
            effectiveUserCount: relevantTwins.count,
            avgSimilarity: avgSimilarity,
            avgImprovement: avgImprovement,
            usageDuration: avgUsageDuration
        )

        return (avgImprovement, reasons, evidence)
    }

    /// 计算成分适配度
    private func calculateIngredientMatch(
        _ product: Product,
        _ fingerprint: SkinFingerprint
    ) -> Double {
        var matchScore: Double = 0.5  // 默认中等匹配
        var factorCount: Double = 1

        // 检查产品适合的肤质
        if product.skinTypes.contains(fingerprint.skinType) {
            matchScore += 0.3
            factorCount += 1
        } else if !product.skinTypes.isEmpty {
            matchScore -= 0.2
        }

        // 检查成分功效与用户关注点的匹配
        let ingredientFunctions = Set(product.ingredients.map(\.function))

        for concern in fingerprint.concerns {
            let matchingFunction = concernToFunction(concern)
            if ingredientFunctions.contains(matchingFunction) {
                matchScore += 0.1
                factorCount += 1
            }
        }

        // 检查香精敏感度
        let hasFragrance = product.ingredients.contains { $0.function == .fragrance }
        if hasFragrance {
            switch fingerprint.fragranceTolerance {
            case .avoid:
                matchScore -= 0.4
            case .sensitive:
                matchScore -= 0.2
            case .neutral:
                break
            case .love:
                matchScore += 0.1
            }
            factorCount += 1
        }

        // 获取用户的成分偏好历史
        let ingredientStats = historyStore.getAllIngredientStats()
        for ingredient in product.ingredients {
            if let stats = ingredientStats[ingredient.name] {
                // 根据历史效果调整分数
                matchScore += stats.avgEffectiveness * 0.2
                factorCount += 1
            }
        }

        return min(1.0, max(0, matchScore / factorCount * factorCount.squareRoot()))
    }

    /// 计算问题匹配度
    private func calculateConcernMatch(
        _ product: Product,
        _ fingerprint: SkinFingerprint
    ) -> Double {
        guard !fingerprint.concerns.isEmpty else { return 0.5 }

        let userConcerns = Set(fingerprint.concerns)
        let productConcerns = Set(product.concerns)

        // 计算交集比例
        let intersection = userConcerns.intersection(productConcerns)
        let matchRatio = Double(intersection.count) / Double(userConcerns.count)

        // 加权：更匹配主要问题（前2个）
        var weightedScore = matchRatio
        let topConcerns = Array(fingerprint.concerns.prefix(2))
        for concern in topConcerns {
            if productConcerns.contains(concern) {
                weightedScore += 0.15
            }
        }

        return min(1.0, weightedScore)
    }

    /// 计算刺激风险
    private func calculateRiskPenalty(
        _ product: Product,
        _ fingerprint: SkinFingerprint
    ) -> Double {
        var riskScore: Double = 0

        // 检查高刺激成分
        let highIrritationIngredients = product.ingredients.filter { $0.irritationRisk == .high }
        let mediumIrritationIngredients = product.ingredients.filter {
            $0.irritationRisk == .medium
        }

        riskScore += Double(highIrritationIngredients.count) * 0.3
        riskScore += Double(mediumIrritationIngredients.count) * 0.1

        // 敏感肌加重风险
        if fingerprint.skinType == .sensitive || fingerprint.concerns.contains(.sensitivity) {
            riskScore *= 1.5
        }

        // 用户历史刺激记录
        if fingerprint.irritationHistory > 0.5 {
            riskScore *= 1.3
        }

        // 检查用户过敏成分（通过历史数据）
        let negativeIngredients = historyStore.getAllIngredientStats().filter {
            $0.value.avgEffectiveness < -0.3
        }

        for ingredient in product.ingredients {
            if negativeIngredients[ingredient.name] != nil {
                riskScore += 0.5
            }
        }

        return min(1.0, riskScore)
    }

    /// 关注点到成分功效的映射
    private func concernToFunction(_ concern: SkinConcern) -> IngredientFunction {
        switch concern {
        case .acne:
            return .acneFighting
        case .aging:
            return .antiAging
        case .dryness:
            return .moisturizing
        case .oiliness:
            return .other  // 控油
        case .sensitivity:
            return .soothing
        case .pigmentation:
            return .brightening
        case .pores:
            return .exfoliating
        case .redness:
            return .soothing
        }
    }
}

// MARK: - Product Recommendation Score

/// 产品推荐分数结构
struct ProductRecommendationScore: Identifiable, Codable {
    var id: UUID { product.id }
    let product: Product
    let score: Double  // 0-1
    let reasons: [String]  // 推荐理由
    let evidence: Evidence  // 证据数据

    /// 证据数据
    struct Evidence: Codable {
        let effectiveUserCount: Int  // 有效用户数
        let avgSimilarity: Double  // 平均相似度
        let avgImprovement: Double  // 平均改善幅度
        let usageDuration: Int  // 平均使用天数

        static let empty = Evidence(
            effectiveUserCount: 0,
            avgSimilarity: 0,
            avgImprovement: 0,
            usageDuration: 0
        )
    }

    /// 分数百分比显示
    var scorePercent: Int {
        Int(score * 100)
    }

    /// 推荐等级
    var recommendationLevel: RecommendationLevel {
        switch score {
        case 0.8...:
            return .highlyRecommended
        case 0.6..<0.8:
            return .recommended
        case 0.4..<0.6:
            return .maybeHelpful
        default:
            return .notRecommended
        }
    }

    enum RecommendationLevel: String {
        case highlyRecommended = "强烈推荐"
        case recommended = "推荐"
        case maybeHelpful = "可能有用"
        case notRecommended = "不推荐"

        var icon: String {
            switch self {
            case .highlyRecommended: return "star.fill"
            case .recommended: return "hand.thumbsup.fill"
            case .maybeHelpful: return "hand.thumbsup"
            case .notRecommended: return "hand.thumbsdown"
            }
        }

        var color: String {
            switch self {
            case .highlyRecommended: return "skinLabPrimary"
            case .recommended: return "skinLabSecondary"
            case .maybeHelpful: return "skinLabAccent"
            case .notRecommended: return "gray"
            }
        }
    }

    /// Mock数据
    static let mock = ProductRecommendationScore(
        product: .mock,
        score: 0.85,
        reasons: [
            "3位相似用户验证有效，平均改善72%",
            "成分适合你的混合性肤质",
            "针对痘痘、毛孔问题",
        ],
        evidence: Evidence(
            effectiveUserCount: 3,
            avgSimilarity: 0.88,
            avgImprovement: 0.72,
            usageDuration: 28
        )
    )
}

// IngredientEffectStats 已在 IngredientExposureRecord.swift 中定义
// avgEffectiveness 属性也已在原始定义中实现
