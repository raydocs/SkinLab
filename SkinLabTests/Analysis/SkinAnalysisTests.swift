// SkinLabTests/Analysis/SkinAnalysisTests.swift
import XCTest

@testable import SkinLab

final class SkinAnalysisTests: XCTestCase {

    // MARK: - SkinType Tests

    func testSkinType_displayName() {
        XCTAssertEqual(SkinType.dry.displayName, "干性")
        XCTAssertEqual(SkinType.oily.displayName, "油性")
        XCTAssertEqual(SkinType.combination.displayName, "混合性")
        XCTAssertEqual(SkinType.sensitive.displayName, "敏感性")
    }

    func testSkinType_icon() {
        XCTAssertEqual(SkinType.dry.icon, "drop")
        XCTAssertEqual(SkinType.oily.icon, "drop.fill")
        XCTAssertEqual(SkinType.combination.icon, "circle.lefthalf.filled")
        XCTAssertEqual(SkinType.sensitive.icon, "exclamationmark.triangle")
    }

    func testSkinType_allCases() {
        XCTAssertEqual(SkinType.allCases.count, 4)
    }

    func testSkinType_codable() throws {
        let original = SkinType.combination
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinType.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - IssueScores Tests

    func testIssueScores_empty() {
        let empty = IssueScores.empty
        XCTAssertEqual(empty.spots, 0)
        XCTAssertEqual(empty.acne, 0)
        XCTAssertEqual(empty.pores, 0)
        XCTAssertEqual(empty.wrinkles, 0)
        XCTAssertEqual(empty.redness, 0)
        XCTAssertEqual(empty.evenness, 0)
        XCTAssertEqual(empty.texture, 0)
    }

    func testIssueScores_equatable() {
        let scores1 = IssueScores(
            spots: 3, acne: 4, pores: 5, wrinkles: 2, redness: 3, evenness: 4, texture: 3)
        let scores2 = IssueScores(
            spots: 3, acne: 4, pores: 5, wrinkles: 2, redness: 3, evenness: 4, texture: 3)
        let scores3 = IssueScores(
            spots: 5, acne: 4, pores: 5, wrinkles: 2, redness: 3, evenness: 4, texture: 3)

        XCTAssertEqual(scores1, scores2)
        XCTAssertNotEqual(scores1, scores3)
    }

    func testIssueScores_codable() throws {
        let original = IssueScores(
            spots: 3, acne: 4, pores: 5, wrinkles: 2, redness: 3, evenness: 4, texture: 3)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IssueScores.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - RegionScores Tests

    func testRegionScores_empty() {
        let empty = RegionScores.empty
        XCTAssertEqual(empty.tZone, 0)
        XCTAssertEqual(empty.leftCheek, 0)
        XCTAssertEqual(empty.rightCheek, 0)
        XCTAssertEqual(empty.eyeArea, 0)
        XCTAssertEqual(empty.chin, 0)
    }

    func testRegionScores_equatable() {
        let regions1 = RegionScores(tZone: 68, leftCheek: 78, rightCheek: 76, eyeArea: 72, chin: 70)
        let regions2 = RegionScores(tZone: 68, leftCheek: 78, rightCheek: 76, eyeArea: 72, chin: 70)
        let regions3 = RegionScores(tZone: 50, leftCheek: 78, rightCheek: 76, eyeArea: 72, chin: 70)

        XCTAssertEqual(regions1, regions2)
        XCTAssertNotEqual(regions1, regions3)
    }

    func testRegionScores_codable() throws {
        let original = RegionScores(tZone: 68, leftCheek: 78, rightCheek: 76, eyeArea: 72, chin: 70)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RegionScores.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - SkinAnalysis Tests

    func testSkinAnalysis_initialization() {
        let analysis = SkinAnalysis(
            skinType: .combination,
            skinAge: 26,
            overallScore: 75,
            issues: .empty,
            regions: .empty,
            recommendations: ["Test recommendation"]
        )

        XCTAssertEqual(analysis.skinType, .combination)
        XCTAssertEqual(analysis.skinAge, 26)
        XCTAssertEqual(analysis.overallScore, 75)
        XCTAssertEqual(analysis.recommendations.count, 1)
        XCTAssertNotNil(analysis.id)
    }

    func testSkinAnalysis_mock() {
        let mock = SkinAnalysis.mock

        XCTAssertEqual(mock.skinType, .combination)
        XCTAssertEqual(mock.skinAge, 26)
        XCTAssertEqual(mock.overallScore, 75)
        XCTAssertEqual(mock.issues.spots, 3)
        XCTAssertEqual(mock.regions.tZone, 68)
        XCTAssertEqual(mock.recommendations.count, 3)
    }

    func testSkinAnalysis_identifiable() {
        let analysis1 = SkinAnalysis(
            skinType: .oily,
            skinAge: 30,
            overallScore: 80,
            issues: .empty,
            regions: .empty,
            recommendations: []
        )
        let analysis2 = SkinAnalysis(
            skinType: .oily,
            skinAge: 30,
            overallScore: 80,
            issues: .empty,
            regions: .empty,
            recommendations: []
        )

        // Different IDs even with same content
        XCTAssertNotEqual(analysis1.id, analysis2.id)
    }

    func testSkinAnalysis_codable() throws {
        let original = SkinAnalysis.mock
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinAnalysis.self, from: encoded)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.skinType, decoded.skinType)
        XCTAssertEqual(original.skinAge, decoded.skinAge)
        XCTAssertEqual(original.overallScore, decoded.overallScore)
        XCTAssertEqual(original.issues, decoded.issues)
        XCTAssertEqual(original.regions, decoded.regions)
        XCTAssertEqual(original.recommendations, decoded.recommendations)
    }

    func testSkinAnalysis_equatable() {
        let id = UUID()
        let date = Date()

        let analysis1 = SkinAnalysis(
            id: id,
            skinType: .dry,
            skinAge: 25,
            overallScore: 70,
            issues: .empty,
            regions: .empty,
            recommendations: ["Rec1"],
            analyzedAt: date
        )
        let analysis2 = SkinAnalysis(
            id: id,
            skinType: .dry,
            skinAge: 25,
            overallScore: 70,
            issues: .empty,
            regions: .empty,
            recommendations: ["Rec1"],
            analyzedAt: date
        )

        XCTAssertEqual(analysis1, analysis2)
    }
}

// MARK: - SkincareRoutine Tests

final class SkincareRoutineTests: XCTestCase {

