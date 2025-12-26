import SwiftData
// SkinLabTests/Community/ProductRecommendationEngineTests.swift
import XCTest

@testable import SkinLab

final class ProductRecommendationEngineTests: XCTestCase {

    // MARK: - ProductRecommendationScore Tests

    func testRecommendationLevel_highlyRecommended() {
        let score = createTestScore(score: 0.85)
        XCTAssertEqual(score.recommendationLevel, .highlyRecommended)
    }

    func testRecommendationLevel_recommended() {
        let score = createTestScore(score: 0.7)
        XCTAssertEqual(score.recommendationLevel, .recommended)
    }

    func testRecommendationLevel_maybeHelpful() {
        let score = createTestScore(score: 0.5)
        XCTAssertEqual(score.recommendationLevel, .maybeHelpful)
    }

    func testRecommendationLevel_notRecommended() {
        let score = createTestScore(score: 0.3)
        XCTAssertEqual(score.recommendationLevel, .notRecommended)
    }

    func testScorePercent() {
        let score = createTestScore(score: 0.85)
        XCTAssertEqual(score.scorePercent, 85)
    }

    func testScorePercent_boundary() {
        let score = createTestScore(score: 0.999)
        XCTAssertEqual(score.scorePercent, 99)
    }

    // MARK: - Evidence Tests

    func testEvidence_empty() {
        let evidence = ProductRecommendationScore.Evidence.empty
        XCTAssertEqual(evidence.effectiveUserCount, 0)
        XCTAssertEqual(evidence.avgSimilarity, 0)
        XCTAssertEqual(evidence.avgImprovement, 0)
        XCTAssertEqual(evidence.usageDuration, 0)
    }

    func testEvidence_withData() {
        let evidence = ProductRecommendationScore.Evidence(
            effectiveUserCount: 5,
            avgSimilarity: 0.88,
            avgImprovement: 0.72,
            usageDuration: 28
        )

        XCTAssertEqual(evidence.effectiveUserCount, 5)
        XCTAssertEqual(evidence.avgSimilarity, 0.88, accuracy: 0.01)
        XCTAssertEqual(evidence.avgImprovement, 0.72, accuracy: 0.01)
        XCTAssertEqual(evidence.usageDuration, 28)
    }

    // MARK: - Score Calculation Logic Tests

    func testScoreRangeIsValid() {
        // 确保分数在有效范围内
        let scores: [Double] = [0.0, 0.3, 0.5, 0.7, 0.85, 1.0]

        for scoreValue in scores {
            let score = createTestScore(score: scoreValue)
            XCTAssertGreaterThanOrEqual(score.score, 0.0)
            XCTAssertLessThanOrEqual(score.score, 1.0)
        }
    }

    func testRecommendationLevelBoundaries() {
        // 测试边界值
        XCTAssertEqual(createTestScore(score: 0.80).recommendationLevel, .highlyRecommended)
        XCTAssertEqual(createTestScore(score: 0.79).recommendationLevel, .recommended)
        XCTAssertEqual(createTestScore(score: 0.60).recommendationLevel, .recommended)
        XCTAssertEqual(createTestScore(score: 0.59).recommendationLevel, .maybeHelpful)
        XCTAssertEqual(createTestScore(score: 0.40).recommendationLevel, .maybeHelpful)
        XCTAssertEqual(createTestScore(score: 0.39).recommendationLevel, .notRecommended)
    }

    // MARK: - Concern to Function Mapping Tests

    func testConcernToFunctionMapping() {
        // 验证关注点到成分功效的映射
        let mappings: [(SkinConcern, IngredientFunction)] = [
            (.acne, .acneFighting),
            (.aging, .antiAging),
            (.dryness, .moisturizing),
            (.sensitivity, .soothing),
            (.pigmentation, .brightening),
            (.pores, .exfoliating),
            (.redness, .soothing),
        ]

        for (concern, expectedFunction) in mappings {
            let function = concernToFunction(concern)
            XCTAssertEqual(
                function, expectedFunction, "Concern \(concern) should map to \(expectedFunction)")
        }
    }

