// SkinLabTests/Tracking/ProductAttributionTests.swift
@testable import SkinLab
import XCTest

final class ProductAttributionTests: XCTestCase {
    var analyzer: ProductEffectAnalyzer!
    let sessionId = UUID()

    override func setUp() {
        super.setUp()
        analyzer = ProductEffectAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Helper Functions

    private func createCheckIn(
        day: Int,
        products: [String],
        analysisId: UUID? = nil,
        feeling: CheckIn.Feeling? = nil
    ) -> CheckIn {
        CheckIn(
            sessionId: sessionId,
            day: day,
            analysisId: analysisId,
            usedProducts: products,
            feeling: feeling
        )
    }

    private func createAnalysis(id: UUID, overallScore: Int) -> SkinAnalysis {
        SkinAnalysis(
            id: id,
            skinType: .combination,
            skinAge: 25,
            overallScore: overallScore,
            issues: .empty,
            regions: .empty,
            recommendations: []
        )
    }

    // MARK: - detectProductOverlap Tests

    func testDetectProductOverlap_returnsCorrectCombinationCounts() {
        // Given: Check-ins with product combinations
        let checkIns = [
            createCheckIn(day: 1, products: ["A", "B"]),
            createCheckIn(day: 2, products: ["A", "B"]),
            createCheckIn(day: 3, products: ["A", "B", "C"]),
            createCheckIn(day: 4, products: ["A", "B"]),
            createCheckIn(day: 5, products: ["B", "C"]),
            createCheckIn(day: 6, products: ["B", "C"])
        ]

        // When
        let result = analyzer.detectProductOverlap(checkIns: checkIns)

        // Then: [A,B] appears 3 times (days 1,2,4), [B,C] appears 2 times (days 5,6)
        // [A,B,C] only appears once, so filtered out
        XCTAssertEqual(result[Set(["A", "B"])], 3)
        XCTAssertEqual(result[Set(["B", "C"])], 2)
        XCTAssertNil(result[Set(["A", "B", "C"])]) // Only 1 occurrence, filtered
    }

    func testDetectProductOverlap_ignoresSingleProductCheckIns() {
        // Given: Check-ins with single products
        let checkIns = [
            createCheckIn(day: 1, products: ["A"]),
            createCheckIn(day: 2, products: ["B"]),
            createCheckIn(day: 3, products: ["A"]),
            createCheckIn(day: 4, products: ["A", "B"])
        ]

        // When
        let result = analyzer.detectProductOverlap(checkIns: checkIns)

        // Then: Only [A,B] on day 4, but only once - not enough for threshold
        XCTAssertTrue(result.isEmpty)
    }

    func testDetectProductOverlap_returnsTop5Combinations() {
        // Given: Many different combinations, each used 2+ times
        let checkIns = [
            createCheckIn(day: 1, products: ["A", "B"]),
            createCheckIn(day: 2, products: ["A", "B"]),
            createCheckIn(day: 3, products: ["C", "D"]),
            createCheckIn(day: 4, products: ["C", "D"]),
            createCheckIn(day: 5, products: ["E", "F"]),
            createCheckIn(day: 6, products: ["E", "F"]),
            createCheckIn(day: 7, products: ["G", "H"]),
            createCheckIn(day: 8, products: ["G", "H"]),
            createCheckIn(day: 9, products: ["I", "J"]),
            createCheckIn(day: 10, products: ["I", "J"]),
            createCheckIn(day: 11, products: ["K", "L"]),
            createCheckIn(day: 12, products: ["K", "L"]),
            createCheckIn(day: 13, products: ["M", "N"]),
            createCheckIn(day: 14, products: ["M", "N"])
        ]

        // When
        let result = analyzer.detectProductOverlap(checkIns: checkIns)

        // Then: Should only return top 5
        XCTAssertEqual(result.count, 5)
    }

    func testDetectProductOverlap_emptyCheckInsReturnsEmpty() {
        // When
        let result = analyzer.detectProductOverlap(checkIns: [])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testDetectProductOverlap_requiresMinimum2Occurrences() {
        // Given: Each combination only used once
        let checkIns = [
            createCheckIn(day: 1, products: ["A", "B"]),
            createCheckIn(day: 2, products: ["C", "D"]),
            createCheckIn(day: 3, products: ["E", "F"])
        ]

        // When
        let result = analyzer.detectProductOverlap(checkIns: checkIns)

        // Then: No combinations meet the threshold
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - calculateAttributionWeights Tests

    func testCalculateAttributionWeights_normalizesToSumOfOne() async {
        // Given: Multiple products with usage data
        let analysisId1 = UUID()
        let analysisId2 = UUID()
        let analysisId3 = UUID()
        let analysisId4 = UUID()

        let checkIns = [
            createCheckIn(day: 1, products: ["A"], analysisId: analysisId1, feeling: .better),
            createCheckIn(day: 2, products: ["A", "B"], analysisId: analysisId2, feeling: .same),
            createCheckIn(day: 3, products: ["B"], analysisId: analysisId3, feeling: .better),
            createCheckIn(day: 4, products: ["A", "B"], analysisId: analysisId4, feeling: .better)
        ]

        let analyses: [UUID: SkinAnalysis] = [
            analysisId1: createAnalysis(id: analysisId1, overallScore: 60),
            analysisId2: createAnalysis(id: analysisId2, overallScore: 65),
            analysisId3: createAnalysis(id: analysisId3, overallScore: 70),
            analysisId4: createAnalysis(id: analysisId4, overallScore: 75)
        ]

        // When
        let weights = await analyzer.calculateAttributionWeights(
            products: ["A", "B"],
            checkIns: checkIns,
            analyses: analyses
        )

        // Then: Weights should sum to 1.0
        let sum = weights.values.reduce(0, +)
        XCTAssertEqual(sum, 1.0, accuracy: 0.001)
        XCTAssertNotNil(weights["A"])
        XCTAssertNotNil(weights["B"])
    }

    func testCalculateAttributionWeights_emptyProductsReturnsEmpty() async {
        // When
        let weights = await analyzer.calculateAttributionWeights(
            products: [],
            checkIns: [],
            analyses: [:]
        )

        // Then
        XCTAssertTrue(weights.isEmpty)
    }

    func testCalculateAttributionWeights_singleProductReturnsOne() async {
        // Given
        let analysisId1 = UUID()
        let analysisId2 = UUID()

        let checkIns = [
            createCheckIn(day: 1, products: ["A"], analysisId: analysisId1, feeling: .better),
            createCheckIn(day: 2, products: ["A"], analysisId: analysisId2, feeling: .same)
        ]

        let analyses: [UUID: SkinAnalysis] = [
            analysisId1: createAnalysis(id: analysisId1, overallScore: 60),
            analysisId2: createAnalysis(id: analysisId2, overallScore: 70)
        ]

        // When
        let weights = await analyzer.calculateAttributionWeights(
            products: ["A"],
            checkIns: checkIns,
            analyses: analyses
        )

        // Then: Single product should have weight 1.0
        XCTAssertEqual(weights["A"] ?? 0, 1.0, accuracy: 0.001)
    }

    func testCalculateAttributionWeights_distributesEvenlyWhenAllZero() async {
        // Given: Products with no usage data (mismatched IDs)
        let checkIns = [
            createCheckIn(day: 1, products: ["X"], analysisId: nil),
            createCheckIn(day: 2, products: ["Y"], analysisId: nil)
        ]

        // When
        let weights = await analyzer.calculateAttributionWeights(
            products: ["A", "B"],
            checkIns: checkIns,
            analyses: [:]
        )

        // Then: Should distribute evenly when all weights are 0
        XCTAssertEqual(weights["A"] ?? 0, 0.5, accuracy: 0.001)
        XCTAssertEqual(weights["B"] ?? 0, 0.5, accuracy: 0.001)
    }

    // MARK: - ProductCombinationInsight synergyLevel Tests

    func testProductCombinationInsight_synergyLevel_highSynergy() {
        let insight = ProductCombinationInsight(
            productIds: Set(["A", "B"]),
            combinedEffectScore: 0.5,
            synergyScore: 0.4,
            usageCount: 5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test")
        )

        XCTAssertEqual(insight.synergyLevel, .highSynergy)
    }

    func testProductCombinationInsight_synergyLevel_mildSynergy() {
        let insight = ProductCombinationInsight(
            productIds: Set(["A", "B"]),
            combinedEffectScore: 0.3,
            synergyScore: 0.15,
            usageCount: 5,
            confidence: ConfidenceScore(value: 0.7, sampleCount: 5, method: "test")
        )

        XCTAssertEqual(insight.synergyLevel, .mildSynergy)
    }

    func testProductCombinationInsight_synergyLevel_neutral() {
        let insight = ProductCombinationInsight(
            productIds: Set(["A", "B"]),
            combinedEffectScore: 0.1,
            synergyScore: 0.0,
            usageCount: 5,
            confidence: ConfidenceScore(value: 0.6, sampleCount: 5, method: "test")
        )

        XCTAssertEqual(insight.synergyLevel, .neutral)
    }

    func testProductCombinationInsight_synergyLevel_mildAntagonism() {
        let insight = ProductCombinationInsight(
            productIds: Set(["A", "B"]),
            combinedEffectScore: -0.1,
            synergyScore: -0.2,
            usageCount: 5,
            confidence: ConfidenceScore(value: 0.6, sampleCount: 5, method: "test")
        )

        XCTAssertEqual(insight.synergyLevel, .mildAntagonism)
    }

    func testProductCombinationInsight_synergyLevel_highAntagonism() {
        let insight = ProductCombinationInsight(
            productIds: Set(["A", "B"]),
            combinedEffectScore: -0.5,
            synergyScore: -0.4,
            usageCount: 5,
            confidence: ConfidenceScore(value: 0.5, sampleCount: 5, method: "test")
        )

        XCTAssertEqual(insight.synergyLevel, .highAntagonism)
    }

    // MARK: - ProductEffectInsight.isPrimaryContributor Tests

    func testProductEffectInsight_isPrimaryContributor_true() {
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: 0.5, // > 0.4
            soloUsageDays: [1, 3, 5],
            coUsedProductIds: nil
        )

        XCTAssertTrue(insight.isPrimaryContributor)
    }

    func testProductEffectInsight_isPrimaryContributor_false_lowWeight() {
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: 0.3, // <= 0.4
            soloUsageDays: [1, 3, 5],
            coUsedProductIds: nil
        )

        XCTAssertFalse(insight.isPrimaryContributor)
    }

    func testProductEffectInsight_isPrimaryContributor_false_nilWeight() {
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: nil, // nil
            soloUsageDays: [1, 3, 5],
            coUsedProductIds: nil
        )

        XCTAssertFalse(insight.isPrimaryContributor)
    }

