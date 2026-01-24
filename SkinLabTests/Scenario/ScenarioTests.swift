// SkinLabTests/Scenario/ScenarioTests.swift
import XCTest

@testable import SkinLab

// MARK: - SkinScenario Tests

final class SkinScenarioTests: XCTestCase {

    // MARK: - All Cases Tests

    func testSkinScenario_allCases_has10Cases() {
        XCTAssertEqual(SkinScenario.allCases.count, 10)
    }

    func testSkinScenario_allCasesContainsExpectedValues() {
        let expectedCases: Set<SkinScenario> = [
            .office, .outdoor, .travel, .postMakeup, .menstrual,
            .stressful, .seasonal, .recovery, .beach, .homeRelax
        ]
        let actualCases = Set(SkinScenario.allCases)
        XCTAssertEqual(actualCases, expectedCases)
    }

    // MARK: - Icon Tests

    func testSkinScenario_icon_isNotEmpty() {
        for scenario in SkinScenario.allCases {
            XCTAssertFalse(scenario.icon.isEmpty, "\(scenario) should have a non-empty icon")
        }
    }

    func testSkinScenario_icon_specificValues() {
        XCTAssertEqual(SkinScenario.office.icon, "building.2")
        XCTAssertEqual(SkinScenario.outdoor.icon, "figure.run")
        XCTAssertEqual(SkinScenario.travel.icon, "airplane")
        XCTAssertEqual(SkinScenario.postMakeup.icon, "face.dashed")
        XCTAssertEqual(SkinScenario.menstrual.icon, "heart.circle")
        XCTAssertEqual(SkinScenario.stressful.icon, "moon.zzz")
        XCTAssertEqual(SkinScenario.seasonal.icon, "leaf")
        XCTAssertEqual(SkinScenario.recovery.icon, "cross.circle")
        XCTAssertEqual(SkinScenario.beach.icon, "sun.horizon")
        XCTAssertEqual(SkinScenario.homeRelax.icon, "house")
    }

    // MARK: - Description Tests

    func testSkinScenario_description_isNotEmpty() {
        for scenario in SkinScenario.allCases {
            XCTAssertFalse(
                scenario.description.isEmpty,
                "\(scenario) should have a non-empty description"
            )
        }
    }

    func testSkinScenario_description_hasMinimumLength() {
        for scenario in SkinScenario.allCases {
            XCTAssertGreaterThan(
                scenario.description.count, 10,
                "\(scenario) description should be descriptive (>10 chars)"
            )
        }
    }

    // MARK: - Color Tests

    func testSkinScenario_color_isNotNil() {
        for scenario in SkinScenario.allCases {
            // Color is a struct, so it's never nil, but we can verify it exists
            let _ = scenario.color
            // If we get here without crash, the color is valid
        }
    }

    // MARK: - Priority Factors Tests

    func testSkinScenario_priorityFactors_areNotEmpty() {
        for scenario in SkinScenario.allCases {
            XCTAssertFalse(
                scenario.priorityFactors.isEmpty,
                "\(scenario) should have priority factors"
            )
        }
    }

    func testSkinScenario_priorityFactors_haveAtLeastThree() {
        for scenario in SkinScenario.allCases {
            XCTAssertGreaterThanOrEqual(
                scenario.priorityFactors.count, 3,
                "\(scenario) should have at least 3 priority factors"
            )
        }
    }

    // MARK: - Duration Hint Tests

    func testSkinScenario_durationHint_isNotEmpty() {
        for scenario in SkinScenario.allCases {
            XCTAssertFalse(
                scenario.durationHint.isEmpty,
                "\(scenario) should have a duration hint"
            )
        }
    }

    // MARK: - RawValue Tests

    func testSkinScenario_rawValues_areChinese() {
        XCTAssertEqual(SkinScenario.office.rawValue, "办公室")
        XCTAssertEqual(SkinScenario.outdoor.rawValue, "户外运动")
        XCTAssertEqual(SkinScenario.travel.rawValue, "长途旅行")
        XCTAssertEqual(SkinScenario.postMakeup.rawValue, "浓妆后")
        XCTAssertEqual(SkinScenario.menstrual.rawValue, "生理期")
        XCTAssertEqual(SkinScenario.stressful.rawValue, "高压期")
        XCTAssertEqual(SkinScenario.seasonal.rawValue, "换季期")
        XCTAssertEqual(SkinScenario.recovery.rawValue, "医美后")
        XCTAssertEqual(SkinScenario.beach.rawValue, "海边度假")
        XCTAssertEqual(SkinScenario.homeRelax.rawValue, "居家放松")
    }

