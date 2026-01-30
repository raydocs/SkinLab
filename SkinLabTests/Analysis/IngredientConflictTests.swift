// SkinLabTests/Analysis/IngredientConflictTests.swift
@testable import SkinLab
import XCTest

final class IngredientConflictTests: XCTestCase {
    // MARK: - Knowledge Base Tests

    func testConflictKnowledgeBase_hasAtLeast15ConflictPairs() {
        // Verify knowledge base has at least 15 conflict pairs as specified
        XCTAssertGreaterThanOrEqual(
            ConflictKnowledgeBase.conflicts.count,
            15,
            "Knowledge base should have at least 15 conflict pairs"
        )
    }

    func testConflictKnowledgeBase_containsRetinolAHAConflict() {
        // Verify retinol + AHA conflict exists and is marked as danger
        let retinolAHAConflict = ConflictKnowledgeBase.conflicts.first {
            ($0.ingredient1 == "retinol" && $0.ingredient2 == "aha") ||
                ($0.ingredient1 == "aha" && $0.ingredient2 == "retinol")
        }

        XCTAssertNotNil(retinolAHAConflict, "Retinol + AHA conflict should exist")
        XCTAssertEqual(retinolAHAConflict?.severity, .danger, "Retinol + AHA should be danger severity")
    }

    func testConflictKnowledgeBase_containsVitaminCNiacinamideConflict() {
        // Verify vitamin C + niacinamide conflict exists and is marked as warning
        let vcNiacinamideConflict = ConflictKnowledgeBase.conflicts.first {
            ($0.ingredient1 == "vitamin c" && $0.ingredient2 == "niacinamide") ||
                ($0.ingredient1 == "niacinamide" && $0.ingredient2 == "vitamin c")
        }

        XCTAssertNotNil(vcNiacinamideConflict, "Vitamin C + Niacinamide conflict should exist")
        XCTAssertEqual(vcNiacinamideConflict?.severity, .warning, "Vitamin C + Niacinamide should be warning severity")
    }

    // MARK: - Conflict Severity Tests

    func testConflictSeverity_displayColor() {
        XCTAssertEqual(ConflictSeverity.warning.displayColor, "orange")
        XCTAssertEqual(ConflictSeverity.danger.displayColor, "red")
    }

    func testConflictSeverity_icon() {
        XCTAssertEqual(ConflictSeverity.warning.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(ConflictSeverity.danger.icon, "xmark.octagon.fill")
    }

    func testConflictSeverity_rawValue() {
        XCTAssertEqual(ConflictSeverity.warning.rawValue, "警告")
        XCTAssertEqual(ConflictSeverity.danger.rawValue, "危险")
    }

    // MARK: - IngredientConflict Model Tests

    func testIngredientConflict_initialization() {
        let conflict = IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "aha",
            severity: .danger,
            description: "Test description",
            recommendation: "Test recommendation"
        )

        XCTAssertEqual(conflict.ingredient1, "retinol")
        XCTAssertEqual(conflict.ingredient2, "aha")
        XCTAssertEqual(conflict.severity, .danger)
        XCTAssertEqual(conflict.description, "Test description")
        XCTAssertEqual(conflict.recommendation, "Test recommendation")
        XCTAssertNotNil(conflict.id)
    }