    // MARK: - RoutinePhase Tests

    func testRoutinePhase_displayName() {
        XCTAssertEqual(RoutinePhase.am.displayName, "早上")
        XCTAssertEqual(RoutinePhase.pm.displayName, "晚上")
    }

    func testRoutinePhase_allCases() {
        XCTAssertEqual(RoutinePhase.allCases.count, 2)
    }

    func testRoutinePhase_codable() throws {
        for phase in RoutinePhase.allCases {
            let encoded = try JSONEncoder().encode(phase)
            let decoded = try JSONDecoder().decode(RoutinePhase.self, from: encoded)
            XCTAssertEqual(phase, decoded)
        }
    }

    // MARK: - RoutineGoal Tests

    func testRoutineGoal_displayName() {
        XCTAssertEqual(RoutineGoal.acne.displayName, "控痘祛痘")
        XCTAssertEqual(RoutineGoal.sensitivity.displayName, "舒缓敏感")
        XCTAssertEqual(RoutineGoal.dryness.displayName, "补水保湿")
        XCTAssertEqual(RoutineGoal.pores.displayName, "细致毛孔")
        XCTAssertEqual(RoutineGoal.pigmentation.displayName, "淡化色斑")
        XCTAssertEqual(RoutineGoal.antiAging.displayName, "抗衰老化")
    }

    func testRoutineGoal_allCases() {
        XCTAssertEqual(RoutineGoal.allCases.count, 6)
    }

    // MARK: - RoutineStep Tests

    func testRoutineStep_initialization() {
        let step = RoutineStep(
            phase: .am,
            order: 1,
            title: "洁面",
            productType: "洁面乳",
            instructions: "取适量于掌心",
            frequency: "每天"
        )

        XCTAssertEqual(step.phase, .am)
        XCTAssertEqual(step.order, 1)
        XCTAssertEqual(step.title, "洁面")
        XCTAssertEqual(step.productType, "洁面乳")
        XCTAssertEqual(step.instructions, "取适量于掌心")
        XCTAssertEqual(step.frequency, "每天")
        XCTAssertTrue(step.precautions.isEmpty)
        XCTAssertTrue(step.alternatives.isEmpty)
    }

