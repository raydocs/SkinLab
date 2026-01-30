// SkinLabTests/Profile/UserProfileTests.swift
@testable import SkinLab
import XCTest

final class UserProfileEnumsTests: XCTestCase {
    // MARK: - AgeRange Tests

    func testAgeRange_displayName() {
        XCTAssertEqual(AgeRange.under20.displayName, "20岁以下")
        XCTAssertEqual(AgeRange.age20to25.displayName, "20-25岁")
        XCTAssertEqual(AgeRange.age25to30.displayName, "25-30岁")
        XCTAssertEqual(AgeRange.age30to35.displayName, "30-35岁")
        XCTAssertEqual(AgeRange.age35to40.displayName, "35-40岁")
        XCTAssertEqual(AgeRange.over40.displayName, "40岁以上")
    }

    func testAgeRange_normalized() {
        XCTAssertEqual(AgeRange.under20.normalized, 0.1, accuracy: 0.001)
        XCTAssertEqual(AgeRange.age20to25.normalized, 0.25, accuracy: 0.001)
        XCTAssertEqual(AgeRange.age25to30.normalized, 0.4, accuracy: 0.001)
        XCTAssertEqual(AgeRange.age30to35.normalized, 0.55, accuracy: 0.001)
        XCTAssertEqual(AgeRange.age35to40.normalized, 0.7, accuracy: 0.001)
        XCTAssertEqual(AgeRange.over40.normalized, 0.85, accuracy: 0.001)
    }

    func testAgeRange_allCases() {
        XCTAssertEqual(AgeRange.allCases.count, 6)
    }

    func testAgeRange_codable() throws {
        for range in AgeRange.allCases {
            let encoded = try JSONEncoder().encode(range)
            let decoded = try JSONDecoder().decode(AgeRange.self, from: encoded)
            XCTAssertEqual(range, decoded)
        }
    }

    // MARK: - SkinConcern Tests

    func testSkinConcern_displayName() {
        XCTAssertEqual(SkinConcern.acne.displayName, "痘痘")
        XCTAssertEqual(SkinConcern.aging.displayName, "抗老")
        XCTAssertEqual(SkinConcern.dryness.displayName, "干燥")
        XCTAssertEqual(SkinConcern.oiliness.displayName, "出油")
        XCTAssertEqual(SkinConcern.sensitivity.displayName, "敏感")
        XCTAssertEqual(SkinConcern.pigmentation.displayName, "色斑")
        XCTAssertEqual(SkinConcern.pores.displayName, "毛孔")
        XCTAssertEqual(SkinConcern.redness.displayName, "泛红")
    }

    func testSkinConcern_icon() {
        XCTAssertEqual(SkinConcern.acne.icon, "circle.fill")
        XCTAssertEqual(SkinConcern.aging.icon, "clock")
        XCTAssertEqual(SkinConcern.sensitivity.icon, "exclamationmark.shield")
        XCTAssertEqual(SkinConcern.redness.icon, "flame")
    }

    func testSkinConcern_allCases() {
        XCTAssertEqual(SkinConcern.allCases.count, 8)
    }

    // MARK: - Gender Tests

    func testGender_displayName() {
        XCTAssertEqual(Gender.male.displayName, "男")
        XCTAssertEqual(Gender.female.displayName, "女")
        XCTAssertEqual(Gender.other.displayName, "其他")
        XCTAssertEqual(Gender.preferNotToSay.displayName, "不愿透露")
    }

    // MARK: - ClimateType Tests

    func testClimateType_allCases() {
        XCTAssertEqual(ClimateType.allCases.count, 5)
    }

    func testClimateType_displayName() {
        XCTAssertEqual(ClimateType.tropical.displayName, "热带")
        XCTAssertEqual(ClimateType.temperate.displayName, "温带")
    }

    // MARK: - UVExposureLevel Tests

    func testUVExposureLevel_normalized() {
        XCTAssertEqual(UVExposureLevel.low.normalized, 0.25, accuracy: 0.001)
        XCTAssertEqual(UVExposureLevel.medium.normalized, 0.5, accuracy: 0.001)
        XCTAssertEqual(UVExposureLevel.high.normalized, 0.75, accuracy: 0.001)
        XCTAssertEqual(UVExposureLevel.veryHigh.normalized, 1.0, accuracy: 0.001)
    }

    // MARK: - PregnancyStatus Tests

    func testPregnancyStatus_requiresSpecialCare() {
        XCTAssertFalse(PregnancyStatus.notPregnant.requiresSpecialCare)
        XCTAssertTrue(PregnancyStatus.pregnant.requiresSpecialCare)
        XCTAssertTrue(PregnancyStatus.breastfeeding.requiresSpecialCare)
    }

    // MARK: - FragranceTolerance Tests

