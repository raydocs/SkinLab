// SkinLabTests/Community/SkinTwinViewModelTests.swift
import XCTest

@testable import SkinLab

final class SkinTwinViewModelTests: XCTestCase {

    // MARK: - MatchStats Tests

    func testMatchStats_summary_withTwin() {
        let stats = MatchStats(
            totalMatches: 5,
            avgSimilarity: 0.85,
            twinCount: 1,
            verySimilarCount: 2,
            recommendedProductCount: 8,
            totalEffectiveProducts: 15
        )

        XCTAssertTrue(stats.summary.contains("1位皮肤双胞胎"))
        XCTAssertTrue(stats.summary.contains("2位相似用户"))
    }

    func testMatchStats_summary_noTwin() {
        let stats = MatchStats(
            totalMatches: 5,
            avgSimilarity: 0.78,
            twinCount: 0,
            verySimilarCount: 3,
            recommendedProductCount: 5,
            totalEffectiveProducts: 10
        )

        XCTAssertTrue(stats.summary.contains("3位非常相似"))
        XCTAssertFalse(stats.summary.contains("皮肤双胞胎"))
    }

    func testMatchStats_summary_onlySimilar() {
        let stats = MatchStats(
            totalMatches: 5,
            avgSimilarity: 0.65,
            twinCount: 0,
            verySimilarCount: 0,
            recommendedProductCount: 3,
            totalEffectiveProducts: 5
        )

        XCTAssertTrue(stats.summary.contains("5位相似用户"))
    }

    func testMatchStats_avgSimilarityPercent() {
        let stats = MatchStats(
            totalMatches: 5,
            avgSimilarity: 0.856,
            twinCount: 1,
            verySimilarCount: 2,
            recommendedProductCount: 8,
            totalEffectiveProducts: 15
        )

        XCTAssertEqual(stats.avgSimilarityPercent, 85)
    }

    // MARK: - MatchError Tests

    func testMatchError_invalidFingerprint() {
        let error = MatchError.invalidFingerprint
        XCTAssertEqual(error.errorDescription, "无法生成皮肤指纹，请完善个人资料")
    }

    func testMatchError_noMatches() {
        let error = MatchError.noMatches
        XCTAssertEqual(error.errorDescription, "暂无匹配的皮肤双胞胎，请稍后再试")
    }

    func testMatchError_emptyPool() {
        let error = MatchError.emptyPool
        XCTAssertEqual(error.errorDescription, "匹配池为空，暂无其他用户参与匹配")
    }

    func testMatchError_serviceUnavailable() {
        let error = MatchError.serviceUnavailable
        XCTAssertEqual(error.errorDescription, "服务暂不可用，请稍后重试")
    }

    func testMatchError_cacheError() {
        let error = MatchError.cacheError
        XCTAssertEqual(error.errorDescription, "缓存读取错误")
    }

    // MARK: - ConsentLevel Tests

    func testConsentLevel_canParticipate() {
        XCTAssertFalse(ConsentLevel.none.canParticipate)
        XCTAssertTrue(ConsentLevel.anonymous.canParticipate)
        XCTAssertTrue(ConsentLevel.pseudonymous.canParticipate)
        XCTAssertTrue(ConsentLevel.public.canParticipate)
    }

    func testConsentLevel_canShowProfile() {
        XCTAssertFalse(ConsentLevel.none.canShowProfile)
        XCTAssertFalse(ConsentLevel.anonymous.canShowProfile)
        XCTAssertTrue(ConsentLevel.pseudonymous.canShowProfile)
        XCTAssertTrue(ConsentLevel.public.canShowProfile)
    }

    func testConsentLevel_descriptions() {
        XCTAssertFalse(ConsentLevel.none.description.isEmpty)
        XCTAssertFalse(ConsentLevel.anonymous.description.isEmpty)
        XCTAssertFalse(ConsentLevel.pseudonymous.description.isEmpty)
        XCTAssertFalse(ConsentLevel.public.description.isEmpty)
    }

    // MARK: - SkinTwin Tests

    func testSkinTwin_similarityPercent() {
        let twin = SkinTwin(
            userId: UUID(),
            similarity: 0.923,
            matchLevel: .twin,
            anonymousProfile: .mock
        )

        XCTAssertEqual(twin.similarityPercent, 92)
    }

