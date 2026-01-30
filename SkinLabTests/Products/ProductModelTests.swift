// SkinLabTests/Products/ProductModelTests.swift
@testable import SkinLab
import XCTest

final class ProductModelTests: XCTestCase {
    // MARK: - ProductCategory Tests

    func testProductCategory_allCases() {
        XCTAssertEqual(ProductCategory.allCases.count, 8)
    }

    func testProductCategory_displayName() {
        XCTAssertEqual(ProductCategory.cleanser.displayName, "洁面")
        XCTAssertEqual(ProductCategory.toner.displayName, "化妆水")
        XCTAssertEqual(ProductCategory.serum.displayName, "精华")
        XCTAssertEqual(ProductCategory.moisturizer.displayName, "面霜")
        XCTAssertEqual(ProductCategory.sunscreen.displayName, "防晒")
    }

    func testProductCategory_icon() {
        XCTAssertFalse(ProductCategory.cleanser.icon.isEmpty)
        XCTAssertFalse(ProductCategory.serum.icon.isEmpty)
    }

    func testProductCategory_codable() throws {
        for category in ProductCategory.allCases {
            let encoded = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(ProductCategory.self, from: encoded)
            XCTAssertEqual(category, decoded)
        }
    }

    // MARK: - PriceRange Tests

    func testPriceRange_allCases() {
        XCTAssertEqual(PriceRange.allCases.count, 4)
    }

    func testPriceRange_displayName() {
        XCTAssertTrue(PriceRange.budget.displayName.contains("100"))
        XCTAssertTrue(PriceRange.midRange.displayName.contains("100-300"))
        XCTAssertTrue(PriceRange.premium.displayName.contains("300-800"))
        XCTAssertTrue(PriceRange.luxury.displayName.contains("800"))
    }

    // MARK: - IngredientFunction Tests

    func testIngredientFunction_displayName() {
        XCTAssertEqual(IngredientFunction.moisturizing.displayName, "保湿")
        XCTAssertEqual(IngredientFunction.brightening.displayName, "美白")
        XCTAssertEqual(IngredientFunction.antiAging.displayName, "抗老")
        XCTAssertEqual(IngredientFunction.acneFighting.displayName, "祛痘")
        XCTAssertEqual(IngredientFunction.exfoliating.displayName, "去角质")
        XCTAssertEqual(IngredientFunction.soothing.displayName, "舒缓")
        XCTAssertEqual(IngredientFunction.sunProtection.displayName, "防晒")
        XCTAssertEqual(IngredientFunction.fragrance.displayName, "香精")
        XCTAssertEqual(IngredientFunction.preservative.displayName, "防腐剂")
        XCTAssertEqual(IngredientFunction.other.displayName, "其他")
    }

    // MARK: - IrritationLevel Tests

    func testIrritationLevel_displayName() {
        XCTAssertEqual(IrritationLevel.none.displayName, "无刺激")
        XCTAssertEqual(IrritationLevel.low.displayName, "低刺激")
        XCTAssertEqual(IrritationLevel.medium.displayName, "中等刺激")
        XCTAssertEqual(IrritationLevel.high.displayName, "高刺激")
    }

    func testIrritationLevel_color() {
        XCTAssertEqual(IrritationLevel.none.color, "green")
        XCTAssertEqual(IrritationLevel.low.color, "blue")
        XCTAssertEqual(IrritationLevel.medium.color, "orange")
        XCTAssertEqual(IrritationLevel.high.color, "red")
    }

    // MARK: - Ingredient Tests

    func testIngredient_initialization() {
        let ingredient = Ingredient(
            id: UUID(),
            name: "Niacinamide",
            aliases: ["Vitamin B3", "Nicotinamide"],
            function: .brightening,
            safetyRating: 9,
            irritationRisk: .low,
            benefits: ["Brightening", "Pore minimizing"],
            warnings: nil,
            concentration: "5%"
        )

        XCTAssertEqual(ingredient.name, "Niacinamide")
        XCTAssertEqual(ingredient.aliases.count, 2)
        XCTAssertEqual(ingredient.function, .brightening)
        XCTAssertEqual(ingredient.safetyRating, 9)
        XCTAssertEqual(ingredient.irritationRisk, .low)
        XCTAssertEqual(ingredient.benefits.count, 2)
        XCTAssertNil(ingredient.warnings)
        XCTAssertEqual(ingredient.concentration, "5%")
    }