    func testFragranceTolerance_normalized() {
        XCTAssertEqual(FragranceTolerance.love.normalized, 1.0, accuracy: 0.001)
        XCTAssertEqual(FragranceTolerance.neutral.normalized, 0.5, accuracy: 0.001)
        XCTAssertEqual(FragranceTolerance.sensitive.normalized, 0.25, accuracy: 0.001)
        XCTAssertEqual(FragranceTolerance.avoid.normalized, 0.0, accuracy: 0.001)
    }

    // MARK: - BudgetLevel Tests

    func testBudgetLevel_maxPricePerProduct() {
        XCTAssertEqual(BudgetLevel.economy.maxPricePerProduct, 100)
        XCTAssertEqual(BudgetLevel.moderate.maxPricePerProduct, 300)
        XCTAssertEqual(BudgetLevel.premium.maxPricePerProduct, 800)
        XCTAssertEqual(BudgetLevel.luxury.maxPricePerProduct, 2000)
        XCTAssertNil(BudgetLevel.noBudget.maxPricePerProduct)
    }
}

// MARK: - RoutinePreferences Tests

final class RoutinePreferencesTests: XCTestCase {
    func testRoutinePreferences_default() {
        let prefs = RoutinePreferences.default

        XCTAssertEqual(prefs.maxAMSteps, 5)
        XCTAssertEqual(prefs.maxPMSteps, 7)
        XCTAssertFalse(prefs.preferVegan)
        XCTAssertFalse(prefs.preferCrueltyFree)
        XCTAssertFalse(prefs.avoidAlcohol)
        XCTAssertFalse(prefs.avoidFragrance)
        XCTAssertFalse(prefs.avoidEssentialOils)
        XCTAssertFalse(prefs.preferNatural)
    }

    func testRoutinePreferences_customValues() {
        let prefs = RoutinePreferences(
            maxAMSteps: 3,
            maxPMSteps: 5,
            preferVegan: true,
            preferCrueltyFree: true,
            avoidAlcohol: true,
            avoidFragrance: true,
            avoidEssentialOils: false,
            preferNatural: true
        )

        XCTAssertEqual(prefs.maxAMSteps, 3)
        XCTAssertEqual(prefs.maxPMSteps, 5)
        XCTAssertTrue(prefs.preferVegan)
        XCTAssertTrue(prefs.preferCrueltyFree)
        XCTAssertTrue(prefs.avoidAlcohol)
        XCTAssertTrue(prefs.avoidFragrance)
        XCTAssertFalse(prefs.avoidEssentialOils)
        XCTAssertTrue(prefs.preferNatural)
    }

    func testRoutinePreferences_codable() throws {
        let original = RoutinePreferences(
            maxAMSteps: 4,
            maxPMSteps: 6,
            preferVegan: true,
            preferCrueltyFree: false,
            avoidAlcohol: true,
            avoidFragrance: false,
            avoidEssentialOils: true,
            preferNatural: false
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RoutinePreferences.self, from: encoded)

        XCTAssertEqual(original.maxAMSteps, decoded.maxAMSteps)
        XCTAssertEqual(original.maxPMSteps, decoded.maxPMSteps)
        XCTAssertEqual(original.preferVegan, decoded.preferVegan)
        XCTAssertEqual(original.avoidAlcohol, decoded.avoidAlcohol)
    }
}

// MARK: - SkinFingerprint Tests

final class SkinFingerprintTests: XCTestCase {
    func testSkinFingerprint_vectorGeneration() {
        let fingerprint = createTestFingerprint()
        let vector = fingerprint.vector

        // Vector should contain multiple values for encoding
        XCTAssertGreaterThan(vector.count, 10)
    }

    func testSkinFingerprint_skinTypeOneHot() {
        let fingerprint = SkinFingerprint(
            skinType: .oily,
            ageRange: .age25to30,
            concerns: [],
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.3,
            budgetLevel: .moderate
        )

        let vector = fingerprint.vector

        // SkinType order: dry, oily, combination, sensitive
        // Oily is index 1
        XCTAssertEqual(vector[0], 0.0) // dry
        XCTAssertEqual(vector[1], 1.0) // oily
        XCTAssertEqual(vector[2], 0.0) // combination
        XCTAssertEqual(vector[3], 0.0) // sensitive
    }

    func testSkinFingerprint_similarity_identical() {
        let fp1 = createTestFingerprint()
        let fp2 = createTestFingerprint()

        let similarity = fp1.similarity(to: fp2)

        XCTAssertEqual(similarity, 1.0, accuracy: 0.01)
    }

    func testSkinFingerprint_similarity_different() {
        let fp1 = SkinFingerprint(
            skinType: .oily,
            ageRange: .under20,
            concerns: [.acne, .oiliness],
            issueVector: [0.8, 0.8, 0.8, 0.2, 0.2],
            fragranceTolerance: .love,
            uvExposure: .high,
            irritationHistory: 0.2,
            budgetLevel: .economy
        )

        let fp2 = SkinFingerprint(
            skinType: .dry,
            ageRange: .over40,
            concerns: [.aging, .dryness],
            issueVector: [0.2, 0.2, 0.2, 0.8, 0.8],
            fragranceTolerance: .avoid,
            uvExposure: .low,
            irritationHistory: 0.8,
            budgetLevel: .luxury
        )

        let similarity = fp1.similarity(to: fp2)

        XCTAssertLessThan(similarity, 0.5) // Very different profiles
    }