    func testIngredientConflict_codable() throws {
        let original = IngredientConflict(
            ingredient1: "vitamin c",
            ingredient2: "niacinamide",
            severity: .warning,
            description: "高浓度时可能产生冲突",
            recommendation: "低浓度可以同用"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IngredientConflict.self, from: encoded)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.ingredient1, decoded.ingredient1)
        XCTAssertEqual(original.ingredient2, decoded.ingredient2)
        XCTAssertEqual(original.severity, decoded.severity)
        XCTAssertEqual(original.description, decoded.description)
        XCTAssertEqual(original.recommendation, decoded.recommendation)
    }

    // MARK: - Conflict Detection Tests (via IngredientRiskAnalyzer)

    @MainActor
    func testDetectConflicts_findsRetinolAHAConflict() {
        let analyzer = IngredientRiskAnalyzer()

        // Create ingredients with retinol and AHA (glycolic acid)
        let ingredients = [
            createParsedIngredient(name: "Retinol", normalizedName: "Retinol"),
            createParsedIngredient(name: "Glycolic Acid", normalizedName: "Glycolic Acid"),
            createParsedIngredient(name: "Water", normalizedName: "Water")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Should detect retinol + AHA conflict
        XCTAssertFalse(result.conflicts.isEmpty, "Should detect conflicts")
        XCTAssertTrue(result.hasDangerConflicts, "Should have danger conflicts")

        // Verify the specific conflict
        let hasRetinolAHAConflict = result.conflicts.contains { conflict in
            (conflict.ingredient1 == "retinol" && conflict.ingredient2 == "aha") ||
                (conflict.ingredient1 == "aha" && conflict.ingredient2 == "retinol")
        }
        XCTAssertTrue(hasRetinolAHAConflict, "Should find retinol + AHA conflict")
    }

    @MainActor
    func testDetectConflicts_findsVitaminCNiacinamideConflict() {
        let analyzer = IngredientRiskAnalyzer()

        // Create ingredients with Vitamin C and Niacinamide
        let ingredients = [
            createParsedIngredient(name: "Ascorbic Acid", normalizedName: "Ascorbic Acid"),
            createParsedIngredient(name: "Niacinamide", normalizedName: "Niacinamide"),
            createParsedIngredient(name: "Water", normalizedName: "Water")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Should detect vitamin C + niacinamide conflict
        XCTAssertFalse(result.conflicts.isEmpty, "Should detect conflicts")
        XCTAssertTrue(result.hasWarningConflicts, "Should have warning conflicts")

        // Verify the specific conflict
        let hasVCNiacinamideConflict = result.conflicts.contains { conflict in
            (conflict.ingredient1 == "vitamin c" && conflict.ingredient2 == "niacinamide") ||
                (conflict.ingredient1 == "niacinamide" && conflict.ingredient2 == "vitamin c")
        }
        XCTAssertTrue(hasVCNiacinamideConflict, "Should find vitamin C + niacinamide conflict")
    }

    @MainActor
    func testDetectConflicts_noConflictsWhenIngredientsDoNotConflict() {
        let analyzer = IngredientRiskAnalyzer()

        // Create ingredients that don't conflict with each other
        let ingredients = [
            createParsedIngredient(name: "Hyaluronic Acid", normalizedName: "Hyaluronic Acid"),
            createParsedIngredient(name: "Glycerin", normalizedName: "Glycerin"),
            createParsedIngredient(name: "Water", normalizedName: "Water"),
            createParsedIngredient(name: "Ceramide", normalizedName: "Ceramide")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Should have no conflicts
        XCTAssertTrue(result.conflicts.isEmpty, "Should have no conflicts for non-conflicting ingredients")
        XCTAssertFalse(result.hasDangerConflicts)
        XCTAssertFalse(result.hasWarningConflicts)
    }

    @MainActor
    func testDetectConflicts_aliasMatching_ascorbicAcidMatchesVitaminC() {
        let analyzer = IngredientRiskAnalyzer()

        // Use "Ascorbic Acid" which should match "vitamin c" conflicts
        let ingredients = [
            createParsedIngredient(name: "Ascorbic Acid", normalizedName: "Ascorbic Acid"),
            createParsedIngredient(name: "Niacinamide", normalizedName: "Niacinamide")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Ascorbic Acid should be recognized as Vitamin C and trigger the conflict
        XCTAssertFalse(result.conflicts.isEmpty, "Ascorbic Acid should match vitamin C conflicts")

        let hasVCConflict = result.conflicts.contains { conflict in
            conflict.ingredient1 == "vitamin c" || conflict.ingredient2 == "vitamin c"
        }
        XCTAssertTrue(hasVCConflict, "Should recognize Ascorbic Acid as Vitamin C for conflict matching")
    }

    @MainActor
    func testDetectConflicts_multipleConflicts() {
        let analyzer = IngredientRiskAnalyzer()

        // Create a "bad routine" with multiple conflicting ingredients
        let ingredients = [
            createParsedIngredient(name: "Retinol", normalizedName: "Retinol"),
            createParsedIngredient(name: "Glycolic Acid", normalizedName: "Glycolic Acid"), // AHA
            createParsedIngredient(name: "Ascorbic Acid", normalizedName: "Ascorbic Acid"), // Vitamin C
            createParsedIngredient(name: "Niacinamide", normalizedName: "Niacinamide")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Should detect multiple conflicts
        XCTAssertGreaterThan(result.conflicts.count, 1, "Should detect multiple conflicts")
    }

    // MARK: - EnhancedIngredientScanResult Conflict Properties Tests

    @MainActor
    func testEnhancedResult_conflictComputedProperties() {
        let analyzer = IngredientRiskAnalyzer()

        // Create ingredients with both danger and warning conflicts
        let ingredients = [
            createParsedIngredient(name: "Retinol", normalizedName: "Retinol"),
            createParsedIngredient(name: "Glycolic Acid", normalizedName: "Glycolic Acid"), // AHA - danger with retinol
            createParsedIngredient(name: "Ascorbic Acid", normalizedName: "Ascorbic Acid"), // Vitamin C
            createParsedIngredient(name: "Niacinamide", normalizedName: "Niacinamide") // Warning with vitamin C
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Test computed properties
        XCTAssertTrue(result.hasDangerConflicts, "Should have danger conflicts")
        XCTAssertTrue(result.hasWarningConflicts, "Should have warning conflicts")
        XCTAssertFalse(result.dangerConflicts.isEmpty, "dangerConflicts should not be empty")
        XCTAssertFalse(result.warningConflicts.isEmpty, "warningConflicts should not be empty")

        // Verify filtering works correctly
        for conflict in result.dangerConflicts {
            XCTAssertEqual(conflict.severity, .danger)
        }
        for conflict in result.warningConflicts {
            XCTAssertEqual(conflict.severity, .warning)
        }
    }

    @MainActor
    func testEnhancedResult_hasPersonalizedInfo_includesConflicts() {
        let analyzer = IngredientRiskAnalyzer()

        let ingredients = [
            createParsedIngredient(name: "Retinol", normalizedName: "Retinol"),
            createParsedIngredient(name: "Salicylic Acid", normalizedName: "Salicylic Acid") // BHA
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // hasPersonalizedInfo should be true when conflicts exist
        if !result.conflicts.isEmpty {
            XCTAssertTrue(result.hasPersonalizedInfo, "hasPersonalizedInfo should include conflict detection")
        }
    }

    // MARK: - Additional Alias Matching Tests

    @MainActor
    func testDetectConflicts_salicylicAcidMatchesBHA() {
        let analyzer = IngredientRiskAnalyzer()

        let ingredients = [
            createParsedIngredient(name: "Retinol", normalizedName: "Retinol"),
            createParsedIngredient(name: "Salicylic Acid", normalizedName: "Salicylic Acid")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Salicylic Acid should match BHA conflict with retinol
        let hasBHAConflict = result.conflicts.contains { conflict in
            (conflict.ingredient1 == "retinol" && conflict.ingredient2 == "bha") ||
                (conflict.ingredient1 == "bha" && conflict.ingredient2 == "retinol") ||
                (conflict.ingredient1 == "retinol" && conflict.ingredient2 == "salicylic acid") ||
                (conflict.ingredient1 == "salicylic acid" && conflict.ingredient2 == "retinol")
        }
        XCTAssertTrue(hasBHAConflict, "Salicylic Acid should trigger BHA conflict with retinol")
    }

    @MainActor
    func testDetectConflicts_lacticAcidMatchesAHA() {
        let analyzer = IngredientRiskAnalyzer()

        let ingredients = [
            createParsedIngredient(name: "Retinol", normalizedName: "Retinol"),
            createParsedIngredient(name: "Lactic Acid", normalizedName: "Lactic Acid")
        ]

        let scanResult = createScanResult(ingredients: ingredients)
        let result = analyzer.analyze(scanResult: scanResult, profile: nil)

        // Should detect conflict - lactic acid matches AHA
        XCTAssertFalse(result.conflicts.isEmpty, "Lactic Acid should trigger AHA conflict with retinol")
        XCTAssertTrue(result.hasDangerConflicts, "Retinol + Lactic Acid should be danger level")
    }

    // MARK: - Helper Methods

    private func createParsedIngredient(
        name: String,
        normalizedName: String,
        function: IngredientFunction? = nil,
        safetyRating: Int? = nil,
        isHighlight: Bool = false,
        isWarning: Bool = false
    ) -> IngredientScanResult.ParsedIngredient {
        IngredientScanResult.ParsedIngredient(
            name: name,
            normalizedName: normalizedName,
            function: function,
            safetyRating: safetyRating,
            isHighlight: isHighlight,
            isWarning: isWarning
        )
    }

    private func createScanResult(
        ingredients: [IngredientScanResult.ParsedIngredient]
    ) -> IngredientScanResult {
        IngredientScanResult(
            rawText: ingredients.map(\.name).joined(separator: ", "),
            ingredients: ingredients,
            overallSafety: .safe,
            highlights: [],
            warnings: [],
            scanDate: Date()
        )
    }
}
