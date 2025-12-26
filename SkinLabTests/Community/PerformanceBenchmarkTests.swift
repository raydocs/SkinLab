// SkinLabTests/Community/PerformanceBenchmarkTests.swift
import XCTest

@testable import SkinLab

/// 性能基准测试
///
/// 目标延迟:
/// - 小规模 (50用户): < 200ms
/// - 中等规模 (200用户): < 500ms
/// - 大规模 (1000用户): < 2s
final class PerformanceBenchmarkTests: XCTestCase {

    var matcher: SkinMatcher!

    override func setUp() {
        super.setUp()
        matcher = SkinMatcher()
    }

    override func tearDown() {
        matcher = nil
        super.tearDown()
    }

    // MARK: - Cosine Similarity Performance

    func testCosineSimilarity_performance_largeVector() {
        let vectorA = (0..<100).map { _ in Double.random(in: 0...1) }
        let vectorB = (0..<100).map { _ in Double.random(in: 0...1) }

        measure {
            for _ in 0..<10000 {
                _ = matcher.testCosineSimilarity(vectorA, vectorB)
            }
        }
    }

    // MARK: - Fingerprint Vector Generation Performance

    func testFingerprintVectorGeneration_performance() {
        let fingerprint = createTestFingerprint()

        measure {
            for _ in 0..<10000 {
                _ = fingerprint.vector
            }
        }
    }

    // MARK: - Weighted Similarity Performance

    func testWeightedSimilarity_performance_singlePair() {
        let userFP = createTestFingerprint()
        let otherFP = createTestFingerprint()

        measure {
            for _ in 0..<10000 {
                _ = matcher.testWeightedSimilarity(user: userFP, other: otherFP)
            }
        }
    }

    // MARK: - Batch Matching Performance Simulation