    // MARK: - Helper Methods

    private func createTestScore(score: Double) -> ProductRecommendationScore {
        ProductRecommendationScore(
            product: .mock,
            score: score,
            reasons: ["测试理由"],
            evidence: .empty
        )
    }

    private func concernToFunction(_ concern: SkinConcern) -> IngredientFunction {
        switch concern {
        case .acne: return .acneFighting
        case .aging: return .antiAging
        case .dryness: return .moisturizing
        case .oiliness: return .other
        case .sensitivity: return .soothing
        case .pigmentation: return .brightening
        case .pores: return .exfoliating
        case .redness: return .soothing
        }
    }
}

// MARK: - EffectiveProduct Tests

final class EffectiveProductTests: XCTestCase {

    func testEffectiveness_veryEffective() {
        let product = createEffectiveProduct(improvement: 0.75)
        XCTAssertEqual(product.effectiveness, .veryEffective)
    }

    func testEffectiveness_effective() {
        let product = createEffectiveProduct(improvement: 0.55)
        XCTAssertEqual(product.effectiveness, .effective)
    }

    func testEffectiveness_neutral() {
        let product = createEffectiveProduct(improvement: 0.25)
        XCTAssertEqual(product.effectiveness, .neutral)
    }

    func testEffectiveness_ineffective() {
        let product = createEffectiveProduct(improvement: 0.05)
        XCTAssertEqual(product.effectiveness, .ineffective)
    }

    func testEffectiveness_boundaries() {
        XCTAssertEqual(createEffectiveProduct(improvement: 0.70).effectiveness, .veryEffective)
        XCTAssertEqual(createEffectiveProduct(improvement: 0.69).effectiveness, .effective)
        XCTAssertEqual(createEffectiveProduct(improvement: 0.40).effectiveness, .effective)
        XCTAssertEqual(createEffectiveProduct(improvement: 0.39).effectiveness, .neutral)
        XCTAssertEqual(createEffectiveProduct(improvement: 0.10).effectiveness, .neutral)
        XCTAssertEqual(createEffectiveProduct(improvement: 0.09).effectiveness, .ineffective)
    }

    func testEffectivenessIcons() {
        XCTAssertEqual(EffectiveProduct.Effectiveness.veryEffective.icon, "checkmark.circle.fill")
        XCTAssertEqual(EffectiveProduct.Effectiveness.effective.icon, "checkmark.circle")
        XCTAssertEqual(EffectiveProduct.Effectiveness.neutral.icon, "minus.circle")
        XCTAssertEqual(EffectiveProduct.Effectiveness.ineffective.icon, "xmark.circle")
    }

    private func createEffectiveProduct(improvement: Double) -> EffectiveProduct {
        EffectiveProduct(
            product: .mock,
            usageDuration: 28,
            improvementPercent: improvement
        )
    }
}

// MARK: - IngredientEffectStats Tests

final class IngredientEffectStatsTests: XCTestCase {

    func testAvgEffectiveness_allBetter() {
        let stats = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 10,
            betterCount: 10,
            sameCount: 0,
            worseCount: 0,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.avgEffectiveness, 1.0, accuracy: 0.01)
    }

    func testAvgEffectiveness_allWorse() {
        let stats = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 10,
            betterCount: 0,
            sameCount: 0,
            worseCount: 10,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.avgEffectiveness, -1.0, accuracy: 0.01)
    }

    func testAvgEffectiveness_mixed() {
        let stats = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 10,
            betterCount: 6,
            sameCount: 2,
            worseCount: 2,
            lastUsedAt: Date()
        )

        // (6 - 2) / 10 = 0.4
        XCTAssertEqual(stats.avgEffectiveness, 0.4, accuracy: 0.01)
    }

    func testAvgEffectiveness_noUses() {
        let stats = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 0,
            betterCount: 0,
            sameCount: 0,
            worseCount: 0,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.avgEffectiveness, 0.0)
    }
}