    func testIngredient_defaultValues() {
        let ingredient = Ingredient(
            name: "Test",
            function: .moisturizing
        )

        XCTAssertEqual(ingredient.safetyRating, 5)
        XCTAssertEqual(ingredient.irritationRisk, .low)
        XCTAssertTrue(ingredient.aliases.isEmpty)
        XCTAssertTrue(ingredient.benefits.isEmpty)
    }

    func testIngredient_codable() throws {
        let original = Ingredient(
            id: UUID(),
            name: "Retinol",
            aliases: ["Vitamin A"],
            function: .antiAging,
            safetyRating: 7,
            irritationRisk: .medium,
            benefits: ["Anti-wrinkle"],
            warnings: ["Avoid sun exposure"],
            concentration: "0.5%"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Ingredient.self, from: encoded)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.aliases, decoded.aliases)
        XCTAssertEqual(original.function, decoded.function)
        XCTAssertEqual(original.safetyRating, decoded.safetyRating)
        XCTAssertEqual(original.irritationRisk, decoded.irritationRisk)
    }

    func testIngredient_hashable() {
        let ing1 = Ingredient(name: "Test", function: .moisturizing)
        let ing2 = Ingredient(name: "Test", function: .moisturizing)

        var set = Set<Ingredient>()
        set.insert(ing1)
        set.insert(ing2)

        XCTAssertEqual(set.count, 2) // Different IDs
    }

    // MARK: - Product Tests

    func testProduct_initialization() {
        let ingredient = Ingredient(
            name: "Glycerin",
            function: .moisturizing
        )

        let product = Product(
            id: UUID(),
            name: "Hydrating Serum",
            brand: "TestBrand",
            category: .serum,
            ingredients: [ingredient],
            skinTypes: [.dry, .combination],
            concerns: [.dryness],
            priceRange: .midRange,
            imageUrl: "https://example.com/image.jpg",
            purchaseLinks: nil,
            effectiveRate: 0.85,
            sampleSize: 100,
            averageRating: 4.5
        )

        XCTAssertEqual(product.name, "Hydrating Serum")
        XCTAssertEqual(product.brand, "TestBrand")
        XCTAssertEqual(product.category, .serum)
        XCTAssertEqual(product.ingredients.count, 1)
        XCTAssertEqual(product.skinTypes.count, 2)
        XCTAssertEqual(product.concerns.count, 1)
        XCTAssertEqual(product.priceRange, .midRange)
        XCTAssertEqual(product.effectiveRate, 0.85)
        XCTAssertEqual(product.sampleSize, 100)
        XCTAssertEqual(product.averageRating, 4.5)
    }

    func testProduct_defaultValues() {
        let product = Product(
            name: "Test Product",
            brand: "Test Brand",
            category: .moisturizer
        )

        XCTAssertTrue(product.ingredients.isEmpty)
        XCTAssertTrue(product.skinTypes.isEmpty)
        XCTAssertTrue(product.concerns.isEmpty)
        XCTAssertEqual(product.priceRange, .midRange)
        XCTAssertNil(product.imageUrl)
        XCTAssertNil(product.purchaseLinks)
        XCTAssertNil(product.effectiveRate)
    }

    func testProduct_mock() {
        let mock = Product.mock

        XCTAssertFalse(mock.name.isEmpty)
        XCTAssertFalse(mock.brand.isEmpty)
        XCTAssertNotNil(mock.id)
    }

    func testProduct_codable() throws {
        let product = Product.mock

        let encoded = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(Product.self, from: encoded)

        XCTAssertEqual(product.id, decoded.id)
        XCTAssertEqual(product.name, decoded.name)
        XCTAssertEqual(product.brand, decoded.brand)
    }

    func testProduct_hashable() {
        let product1 = Product(name: "P1", brand: "B", category: .serum)
        let product2 = Product(name: "P2", brand: "B", category: .serum)

        var set = Set<Product>()
        set.insert(product1)
        set.insert(product2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - PurchaseLink Tests

    func testPurchaseLink_initialization() {
        let link = PurchaseLink(
            platform: "Amazon",
            url: "https://amazon.com/product",
            price: 29.99
        )

        XCTAssertEqual(link.platform, "Amazon")
        XCTAssertEqual(link.url, "https://amazon.com/product")
        XCTAssertEqual(link.price, 29.99)
    }

    func testPurchaseLink_withoutPrice() {
        let link = PurchaseLink(
            platform: "Official",
            url: "https://brand.com",
            price: nil
        )

        XCTAssertNil(link.price)
    }
}

// MARK: - IngredientFunction Extension Tests

final class IngredientFunctionExtensionTests: XCTestCase {
    func testIngredientFunction_description() {
        XCTAssertEqual(IngredientFunction.moisturizing.description, "提供水分和锁水功效")
        XCTAssertEqual(IngredientFunction.brightening.description, "淡化色斑，提亮肤色")
        XCTAssertEqual(IngredientFunction.antiAging.description, "减少细纹，紧致肌肤")
    }

    func testIngredientFunction_icon() {
        XCTAssertEqual(IngredientFunction.moisturizing.icon, "drop.fill")
        XCTAssertEqual(IngredientFunction.brightening.icon, "sun.max.fill")
        XCTAssertEqual(IngredientFunction.antiAging.icon, "sparkles")
        XCTAssertEqual(IngredientFunction.soothing.icon, "leaf.fill")
    }
}

// MARK: - FunctionGroup Tests

final class FunctionGroupTests: XCTestCase {
    func testFunctionGroup_displayName() {
        let group = FunctionGroup(
            function: .moisturizing,
            ingredients: [],
            description: "Test description",
            icon: "drop.fill"
        )

        XCTAssertEqual(group.displayName, IngredientFunction.moisturizing.displayName)
    }

    func testFunctionGroup_identifiable() {
        let group1 = FunctionGroup(
            function: .brightening,
            ingredients: [],
            description: "Desc",
            icon: "sun"
        )
        let group2 = FunctionGroup(
            function: .brightening,
            ingredients: [],
            description: "Desc",
            icon: "sun"
        )

        // Different IDs
        XCTAssertNotEqual(group1.id, group2.id)
    }
}

// MARK: - IngredientUserReaction Tests

final class IngredientUserReactionTests: XCTestCase {
    func testIngredientUserReaction_displaySummary_positive() {
        let reaction = IngredientUserReaction(
            ingredientName: "Niacinamide",
            totalUses: 10,
            betterCount: 8,
            worseCount: 1,
            effectivenessRating: .positive,
            confidenceLevel: .high
        )

        XCTAssertTrue(reaction.displaySummary.contains("变好"))
        XCTAssertTrue(reaction.displaySummary.contains("✓"))
    }

    func testIngredientUserReaction_displaySummary_negative() {
        let reaction = IngredientUserReaction(
            ingredientName: "Alcohol",
            totalUses: 5,
            betterCount: 0,
            worseCount: 4,
            effectivenessRating: .negative,
            confidenceLevel: .medium
        )

        XCTAssertTrue(reaction.displaySummary.contains("变差"))
        XCTAssertTrue(reaction.displaySummary.contains("⚠️"))
    }

    func testIngredientUserReaction_displaySummary_neutral() {
        let reaction = IngredientUserReaction(
            ingredientName: "Glycerin",
            totalUses: 8,
            betterCount: 2,
            worseCount: 2,
            effectivenessRating: .neutral,
            confidenceLevel: .medium
        )

        XCTAssertTrue(reaction.displaySummary.contains("效果平平"))
    }

    func testIngredientUserReaction_displaySummary_insufficient() {
        let reaction = IngredientUserReaction(
            ingredientName: "New Ingredient",
            totalUses: 2,
            betterCount: 1,
            worseCount: 0,
            effectivenessRating: .insufficient,
            confidenceLevel: .low
        )

        XCTAssertTrue(reaction.displaySummary.contains("使用次数较少"))
    }
}
