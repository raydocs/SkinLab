import Foundation
import SwiftData

// MARK: - Product Category
enum ProductCategory: String, Codable, CaseIterable, Sendable {
    case cleanser
    case toner
    case serum
    case moisturizer
    case sunscreen
    case mask
    case exfoliant
    case eyeCream

    var displayName: String {
        switch self {
        case .cleanser: return "洁面"
        case .toner: return "化妆水"
        case .serum: return "精华"
        case .moisturizer: return "面霜"
        case .sunscreen: return "防晒"
        case .mask: return "面膜"
        case .exfoliant: return "去角质"
        case .eyeCream: return "眼霜"
        }
    }

    var icon: String {
        switch self {
        case .cleanser: return "drop.circle"
        case .toner: return "humidity"
        case .serum: return "flask"
        case .moisturizer: return "circle.fill"
        case .sunscreen: return "sun.max"
        case .mask: return "theatermask.and.paintbrush"
        case .exfoliant: return "sparkles"
        case .eyeCream: return "eye"
        }
    }
}

// MARK: - Price Range
enum PriceRange: String, Codable, CaseIterable, Sendable {
    case budget  // < ¥100
    case midRange  // ¥100-300
    case premium  // ¥300-800
    case luxury  // > ¥800

    var displayName: String {
        switch self {
        case .budget: return "平价 (<¥100)"
        case .midRange: return "中端 (¥100-300)"
        case .premium: return "高端 (¥300-800)"
        case .luxury: return "奢侈 (>¥800)"
        }
    }
}

// MARK: - Ingredient
struct Ingredient: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let aliases: [String]
    let function: IngredientFunction
    let safetyRating: Int
    let irritationRisk: IrritationLevel
    let benefits: [String]
    let warnings: [String]?
    let concentration: String?

    init(
        id: UUID = UUID(),
        name: String,
        aliases: [String] = [],
        function: IngredientFunction,
        safetyRating: Int = 5,
        irritationRisk: IrritationLevel = .low,
        benefits: [String] = [],
        warnings: [String]? = nil,
        concentration: String? = nil
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.function = function
        self.safetyRating = safetyRating
        self.irritationRisk = irritationRisk
        self.benefits = benefits
        self.warnings = warnings
        self.concentration = concentration
    }
}

enum IngredientFunction: String, Codable, Sendable {
    case moisturizing
    case antiAging
    case brightening
    case acneFighting
    case soothing
    case exfoliating
    case sunProtection
    case preservative
    case fragrance
    case other

    var displayName: String {
        switch self {
        case .moisturizing: return "保湿"
        case .antiAging: return "抗老"
        case .brightening: return "美白"
        case .acneFighting: return "祛痘"
        case .soothing: return "舒缓"
        case .exfoliating: return "去角质"
        case .sunProtection: return "防晒"
        case .preservative: return "防腐剂"
        case .fragrance: return "香精"
        case .other: return "其他"
        }
    }
}

enum IrritationLevel: String, Codable, Sendable {
    case none, low, medium, high

    var displayName: String {
        switch self {
        case .none: return "无刺激"
        case .low: return "低刺激"
        case .medium: return "中等刺激"
        case .high: return "高刺激"
        }
    }

    var color: String {
        switch self {
        case .none: return "green"
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Product
struct Product: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let brand: String
    let category: ProductCategory
    let ingredients: [Ingredient]
    let skinTypes: [SkinType]
    let concerns: [SkinConcern]
    let priceRange: PriceRange
    let imageUrl: String?
    let purchaseLinks: [PurchaseLink]?

    // Community data
    var effectiveRate: Double?
    var sampleSize: Int?
    var averageRating: Double?

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: ProductCategory,
        ingredients: [Ingredient] = [],
        skinTypes: [SkinType] = [],
        concerns: [SkinConcern] = [],
        priceRange: PriceRange = .midRange,
        imageUrl: String? = nil,
        purchaseLinks: [PurchaseLink]? = nil,
        effectiveRate: Double? = nil,
        sampleSize: Int? = nil,
        averageRating: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.ingredients = ingredients
        self.skinTypes = skinTypes
        self.concerns = concerns
        self.priceRange = priceRange
        self.imageUrl = imageUrl
        self.purchaseLinks = purchaseLinks
        self.effectiveRate = effectiveRate
        self.sampleSize = sampleSize
        self.averageRating = averageRating
    }

    static let mock = Product(
        name: "B5修复霜",
        brand: "La Roche-Posay",
        category: .moisturizer,
        skinTypes: [.sensitive, .dry],
        concerns: [.sensitivity, .dryness],
        priceRange: .midRange,
        effectiveRate: 0.67,
        sampleSize: 328,
        averageRating: 4.8
    )
}

struct PurchaseLink: Codable, Equatable, Hashable, Sendable {
    let platform: String
    let url: String
    let price: Double?
}

// MARK: - SwiftData Model
@Model
final class ProductRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String
    var categoryRaw: String
    var ingredientsData: Data?
    var skinTypesRaw: [String]
    var concernsRaw: [String]
    var priceRangeRaw: String
    var imageUrl: String?
    var effectiveRate: Double?
    var sampleSize: Int?
    var averageRating: Double?
    var updatedAt: Date

    init(from product: Product) {
        self.id = product.id
        self.name = product.name
        self.brand = product.brand
        self.categoryRaw = product.category.rawValue
        self.ingredientsData = try? JSONEncoder().encode(product.ingredients)
        self.skinTypesRaw = product.skinTypes.map(\.rawValue)
        self.concernsRaw = product.concerns.map(\.rawValue)
        self.priceRangeRaw = product.priceRange.rawValue
        self.imageUrl = product.imageUrl
        self.effectiveRate = product.effectiveRate
        self.sampleSize = product.sampleSize
        self.averageRating = product.averageRating
        self.updatedAt = Date()
    }
}