    // MARK: - Identifiable Tests

    func testSkinScenario_id_equalsRawValue() {
        for scenario in SkinScenario.allCases {
            XCTAssertEqual(scenario.id, scenario.rawValue)
        }
    }

    // MARK: - Codable Tests

    func testSkinScenario_codable() throws {
        for scenario in SkinScenario.allCases {
            let encoded = try JSONEncoder().encode(scenario)
            let decoded = try JSONDecoder().decode(SkinScenario.self, from: encoded)
            XCTAssertEqual(scenario, decoded)
        }
    }
}

// MARK: - ScenarioRecommendation Tests

final class ScenarioRecommendationTests: XCTestCase {

    func testScenarioRecommendation_initialization() {
        let recommendation = ScenarioRecommendation(
            scenario: .office,
            summary: "Test summary",
            doList: ["Do this", "Do that"],
            dontList: ["Don't do this"],
            productTips: ["Use this product"],
            ingredientFocus: ["Hyaluronic acid"],
            ingredientAvoid: ["Alcohol"]
        )

        XCTAssertEqual(recommendation.scenario, .office)
        XCTAssertEqual(recommendation.summary, "Test summary")
        XCTAssertEqual(recommendation.doList.count, 2)
        XCTAssertEqual(recommendation.dontList.count, 1)
        XCTAssertEqual(recommendation.productTips.count, 1)
        XCTAssertEqual(recommendation.ingredientFocus.count, 1)
        XCTAssertEqual(recommendation.ingredientAvoid.count, 1)
        XCTAssertNotNil(recommendation.id)
        XCTAssertNotNil(recommendation.generatedAt)
    }

    func testScenarioRecommendation_hasValidDoList() {
        let recommendation = createTestRecommendation()
        XCTAssertFalse(recommendation.doList.isEmpty)
        for item in recommendation.doList {
            XCTAssertFalse(item.isEmpty, "Do list items should not be empty")
        }
    }

    func testScenarioRecommendation_hasValidDontList() {
        let recommendation = createTestRecommendation()
        XCTAssertFalse(recommendation.dontList.isEmpty)
        for item in recommendation.dontList {
            XCTAssertFalse(item.isEmpty, "Don't list items should not be empty")
        }
    }

    func testScenarioRecommendation_codable() throws {
        let original = createTestRecommendation()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScenarioRecommendation.self, from: encoded)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.scenario, decoded.scenario)
        XCTAssertEqual(original.summary, decoded.summary)
        XCTAssertEqual(original.doList, decoded.doList)
        XCTAssertEqual(original.dontList, decoded.dontList)
        XCTAssertEqual(original.productTips, decoded.productTips)
        XCTAssertEqual(original.ingredientFocus, decoded.ingredientFocus)
        XCTAssertEqual(original.ingredientAvoid, decoded.ingredientAvoid)
    }

    // MARK: - Helper Methods

    private func createTestRecommendation() -> ScenarioRecommendation {
        ScenarioRecommendation(
            scenario: .outdoor,
            summary: "Outdoor skincare tips",
            doList: ["Apply sunscreen", "Reapply every 2 hours", "Stay hydrated"],
            dontList: ["Skip sunscreen", "Use heavy products"],
            productTips: ["Use SPF 50+", "Carry facial mist"],
            ingredientFocus: ["Vitamin C", "Vitamin E"],
            ingredientAvoid: ["Retinol during day"]
        )
    }
}

// MARK: - ScenarioAdvisor Tests

final class ScenarioAdvisorTests: XCTestCase {

    private var advisor: ScenarioAdvisor!

    override func setUp() {
        super.setUp()
        advisor = ScenarioAdvisor()
    }

    override func tearDown() {
        advisor = nil
        super.tearDown()
    }

    // MARK: - Generate Recommendation Tests

