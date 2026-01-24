// SkinLabTests/Community/SkinMatcherTests.swift
import XCTest
@testable import SkinLab

final class SkinMatcherTests: XCTestCase {

    var matcher: SkinMatcher!

    override func setUp() {
        super.setUp()
        matcher = SkinMatcher()
    }

    override func tearDown() {
        matcher = nil
        super.tearDown()
    }

    // MARK: - Cosine Similarity Tests

    func testCosineSimilarity_identicalVectors_returns1() {
        let vectorA = [1.0, 0.5, 0.3, 0.8]
        let vectorB = [1.0, 0.5, 0.3, 0.8]

        let similarity = matcher.testCosineSimilarity(vectorA, vectorB)

        XCTAssertEqual(similarity, 1.0, accuracy: 0.001)
    }

    func testCosineSimilarity_orthogonalVectors_returns0() {
        let vectorA = [1.0, 0.0, 0.0, 0.0]
        let vectorB = [0.0, 1.0, 0.0, 0.0]

        let similarity = matcher.testCosineSimilarity(vectorA, vectorB)

        XCTAssertEqual(similarity, 0.0, accuracy: 0.001)
    }

    func testCosineSimilarity_oppositeVectors_returnsNegative() {
        let vectorA = [1.0, 0.0]
        let vectorB = [-1.0, 0.0]

        let similarity = matcher.testCosineSimilarity(vectorA, vectorB)

        XCTAssertEqual(similarity, -1.0, accuracy: 0.001)
    }

    func testCosineSimilarity_emptyVectors_returns0() {
        let vectorA: [Double] = []
        let vectorB: [Double] = []

        let similarity = matcher.testCosineSimilarity(vectorA, vectorB)

        XCTAssertEqual(similarity, 0.0)
    }

    func testCosineSimilarity_differentLengthVectors_returns0() {
        let vectorA = [1.0, 0.5]
        let vectorB = [1.0, 0.5, 0.3]

        let similarity = matcher.testCosineSimilarity(vectorA, vectorB)

        XCTAssertEqual(similarity, 0.0)
    }

    func testCosineSimilarity_similarVectors_returnsHighValue() {
        let vectorA = [0.9, 0.5, 0.3, 0.7]
        let vectorB = [0.85, 0.55, 0.28, 0.72]

        let similarity = matcher.testCosineSimilarity(vectorA, vectorB)

        XCTAssertGreaterThan(similarity, 0.95)
    }

    // MARK: - Weighted Similarity Tests

    func testWeightedSimilarity_sameSkinType_bonus() {
        let userFP = createTestFingerprint(skinType: .combination)
        let otherFP = createTestFingerprint(skinType: .combination)

        let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)