    func testSkinTwin_commonConcerns() {
        let profile = AnonymousProfile(
            skinType: .combination,
            ageRange: .age25to30,
            mainConcerns: [.acne, .pores, .oiliness],
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            region: nil
        )

        let twin = SkinTwin(
            userId: UUID(),
            similarity: 0.85,
            matchLevel: .verySimilar,
            anonymousProfile: profile
        )

        let userConcerns: [SkinConcern] = [.acne, .sensitivity, .pores]
        let common = twin.commonConcerns(with: userConcerns)

        XCTAssertEqual(common.count, 2)
        XCTAssertTrue(common.contains(.acne))
        XCTAssertTrue(common.contains(.pores))
    }

    // MARK: - MatchCache Tests

    func testCacheStats_formattedMemoryUsage_bytes() {
        let stats = CacheStats(
            totalEntries: 1,
            validEntries: 1,
            expiredEntries: 0,
            avgAge: 3600,
            totalMatches: 5,
            totalRecommendations: 3,
            memoryUsageEstimate: 500
        )

        XCTAssertEqual(stats.formattedMemoryUsage, "500 B")
    }

    func testCacheStats_formattedMemoryUsage_kilobytes() {
        let stats = CacheStats(
            totalEntries: 10,
            validEntries: 8,
            expiredEntries: 2,
            avgAge: 7200,
            totalMatches: 50,
            totalRecommendations: 30,
            memoryUsageEstimate: 5120
        )

        XCTAssertEqual(stats.formattedMemoryUsage, "5.0 KB")
    }

    func testCacheStats_formattedAvgAge() {
        let stats = CacheStats(
            totalEntries: 5,
            validEntries: 5,
            expiredEntries: 0,
            avgAge: 5400,  // 1.5 hours
            totalMatches: 25,
            totalRecommendations: 15,
            memoryUsageEstimate: 10000
        )

        XCTAssertEqual(stats.formattedAvgAge, "1h 30m")
    }
}

// MARK: - AnonymousProfile Tests

final class AnonymousProfileTests: XCTestCase {

    func testAnonymousProfile_mock() {
        let profile = AnonymousProfile.mock

        XCTAssertEqual(profile.skinType, .combination)
        XCTAssertEqual(profile.ageRange, .age25to30)
        XCTAssertEqual(profile.mainConcerns.count, 3)
        XCTAssertEqual(profile.issueVector.count, 7)
        XCTAssertEqual(profile.region, "广东省")
    }

    func testAnonymousProfile_equatable() {
        let profile1 = AnonymousProfile(
            skinType: .oily,
            ageRange: .age20to25,
            mainConcerns: [.acne],
            issueVector: [0.5],
            region: "北京"
        )

        let profile2 = AnonymousProfile(
            skinType: .oily,
            ageRange: .age20to25,
            mainConcerns: [.acne],
            issueVector: [0.5],
            region: "北京"
        )

        XCTAssertEqual(profile1, profile2)
    }

    func testAnonymousProfile_hashable() {
        let profile1 = AnonymousProfile.mock
        let profile2 = AnonymousProfile.mock

        // 相同值应有相同hash
        XCTAssertEqual(profile1.hashValue, profile2.hashValue)

        // 可以放入Set
        let set: Set<AnonymousProfile> = [profile1, profile2]
        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - MatchLevel Tests

final class MatchLevelTests: XCTestCase {

    func testMatchLevel_allCases() {
        XCTAssertEqual(MatchLevel.allCases.count, 4)
    }

    func testMatchLevel_rawValues() {
        XCTAssertTrue(MatchLevel.twin.rawValue.contains("双胞胎"))
        XCTAssertTrue(MatchLevel.verySimilar.rawValue.contains("非常相似"))
        XCTAssertTrue(MatchLevel.similar.rawValue.contains("相似"))
        XCTAssertTrue(MatchLevel.somewhatSimilar.rawValue.contains("有点相似"))
    }

    func testMatchLevel_colorName() {
        XCTAssertEqual(MatchLevel.twin.colorName, "skinLabPrimary")
        XCTAssertEqual(MatchLevel.verySimilar.colorName, "skinLabSecondary")
        XCTAssertEqual(MatchLevel.similar.colorName, "skinLabAccent")
        XCTAssertEqual(MatchLevel.somewhatSimilar.colorName, "skinLabSubtext")
    }

    func testMatchLevel_icon() {
        XCTAssertFalse(MatchLevel.twin.icon.isEmpty)
        XCTAssertFalse(MatchLevel.verySimilar.icon.isEmpty)
        XCTAssertFalse(MatchLevel.similar.icon.isEmpty)
        XCTAssertFalse(MatchLevel.somewhatSimilar.icon.isEmpty)
    }
}