    func testScenarioAdvisor_generatesRecommendationForAllScenarios() {
        let profile = createTestProfile()

        for scenario in SkinScenario.allCases {
            let recommendation = advisor.generateRecommendation(
                scenario: scenario,
                profile: profile,
                currentAnalysis: nil
            )

            XCTAssertEqual(recommendation.scenario, scenario)
            XCTAssertFalse(recommendation.summary.isEmpty, "\(scenario) should have a summary")
            XCTAssertFalse(recommendation.doList.isEmpty, "\(scenario) should have do list")
            XCTAssertFalse(recommendation.dontList.isEmpty, "\(scenario) should have don't list")
        }
    }

    func testScenarioAdvisor_recommendationHasNonEmptyDoList() {
        let profile = createTestProfile()

        for scenario in SkinScenario.allCases {
            let recommendation = advisor.generateRecommendation(
                scenario: scenario,
                profile: profile,
                currentAnalysis: nil
            )

            XCTAssertGreaterThanOrEqual(
                recommendation.doList.count, 3,
                "\(scenario) should have at least 3 do items"
            )

            for item in recommendation.doList {
                XCTAssertFalse(item.isEmpty, "Do list item should not be empty for \(scenario)")
            }
        }
    }

    func testScenarioAdvisor_recommendationHasNonEmptyDontList() {
        let profile = createTestProfile()

        for scenario in SkinScenario.allCases {
            let recommendation = advisor.generateRecommendation(
                scenario: scenario,
                profile: profile,
                currentAnalysis: nil
            )

            XCTAssertGreaterThanOrEqual(
                recommendation.dontList.count, 2,
                "\(scenario) should have at least 2 don't items"
            )

            for item in recommendation.dontList {
                XCTAssertFalse(item.isEmpty, "Don't list item should not be empty for \(scenario)")
            }
        }
    }

    func testScenarioAdvisor_recommendationHasIngredientFocus() {
        let profile = createTestProfile()

        for scenario in SkinScenario.allCases {
            let recommendation = advisor.generateRecommendation(
                scenario: scenario,
                profile: profile,
                currentAnalysis: nil
            )

            XCTAssertFalse(
                recommendation.ingredientFocus.isEmpty,
                "\(scenario) should have ingredient focus list"
            )
        }
    }

    func testScenarioAdvisor_recommendationHasProductTips() {
        let profile = createTestProfile()

        for scenario in SkinScenario.allCases {
            let recommendation = advisor.generateRecommendation(
                scenario: scenario,
                profile: profile,
                currentAnalysis: nil
            )

            XCTAssertFalse(
                recommendation.productTips.isEmpty,
                "\(scenario) should have product tips"
            )
        }
    }

    // MARK: - Skin Type Affects Recommendations

    func testScenarioAdvisor_skinTypeAffectsRecommendation_oilySkin() {
        let oilyProfile = createTestProfile(skinType: .oily)
        let recommendation = advisor.generateRecommendation(
            scenario: .office,
            profile: oilyProfile,
            currentAnalysis: nil
        )

        // Oily skin should get "clear/light texture" recommendation
        let hasOilyAdvice = recommendation.doList.contains { item in
            item.contains("清爽") || item.contains("轻薄")
        }
        XCTAssertTrue(hasOilyAdvice, "Oily skin should get light texture advice")
    }

    func testScenarioAdvisor_skinTypeAffectsRecommendation_drySkin() {
        let dryProfile = createTestProfile(skinType: .dry)
        let recommendation = advisor.generateRecommendation(
            scenario: .office,
            profile: dryProfile,
            currentAnalysis: nil
        )

        // Dry skin should get moisturizing recommendation
        let hasMoistureAdvice = recommendation.doList.contains { item in
            item.contains("保湿")
        }
        XCTAssertTrue(hasMoistureAdvice, "Dry skin should get moisturizing advice")
    }

    func testScenarioAdvisor_skinTypeAffectsRecommendation_sensitiveSkin() {
        let sensitiveProfile = createTestProfile(skinType: .sensitive)
        let recommendation = advisor.generateRecommendation(
            scenario: .menstrual,
            profile: sensitiveProfile,
            currentAnalysis: nil
        )

        // Sensitive skin should get gentle product advice
        let hasSensitiveAdvice = recommendation.doList.contains { item in
            item.contains("测试") || item.contains("温和")
        }
        let avoidIrritants = recommendation.dontList.contains { item in
            item.contains("刺激")
        }

        XCTAssertTrue(
            hasSensitiveAdvice || avoidIrritants,
            "Sensitive skin should get gentle care advice"
        )
    }