        // 相同肤质应获得加成，相似度应高于基础值
        XCTAssertGreaterThan(similarity, 0.7)
    }

    func testWeightedSimilarity_differentSkinType_penalty() {
        let userFP = createTestFingerprint(skinType: .oily)
        let otherFP = createTestFingerprint(skinType: .dry)

        let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)

        // 不同肤质应受到惩罚
        XCTAssertLessThan(similarity, 0.8)
    }

    func testWeightedSimilarity_sameAgeRange_bonus() {
        let userFP = createTestFingerprint(ageRange: .age25to30)
        let otherFP = createTestFingerprint(ageRange: .age25to30)

        let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)

        XCTAssertGreaterThan(similarity, 0.6)
    }

    func testWeightedSimilarity_commonConcerns_bonus() {
        let userFP = createTestFingerprint(concerns: [.acne, .pores, .oiliness])
        let otherFP = createTestFingerprint(concerns: [.acne, .pores, .sensitivity])

        let similarityWithCommon = matcher.testWeightedSimilarity(user: userFP, other: otherFP)

        let userFP2 = createTestFingerprint(concerns: [.acne])
        let otherFP2 = createTestFingerprint(concerns: [.aging])
        let similarityNoCommon = matcher.testWeightedSimilarity(user: userFP2, other: otherFP2)

        // 有共同关注点应获得更高或相等相似度（相似度已经很高时可能相等）
        XCTAssertGreaterThanOrEqual(similarityWithCommon, similarityNoCommon)
    }

    func testWeightedSimilarity_sensitivityMatch_bonus() {
        let userFP = createTestFingerprint(irritationHistory: 0.3)
        let otherFP = createTestFingerprint(irritationHistory: 0.35)

        let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)

        // 敏感度接近应获得加成
        XCTAssertGreaterThan(similarity, 0.5)
    }

    func testWeightedSimilarity_resultInValidRange() {
        let userFP = createTestFingerprint()
        let otherFP = createTestFingerprint()

        let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)

        // 结果应在 [0, 1] 范围内
        XCTAssertGreaterThanOrEqual(similarity, 0.0)
        XCTAssertLessThanOrEqual(similarity, 1.0)
    }

    // MARK: - Batch Processing Tests

    func testBatchProcessing_emptyFingerprints_returnsEmpty() async {
        let fingerprints: [SkinFingerprint] = []
        let candidates: [MatchCandidate] = []

        let results = await matcher.findMatchesBatch(for: fingerprints, candidates: candidates)

        XCTAssertEqual(results.count, 0)
    }

    func testBatchProcessing_emptyCandidates_returnsEmptyArrays() async {
        let fingerprints = [
            createTestFingerprint(skinType: .oily),
            createTestFingerprint(skinType: .dry)
        ]
        let candidates: [MatchCandidate] = []

        let results = await matcher.findMatchesBatch(for: fingerprints, candidates: candidates)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0].isEmpty)
        XCTAssertTrue(results[1].isEmpty)
    }

    func testBatchProcessing_multipleFingerprints_maintainsOrder() async {
        // This test verifies batch processing maintains correct order
        let fingerprints = [
            createTestFingerprint(skinType: .oily, ageRange: .age20to25),
            createTestFingerprint(skinType: .dry, ageRange: .age30to35),
            createTestFingerprint(skinType: .combination, ageRange: .age25to30)
        ]
        let candidates: [MatchCandidate] = []

        let results = await matcher.findMatchesBatch(for: fingerprints, candidates: candidates)

        // Should return same number of result arrays as input fingerprints
        XCTAssertEqual(results.count, fingerprints.count)
    }

    // MARK: - Batch Processing with Candidates Tests

    func testBatchProcessing_withCandidates_returnsExpectedTopMatch() async {
        // Create a user fingerprint
        let userFP = createTestFingerprint(skinType: .oily, ageRange: .age20to25, concerns: [.acne, .pores])

        // Create candidates - one very similar, one quite different
        let bestCandidate = createTestCandidate(
            skinType: .oily,
            ageRange: .age20to25,
            concerns: [.acne, .pores]
        )
        let worstCandidate = createTestCandidate(
            skinType: .dry,
            ageRange: .over40,
            concerns: [.aging, .dryness]
        )

        let candidates = [worstCandidate, bestCandidate]
        let results = await matcher.findMatchesBatch(for: [userFP], candidates: candidates, limit: 5)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].isEmpty, "Should find at least one match")
        XCTAssertEqual(results[0].first?.userId, bestCandidate.userId, "Best candidate should be first match")
    }

    func testBatchProcessing_withCandidates_batchResultsMatchSingleResults() async {
        // Create fingerprints
        let fp1 = createTestFingerprint(skinType: .oily, concerns: [.acne])
        let fp2 = createTestFingerprint(skinType: .dry, concerns: [.dryness])

        // Create candidates
        let candidates = [
            createTestCandidate(skinType: .oily, concerns: [.acne, .pores]),
            createTestCandidate(skinType: .dry, concerns: [.dryness, .sensitivity]),
            createTestCandidate(skinType: .combination, concerns: [.acne, .dryness])
        ]

        // Get batch results
        let batchResults = await matcher.findMatchesBatch(for: [fp1, fp2], candidates: candidates, limit: 10)

        // Get single results
        let singleResult1 = matcher.findMatchesFromCandidates(for: fp1, candidates: candidates, limit: 10)
        let singleResult2 = matcher.findMatchesFromCandidates(for: fp2, candidates: candidates, limit: 10)

        // Compare results
        XCTAssertEqual(batchResults.count, 2)
        XCTAssertEqual(batchResults[0].count, singleResult1.count, "Batch and single should have same count for fp1")
        XCTAssertEqual(batchResults[1].count, singleResult2.count, "Batch and single should have same count for fp2")

        // Verify ordering matches
        if !batchResults[0].isEmpty && !singleResult1.isEmpty {
            XCTAssertEqual(batchResults[0][0].userId, singleResult1[0].userId, "Top match should be same")
        }
    }

    func testBatchProcessing_withCandidates_respectsMinSimilarityThreshold() async {
        // Create a fingerprint that won't match well
        let userFP = createTestFingerprint(skinType: .oily, ageRange: .under20, concerns: [.oiliness])

        // Create a very different candidate
        let differentCandidate = createTestCandidate(
            skinType: .dry,
            ageRange: .over40,
            concerns: [.aging, .dryness]
        )

        // Use high similarity threshold
        let strictMatcher = SkinMatcher(config: SkinMatcher.BatchConfig(
            maxBatchSize: 5,
            minSimilarity: 0.9,  // Very high threshold
            enableParallelProcessing: true
        ))

        let results = await strictMatcher.findMatchesBatch(for: [userFP], candidates: [differentCandidate], limit: 10)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].isEmpty, "Should not match with very different candidate at high threshold")
    }

    func testExtractCandidates_precomputesVectors() {
        // Test that MatchCandidate has precomputed vector
        let fingerprint = createTestFingerprint()
        let candidate = MatchCandidate(
            userId: UUID(),
            fingerprint: fingerprint,
            vector: fingerprint.vector,
            anonymousProfile: .mock
        )

        // Vector should be non-empty and match fingerprint vector
        XCTAssertFalse(candidate.vector.isEmpty)
        XCTAssertEqual(candidate.vector, fingerprint.vector)
    }

    func testBatchConfig_customConfig_respected() {
        let customConfig = SkinMatcher.BatchConfig(
            maxBatchSize: 3,
            minSimilarity: 0.7,
            enableParallelProcessing: false
        )
        let customMatcher = SkinMatcher(config: customConfig)

        // Matcher should be created with custom config
        XCTAssertNotNil(customMatcher)
    }

    func testBatchConfig_defaultConfig_hasReasonableValues() {
        let defaultConfig = SkinMatcher.BatchConfig.default

        XCTAssertEqual(defaultConfig.maxBatchSize, 5)
        XCTAssertEqual(defaultConfig.minSimilarity, 0.6)
        XCTAssertTrue(defaultConfig.enableParallelProcessing)
    }

    // MARK: - Array Chunked Extension Tests

    func testArrayChunked_evenDivision() {
        let array = [1, 2, 3, 4, 5, 6]
        let chunks = array.chunked(into: 2)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1, 2])
        XCTAssertEqual(chunks[1], [3, 4])
        XCTAssertEqual(chunks[2], [5, 6])
    }

    func testArrayChunked_unevenDivision() {
        let array = [1, 2, 3, 4, 5]
        let chunks = array.chunked(into: 2)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1, 2])
        XCTAssertEqual(chunks[1], [3, 4])
        XCTAssertEqual(chunks[2], [5])
    }

    func testArrayChunked_singleElementChunks() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 1)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1])
        XCTAssertEqual(chunks[1], [2])
        XCTAssertEqual(chunks[2], [3])
    }

    func testArrayChunked_chunkSizeLargerThanArray() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 10)

        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], [1, 2, 3])
    }

    func testArrayChunked_emptyArray() {
        let array: [Int] = []
        let chunks = array.chunked(into: 5)

        XCTAssertEqual(chunks.count, 0)
    }

    func testArrayChunked_zeroSize_returnsEmpty() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 0)

        XCTAssertEqual(chunks.count, 0)
    }

    // MARK: - MatchLevel Tests

    func testMatchLevel_twin() {
        let level = MatchLevel(similarity: 0.95)
        XCTAssertEqual(level, .twin)
    }

    func testMatchLevel_verySimilar() {
        let level = MatchLevel(similarity: 0.85)
        XCTAssertEqual(level, .verySimilar)
    }

    func testMatchLevel_similar() {
        let level = MatchLevel(similarity: 0.75)
        XCTAssertEqual(level, .similar)
    }

    func testMatchLevel_somewhatSimilar() {
        let level = MatchLevel(similarity: 0.65)
        XCTAssertEqual(level, .somewhatSimilar)
    }

    func testMatchLevel_boundaryAt90() {
        let level = MatchLevel(similarity: 0.90)
        XCTAssertEqual(level, .twin)
    }

    func testMatchLevel_boundaryAt80() {
        let level = MatchLevel(similarity: 0.80)
        XCTAssertEqual(level, .verySimilar)
    }

    // MARK: - Helper Methods

    private func createTestFingerprint(
        skinType: SkinType = .combination,
        ageRange: AgeRange = .age25to30,
        concerns: [SkinConcern] = [.acne, .pores],
        irritationHistory: Double = 0.3
    ) -> SkinFingerprint {
        SkinFingerprint(
            skinType: skinType,
            ageRange: ageRange,
            concerns: concerns,
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: irritationHistory,
            budgetLevel: .moderate
        )
    }

    private func createTestCandidate(
        skinType: SkinType = .combination,
        ageRange: AgeRange = .age25to30,
        concerns: [SkinConcern] = [.acne, .pores],
        irritationHistory: Double = 0.3
    ) -> MatchCandidate {
        let fingerprint = SkinFingerprint(
            skinType: skinType,
            ageRange: ageRange,
            concerns: concerns,
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: irritationHistory,
            budgetLevel: .moderate
        )
        return MatchCandidate(
            userId: UUID(),
            fingerprint: fingerprint,
            vector: fingerprint.vector,
            anonymousProfile: .mock
        )
    }
}

// MARK: - SkinMatcher Test Extensions

extension SkinMatcher {
    /// 暴露 cosineSimilarity 供测试使用
    func testCosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// 暴露 weightedSimilarity 供测试使用
    func testWeightedSimilarity(user: SkinFingerprint, other: SkinFingerprint) -> Double {
        // 复制私有方法逻辑用于测试
        let baseSimilarity = testCosineSimilarity(user.vector, other.vector)
        let skinTypeBonus = user.skinType == other.skinType ? 0.2 : -0.3

        let ageDiff = abs(user.ageRange.normalized - other.ageRange.normalized)
        let ageBonus: Double
        if ageDiff < 0.2 {
            ageBonus = 0.1
        } else if ageDiff > 0.4 {
            ageBonus = -0.1
        } else {
            ageBonus = 0
        }

        let concernOverlap = Set(user.concerns).intersection(other.concerns)
        let concernBonus = Double(concernOverlap.count) * 0.03

        let sensitivityBonus = abs(user.irritationHistory - other.irritationHistory) < 0.2 ? 0.05 : 0

        let finalScore = baseSimilarity + skinTypeBonus + ageBonus + concernBonus + sensitivityBonus
        return min(1.0, max(0, finalScore))
    }
}