    func testProductEffectInsight_isPrimaryContributor_boundaryValue() {
        // Weight exactly at 0.4 - should be false (> 0.4, not >=)
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: 0.4, // exactly 0.4
            soloUsageDays: [1, 3, 5],
            coUsedProductIds: nil
        )

        XCTAssertFalse(insight.isPrimaryContributor)
    }

    // MARK: - ProductEffectInsight.needsSoloUsageValidation Tests

    func testProductEffectInsight_needsSoloUsageValidation_true_nilSoloUsage() {
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: 0.5,
            soloUsageDays: nil, // nil
            coUsedProductIds: nil
        )

        XCTAssertTrue(insight.needsSoloUsageValidation)
    }

    func testProductEffectInsight_needsSoloUsageValidation_true_emptySoloUsage() {
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: 0.5,
            soloUsageDays: [], // empty
            coUsedProductIds: nil
        )

        XCTAssertTrue(insight.needsSoloUsageValidation)
    }

    func testProductEffectInsight_needsSoloUsageValidation_false() {
        let insight = ProductEffectInsight(
            productId: "A",
            productName: "Product A",
            effectivenessScore: 0.5,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 5, method: "test"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 2.0,
            attributionWeight: 0.5,
            soloUsageDays: [1, 3, 5], // has data
            coUsedProductIds: nil
        )

        XCTAssertFalse(insight.needsSoloUsageValidation)
    }

    // MARK: - analyzeCombinationEffect Tests

    func testAnalyzeCombinationEffect_returnsNilForSingleProduct() {
        // Given
        let checkIns = [
            createCheckIn(day: 1, products: ["A"]),
            createCheckIn(day: 2, products: ["A"])
        ]

        // When
        let result = analyzer.analyzeCombinationEffect(
            products: Set(["A"]),
            checkIns: checkIns,
            analyses: [:]
        )

        // Then
        XCTAssertNil(result)
    }

    func testAnalyzeCombinationEffect_returnsNilForInsufficientData() {
        // Given: Only 1 check-in with the combination
        let analysisId = UUID()
        let checkIns = [
            createCheckIn(day: 1, products: ["A", "B"], analysisId: analysisId)
        ]
        let analyses: [UUID: SkinAnalysis] = [
            analysisId: createAnalysis(id: analysisId, overallScore: 70)
        ]

        // When
        let result = analyzer.analyzeCombinationEffect(
            products: Set(["A", "B"]),
            checkIns: checkIns,
            analyses: analyses
        )

        // Then: Need at least 2 usages
        XCTAssertNil(result)
    }

    func testAnalyzeCombinationEffect_returnsInsightForValidData() {
        // Given: 3 check-ins with the combination
        let analysisId1 = UUID()
        let analysisId2 = UUID()
        let analysisId3 = UUID()

        let checkIns = [
            createCheckIn(day: 1, products: ["A", "B"], analysisId: analysisId1),
            createCheckIn(day: 2, products: ["A", "B"], analysisId: analysisId2),
            createCheckIn(day: 3, products: ["A", "B"], analysisId: analysisId3)
        ]

        let analyses: [UUID: SkinAnalysis] = [
            analysisId1: createAnalysis(id: analysisId1, overallScore: 60),
            analysisId2: createAnalysis(id: analysisId2, overallScore: 65),
            analysisId3: createAnalysis(id: analysisId3, overallScore: 70)
        ]

        // When
        let result = analyzer.analyzeCombinationEffect(
            products: Set(["A", "B"]),
            checkIns: checkIns,
            analyses: analyses
        )

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.productIds, Set(["A", "B"]))
        XCTAssertEqual(result?.usageCount, 3)
        XCTAssertGreaterThan(result?.combinedEffectScore ?? 0, 0) // Scores are improving
    }

    func testAnalyzeCombinationEffect_requiresAllProductsPresent() {
        // Given: Check-ins where only some products are present
        let analysisId1 = UUID()
        let analysisId2 = UUID()
        let analysisId3 = UUID()

        let checkIns = [
            createCheckIn(day: 1, products: ["A", "B"], analysisId: analysisId1),
            createCheckIn(day: 2, products: ["A"], analysisId: analysisId2), // Missing B
            createCheckIn(day: 3, products: ["B"], analysisId: analysisId3) // Missing A
        ]

        let analyses: [UUID: SkinAnalysis] = [
            analysisId1: createAnalysis(id: analysisId1, overallScore: 60),
            analysisId2: createAnalysis(id: analysisId2, overallScore: 65),
            analysisId3: createAnalysis(id: analysisId3, overallScore: 70)
        ]

        // When
        let result = analyzer.analyzeCombinationEffect(
            products: Set(["A", "B"]),
            checkIns: checkIns,
            analyses: analyses
        )

        // Then: Only 1 check-in has both A and B, not enough
        XCTAssertNil(result)
    }
}