    func testScenarioAdvisor_skinTypeAffectsRecommendation_combinationSkin() {
        let combinationProfile = createTestProfile(skinType: .combination)
        let recommendation = advisor.generateRecommendation(
            scenario: .office,
            profile: combinationProfile,
            currentAnalysis: nil
        )

        // Combination skin should get zone care advice
        let hasZoneAdvice = recommendation.doList.contains { item in
            item.contains("T区") || item.contains("两颊") || item.contains("分区")
        }
        XCTAssertTrue(hasZoneAdvice, "Combination skin should get zone-specific advice")
    }

    // MARK: - Pregnancy Status Tests

    func testScenarioAdvisor_pregnancyAffectsRecommendation() {
        let pregnantProfile = createTestProfile(pregnancyStatus: .pregnant)
        let recommendation = advisor.generateRecommendation(
            scenario: .homeRelax,
            profile: pregnantProfile,
            currentAnalysis: nil
        )

        // Pregnant users should avoid retinol/acids
        let avoidsRetinol = recommendation.dontList.contains { item in
            item.contains("视黄醇") || item.contains("A酸")
        }
        XCTAssertTrue(avoidsRetinol, "Pregnant users should avoid retinol")
    }

    // MARK: - Budget Level Tests

    func testScenarioAdvisor_budgetAffectsProductTips_economy() {
        let economyProfile = createTestProfile(budgetLevel: .economy)
        let recommendation = advisor.generateRecommendation(
            scenario: .office,
            profile: economyProfile,
            currentAnalysis: nil
        )

        let hasEconomyTip = recommendation.productTips.contains { tip in
            tip.contains("药房") || tip.contains("性价比")
        }
        XCTAssertTrue(hasEconomyTip, "Economy budget should get drugstore recommendations")
    }

    func testScenarioAdvisor_budgetAffectsProductTips_luxury() {
        let luxuryProfile = createTestProfile(budgetLevel: .luxury)
        let recommendation = advisor.generateRecommendation(
            scenario: .office,
            profile: luxuryProfile,
            currentAnalysis: nil
        )

        let hasLuxuryTip = recommendation.productTips.contains { tip in
            tip.contains("专业") || tip.contains("贵妇")
        }
        XCTAssertTrue(hasLuxuryTip, "Luxury budget should get premium recommendations")
    }

    // MARK: - Scenario-Specific Tests

    func testScenarioAdvisor_officeScenario_hasSPFAdvice() {
        let profile = createTestProfile()
        let recommendation = advisor.generateRecommendation(
            scenario: .office,
            profile: profile,
            currentAnalysis: nil
        )

        let hasSPFAdvice = recommendation.doList.contains { item in
            item.contains("防晒") || item.contains("蓝光")
        }
        XCTAssertTrue(hasSPFAdvice, "Office scenario should mention SPF or blue light protection")
    }

    func testScenarioAdvisor_outdoorScenario_hasSunscreenAdvice() {
        let profile = createTestProfile()
        let recommendation = advisor.generateRecommendation(
            scenario: .outdoor,
            profile: profile,
            currentAnalysis: nil
        )

        let hasSunscreenAdvice = recommendation.doList.contains { item in
            item.contains("防晒") || item.contains("SPF")
        }
        XCTAssertTrue(hasSunscreenAdvice, "Outdoor scenario should have sunscreen advice")
    }

    func testScenarioAdvisor_beachScenario_hasHighSPF() {
        let profile = createTestProfile()
        let recommendation = advisor.generateRecommendation(
            scenario: .beach,
            profile: profile,
            currentAnalysis: nil
        )

        let hasHighSPF = recommendation.doList.contains { item in
            item.contains("SPF50") || item.contains("PA++++")
        }
        XCTAssertTrue(hasHighSPF, "Beach scenario should recommend high SPF protection")
    }

    func testScenarioAdvisor_recoveryScenario_emphasizesGentle() {
        let profile = createTestProfile()
        let recommendation = advisor.generateRecommendation(
            scenario: .recovery,
            profile: profile,
            currentAnalysis: nil
        )

        let hasGentleAdvice = recommendation.doList.contains { item in
            item.contains("遵医嘱") || item.contains("修复") || item.contains("医用")
        }
        XCTAssertTrue(hasGentleAdvice, "Recovery scenario should emphasize gentle care")

        let avoidsActive = recommendation.dontList.contains { item in
            item.contains("功效") || item.contains("去角质") || item.contains("暴晒")
        }
        XCTAssertTrue(avoidsActive, "Recovery scenario should avoid active ingredients")
    }