    func testRoutineStep_withOptionalFields() {
        let step = RoutineStep(
            phase: .pm,
            order: 2,
            title: "精华",
            productType: "精华液",
            instructions: "涂抹于面部",
            frequency: "每晚",
            precautions: ["避开眼周", "敏感肌慎用"],
            alternatives: ["另一款精华"]
        )

        XCTAssertEqual(step.precautions.count, 2)
        XCTAssertEqual(step.alternatives.count, 1)
    }

    func testRoutineStep_hashable() {
        let step1 = RoutineStep(
            phase: .am, order: 1, title: "Step", productType: "Type", instructions: "Inst",
            frequency: "Daily")
        let step2 = RoutineStep(
            phase: .am, order: 1, title: "Step", productType: "Type", instructions: "Inst",
            frequency: "Daily")

        // Different IDs make them different
        XCTAssertNotEqual(step1, step2)

        var set = Set<RoutineStep>()
        set.insert(step1)
        set.insert(step2)
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - SkincareRoutine Tests

    func testSkincareRoutine_amSteps() {
        let amStep1 = RoutineStep(
            phase: .am, order: 2, title: "AM2", productType: "T", instructions: "I", frequency: "F")
        let amStep2 = RoutineStep(
            phase: .am, order: 1, title: "AM1", productType: "T", instructions: "I", frequency: "F")
        let pmStep = RoutineStep(
            phase: .pm, order: 1, title: "PM1", productType: "T", instructions: "I", frequency: "F")

        let routine = SkincareRoutine(
            skinType: .combination,
            concerns: [.acne],
            goals: [.acne],
            steps: [amStep1, pmStep, amStep2],
            notes: []
        )

        let amSteps = routine.amSteps
        XCTAssertEqual(amSteps.count, 2)
        XCTAssertEqual(amSteps[0].order, 1)  // Sorted by order
        XCTAssertEqual(amSteps[1].order, 2)
    }

    func testSkincareRoutine_pmSteps() {
        let amStep = RoutineStep(
            phase: .am, order: 1, title: "AM1", productType: "T", instructions: "I", frequency: "F")
        let pmStep1 = RoutineStep(
            phase: .pm, order: 2, title: "PM2", productType: "T", instructions: "I", frequency: "F")
        let pmStep2 = RoutineStep(
            phase: .pm, order: 1, title: "PM1", productType: "T", instructions: "I", frequency: "F")

        let routine = SkincareRoutine(
            skinType: .dry,
            concerns: [.dryness],
            goals: [.dryness],
            steps: [amStep, pmStep1, pmStep2],
            notes: []
        )

        let pmSteps = routine.pmSteps
        XCTAssertEqual(pmSteps.count, 2)
        XCTAssertEqual(pmSteps[0].order, 1)
        XCTAssertEqual(pmSteps[1].order, 2)
    }

    func testSkincareRoutine_weeksDuration_default() {
        let routine = SkincareRoutine(
            skinType: .oily,
            concerns: [],
            goals: [],
            steps: [],
            notes: []
        )

        XCTAssertEqual(routine.weeksDuration, 4)  // Default value
    }

    func testSkincareRoutine_weeksDuration_custom() {
        let routine = SkincareRoutine(
            skinType: .sensitive,
            concerns: [.sensitivity],
            goals: [.sensitivity],
            steps: [],
            notes: ["Take it slow"],
            weeksDuration: 8
        )

        XCTAssertEqual(routine.weeksDuration, 8)
    }

    func testSkincareRoutine_codable() throws {
        let step = RoutineStep(
            phase: .am, order: 1, title: "Test", productType: "Type", instructions: "Inst",
            frequency: "Daily")
        let routine = SkincareRoutine(
            skinType: .combination,
            concerns: [.acne, .pores],
            goals: [.acne, .pores],
            steps: [step],
            notes: ["Note 1"],
            weeksDuration: 6
        )

        let encoded = try JSONEncoder().encode(routine)
        let decoded = try JSONDecoder().decode(SkincareRoutine.self, from: encoded)

        XCTAssertEqual(routine.id, decoded.id)
        XCTAssertEqual(routine.skinType, decoded.skinType)
        XCTAssertEqual(routine.concerns, decoded.concerns)
        XCTAssertEqual(routine.goals, decoded.goals)
        XCTAssertEqual(routine.steps.count, decoded.steps.count)
        XCTAssertEqual(routine.notes, decoded.notes)
        XCTAssertEqual(routine.weeksDuration, decoded.weeksDuration)
    }
}