    func testBatchMatching_50users_simulation() {
        let userFP = createTestFingerprint()
        let pool = (0..<50).map { _ in createRandomFingerprint() }

        measure {
            var results: [(SkinFingerprint, Double)] = []
            for otherFP in pool {
                let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)
                if similarity >= 0.6 {
                    results.append((otherFP, similarity))
                }
            }
            _ = results.sorted { $0.1 > $1.1 }.prefix(20)
        }
    }

    func testBatchMatching_200users_simulation() {
        let userFP = createTestFingerprint()
        let pool = (0..<200).map { _ in createRandomFingerprint() }

        measure {
            var results: [(SkinFingerprint, Double)] = []
            for otherFP in pool {
                let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)
                if similarity >= 0.6 {
                    results.append((otherFP, similarity))
                }
            }
            _ = results.sorted { $0.1 > $1.1 }.prefix(20)
        }
    }

    func testBatchMatching_1000users_simulation() {
        let userFP = createTestFingerprint()
        let pool = (0..<1000).map { _ in createRandomFingerprint() }

        measure {
            var results: [(SkinFingerprint, Double)] = []
            for otherFP in pool {
                let similarity = matcher.testWeightedSimilarity(user: userFP, other: otherFP)
                if similarity >= 0.6 {
                    results.append((otherFP, similarity))
                }
            }
            _ = results.sorted { $0.1 > $1.1 }.prefix(20)
        }
    }

    // MARK: - MatchLevel Initialization Performance

    func testMatchLevelInit_performance() {
        measure {
            for _ in 0..<100000 {
                _ = MatchLevel(similarity: Double.random(in: 0...1))
            }
        }
    }

    // MARK: - Cache Performance

    func testCacheOperations_performance() {
        let cache = MatchCache()
        let userId = UUID()
        let matches = (0..<20).map { _ in createMockSkinTwin() }

        measure {
            for i in 0..<1000 {
                let testUserId = i % 2 == 0 ? userId : UUID()
                cache.set(matches: matches, recommendations: [], for: testUserId)
                _ = cache.getMatches(for: testUserId)
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestFingerprint() -> SkinFingerprint {
        SkinFingerprint(
            skinType: .combination,
            ageRange: .age25to30,
            concerns: [.acne, .pores],
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.3,
            budgetLevel: .moderate
        )
    }

    private func createRandomFingerprint() -> SkinFingerprint {
        let skinTypes: [SkinType] = [.dry, .oily, .combination, .sensitive]
        let ageRanges: [AgeRange] = [
            .under20, .age20to25, .age25to30, .age30to35, .age35to40, .over40,
        ]
        let allConcerns: [SkinConcern] = [
            .acne, .aging, .dryness, .oiliness, .sensitivity, .pigmentation, .pores, .redness,
        ]

        let randomConcerns = Array(allConcerns.shuffled().prefix(Int.random(in: 1...4)))

        return SkinFingerprint(
            skinType: skinTypes.randomElement()!,
            ageRange: ageRanges.randomElement()!,
            concerns: randomConcerns,
            issueVector: (0..<5).map { _ in Double.random(in: 0...1) },
            fragranceTolerance: FragranceTolerance.allCases.randomElement()!,
            uvExposure: UVExposureLevel.allCases.randomElement()!,
            irritationHistory: Double.random(in: 0...1),
            budgetLevel: BudgetLevel.allCases.randomElement()!
        )
    }

    private func createMockSkinTwin() -> SkinTwin {
        SkinTwin(
            userId: UUID(),
            similarity: Double.random(in: 0.6...1.0),
            matchLevel: .verySimilar,
            anonymousProfile: .mock
        )
    }
}

// MARK: - Memory Usage Tests

final class MemoryUsageTests: XCTestCase {

    @MainActor
    func testMatchCache_memoryFootprint() {
        let cache = MatchCache()

        // 添加100个用户的缓存
        for _ in 0..<100 {
            let userId = UUID()
            let matches = (0..<20).map { _ in
                SkinTwin(
                    userId: UUID(),
                    similarity: Double.random(in: 0.6...1.0),
                    matchLevel: .verySimilar,
                    anonymousProfile: .mock
                )
            }
            cache.set(matches: matches, recommendations: [], for: userId)
        }

        let stats = cache.getStats()

        // 验证缓存统计
        XCTAssertEqual(stats.totalEntries, 100)
        XCTAssertEqual(stats.validEntries, 100)
        XCTAssertEqual(stats.expiredEntries, 0)

        // 内存估算应在合理范围内 (< 5MB)
        XCTAssertLessThan(stats.memoryUsageEstimate, 5 * 1024 * 1024)
    }

    @MainActor
    func testMatchCache_LRUEviction() {
        let cache = MatchCache()

        // 添加超过最大容量的缓存 (默认100)
        for i in 0..<120 {
            let userId = UUID()
            let matches = [SkinTwin.mock]
            cache.set(matches: matches, recommendations: [], for: userId)

            // 验证缓存不超过最大容量
            let stats = cache.getStats()
            XCTAssertLessThanOrEqual(
                stats.totalEntries, 100, "Cache should not exceed max size at iteration \(i)")
        }
    }
}

// MARK: - Concurrency Tests

final class ConcurrencyTests: XCTestCase {

    func testSkinMatcher_concurrentAccess() async {
        let matcher = SkinMatcher()
        let userFP = SkinFingerprint(
            skinType: .combination,
            ageRange: .age25to30,
            concerns: [.acne],
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.3,
            budgetLevel: .moderate
        )

        // 并发执行相似度计算
        await withTaskGroup(of: Double.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let otherFP = SkinFingerprint(
                        skinType: .combination,
                        ageRange: .age25to30,
                        concerns: [.acne],
                        issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
                        fragranceTolerance: .neutral,
                        uvExposure: .medium,
                        irritationHistory: 0.3,
                        budgetLevel: .moderate
                    )
                    return matcher.testWeightedSimilarity(user: userFP, other: otherFP)
                }
            }

            var results: [Double] = []
            for await result in group {
                results.append(result)
            }

            // 验证所有结果一致 (相同输入应产生相同输出)
            XCTAssertEqual(results.count, 100)
            let firstResult = results.first!
            XCTAssertTrue(results.allSatisfy { abs($0 - firstResult) < 0.001 })
        }
    }
}