    func testSkinFingerprint_similarity_partialMatch() {
        let fp1 = SkinFingerprint(
            skinType: .combination,
            ageRange: .age25to30,
            concerns: [.acne, .pores],
            issueVector: [0.5, 0.6, 0.7, 0.3, 0.4],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.4,
            budgetLevel: .moderate
        )

        let fp2 = SkinFingerprint(
            skinType: .combination,
            ageRange: .age30to35,
            concerns: [.acne, .aging],
            issueVector: [0.5, 0.5, 0.6, 0.4, 0.4],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.5,
            budgetLevel: .premium
        )

        let similarity = fp1.similarity(to: fp2)

        XCTAssertGreaterThan(similarity, 0.7) // Same skin type, similar concerns
        XCTAssertLessThan(similarity, 1.0)
    }

    func testSkinFingerprint_codable() throws {
        let original = createTestFingerprint()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinFingerprint.self, from: encoded)

        XCTAssertEqual(original.skinType, decoded.skinType)
        XCTAssertEqual(original.ageRange, decoded.ageRange)
        XCTAssertEqual(original.concerns, decoded.concerns)
        XCTAssertEqual(original.fragranceTolerance, decoded.fragranceTolerance)
        XCTAssertEqual(original.uvExposure, decoded.uvExposure)
        XCTAssertEqual(original.irritationHistory, decoded.irritationHistory, accuracy: 0.001)
        XCTAssertEqual(original.budgetLevel, decoded.budgetLevel)
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
}

// MARK: - ConsentLevel Tests

final class ConsentLevelTests: XCTestCase {
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

    func testConsentLevel_description() {
        XCTAssertFalse(ConsentLevel.none.description.isEmpty)
        XCTAssertFalse(ConsentLevel.anonymous.description.isEmpty)
        XCTAssertFalse(ConsentLevel.pseudonymous.description.isEmpty)
        XCTAssertFalse(ConsentLevel.public.description.isEmpty)
    }

    func testConsentLevel_rawValues() {
        XCTAssertEqual(ConsentLevel.none.rawValue, "完全私密")
        XCTAssertEqual(ConsentLevel.anonymous.rawValue, "匿名统计")
        XCTAssertEqual(ConsentLevel.pseudonymous.rawValue, "社区分享")
        XCTAssertEqual(ConsentLevel.public.rawValue, "公开分享")
    }

    func testConsentLevel_allCases() {
        XCTAssertEqual(ConsentLevel.allCases.count, 4)
    }
}

// MARK: - PreferenceSource Tests

final class PreferenceSourceTests: XCTestCase {
    func testPreferenceSource_priority() {
        XCTAssertEqual(PreferenceSource.manual.priority, 3)
        XCTAssertEqual(PreferenceSource.imported.priority, 2)
        XCTAssertEqual(PreferenceSource.autoFromCheckIn.priority, 1)
        XCTAssertEqual(PreferenceSource.autoFromAnalysis.priority, 0)
    }

    func testPreferenceSource_rawValue() {
        XCTAssertEqual(PreferenceSource.manual.rawValue, "手动标记")
        XCTAssertEqual(PreferenceSource.autoFromCheckIn.rawValue, "从打卡自动学习")
        XCTAssertEqual(PreferenceSource.autoFromAnalysis.rawValue, "从分析自动学习")
        XCTAssertEqual(PreferenceSource.imported.rawValue, "导入")
    }
}

// MARK: - PreferenceType Tests

final class PreferenceTypeTests: XCTestCase {
    func testPreferenceType_label() {
        XCTAssertEqual(PreferenceType.loved.label, "喜爱")
        XCTAssertEqual(PreferenceType.liked.label, "喜欢")
        XCTAssertEqual(PreferenceType.neutral.label, "中性")
        XCTAssertEqual(PreferenceType.avoided.label, "避免")
        XCTAssertEqual(PreferenceType.disliked.label, "不喜欢")
    }

    func testPreferenceType_color() {
        XCTAssertEqual(PreferenceType.loved.color, "pink")
        XCTAssertEqual(PreferenceType.liked.color, "green")
        XCTAssertEqual(PreferenceType.neutral.color, "gray")
        XCTAssertEqual(PreferenceType.avoided.color, "orange")
        XCTAssertEqual(PreferenceType.disliked.color, "red")
    }

    func testPreferenceType_icon() {
        XCTAssertEqual(PreferenceType.loved.icon, "heart.fill")
        XCTAssertEqual(PreferenceType.liked.icon, "hand.thumbsup.fill")
        XCTAssertEqual(PreferenceType.neutral.icon, "minus.circle")
    }
}