    // MARK: - Helper Methods

    private func createTestProfile(
        skinType: SkinType = .combination,
        pregnancyStatus: PregnancyStatus = .notPregnant,
        budgetLevel: BudgetLevel = .moderate
    ) -> UserProfile {
        UserProfile(
            skinType: skinType,
            ageRange: .age25to30,
            concerns: [.pores, .oiliness],
            allergies: [],
            gender: "female",
            pregnancyStatus: pregnancyStatus,
            budgetLevel: budgetLevel
        )
    }
}

// MARK: - ScenarioCategory Tests

final class ScenarioCategoryTests: XCTestCase {

    func testScenarioCategory_allCases_has4Categories() {
        XCTAssertEqual(ScenarioCategory.allCases.count, 4)
    }

    func testScenarioCategory_daily_containsExpectedScenarios() {
        let daily = ScenarioCategory.daily
        XCTAssertTrue(daily.scenarios.contains(.office))
        XCTAssertTrue(daily.scenarios.contains(.homeRelax))
        XCTAssertEqual(daily.scenarios.count, 2)
    }

    func testScenarioCategory_special_containsExpectedScenarios() {
        let special = ScenarioCategory.special
        XCTAssertTrue(special.scenarios.contains(.menstrual))
        XCTAssertTrue(special.scenarios.contains(.stressful))
        XCTAssertTrue(special.scenarios.contains(.seasonal))
        XCTAssertTrue(special.scenarios.contains(.recovery))
        XCTAssertEqual(special.scenarios.count, 4)
    }

    func testScenarioCategory_outdoor_containsExpectedScenarios() {
        let outdoor = ScenarioCategory.outdoor
        XCTAssertTrue(outdoor.scenarios.contains(.outdoor))
        XCTAssertTrue(outdoor.scenarios.contains(.travel))
        XCTAssertTrue(outdoor.scenarios.contains(.beach))
        XCTAssertEqual(outdoor.scenarios.count, 3)
    }

    func testScenarioCategory_care_containsExpectedScenarios() {
        let care = ScenarioCategory.care
        XCTAssertTrue(care.scenarios.contains(.postMakeup))
        XCTAssertEqual(care.scenarios.count, 1)
    }

    func testScenarioCategory_allScenariosAreCovered() {
        var allCategorized = Set<SkinScenario>()
        for category in ScenarioCategory.allCases {
            for scenario in category.scenarios {
                allCategorized.insert(scenario)
            }
        }

        let allScenarios = Set(SkinScenario.allCases)
        XCTAssertEqual(allCategorized, allScenarios, "All scenarios should be in some category")
    }

    func testScenarioCategory_icon_isNotEmpty() {
        for category in ScenarioCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) should have an icon")
        }
    }

    func testScenarioCategory_rawValue_isChinese() {
        XCTAssertEqual(ScenarioCategory.daily.rawValue, "日常")
        XCTAssertEqual(ScenarioCategory.special.rawValue, "特殊时期")
        XCTAssertEqual(ScenarioCategory.outdoor.rawValue, "户外活动")
        XCTAssertEqual(ScenarioCategory.care.rawValue, "护理时机")
    }
}

// MARK: - ScenarioSelection Tests

final class ScenarioSelectionTests: XCTestCase {

    func testScenarioSelection_initialization() {
        let selection = ScenarioSelection(
            scenario: .office,
            notes: "Working from home today"
        )

        XCTAssertEqual(selection.scenario, .office)
        XCTAssertEqual(selection.notes, "Working from home today")
        XCTAssertNotNil(selection.id)
        XCTAssertNotNil(selection.selectedAt)
    }

    func testScenarioSelection_initializationWithoutNotes() {
        let selection = ScenarioSelection(scenario: .beach)

        XCTAssertEqual(selection.scenario, .beach)
        XCTAssertNil(selection.notes)
    }

    func testScenarioSelection_codable() throws {
        let original = ScenarioSelection(
            scenario: .travel,
            notes: "Flying to Tokyo"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScenarioSelection.self, from: encoded)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.scenario, decoded.scenario)
        XCTAssertEqual(original.notes, decoded.notes)
    }
}
