import Foundation
import Vision
import UIKit

// MARK: - Ingredient OCR Service
actor IngredientOCRService {
    static let shared = IngredientOCRService()
    
    private let normalizer = IngredientNormalizer()
    
    // MARK: - Recognize Text
    func recognizeIngredients(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observations = request.results, !observations.isEmpty else {
            throw OCRError.noTextFound
        }
        
        // Combine all recognized text
        let fullText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        
        // Parse ingredients from text
        let ingredients = parseIngredients(from: fullText)
        
        return ingredients
    }
    
    // MARK: - Parse Ingredients
    private func parseIngredients(from text: String) -> [String] {
        // Common separators in ingredient lists
        let separators = CharacterSet(charactersIn: ",，、;；/")
        
        // Find the ingredients section
        var ingredientText = text
        
        // Look for common headers
        let headers = ["ingredients:", "成分:", "成分表:", "全成分:", "成份:"]
        for header in headers {
            if let range = text.range(of: header, options: .caseInsensitive) {
                ingredientText = String(text[range.upperBound...])
                break
            }
        }
        
        // Split by separators
        let rawIngredients = ingredientText
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 1 }
        
        // Normalize and clean
        return rawIngredients.map { normalizer.normalize($0) }
    }
}

// MARK: - OCR Errors
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "图片无效"
        case .noTextFound: return "未识别到文字"
        case .parseError: return "解析成分失败"
        }
    }
}

// MARK: - Ingredient Normalizer
struct IngredientNormalizer {
    // Common ingredient aliases mapping
    private let aliasMap: [String: String] = [
        // Water
        "水": "Water",
        "纯净水": "Water",
        "去离子水": "Water",
        "aqua": "Water",
        
        // Niacinamide
        "烟酰胺": "Niacinamide",
        "维生素b3": "Niacinamide",
        "nicotinamide": "Niacinamide",
        
        // Retinol
        "视黄醇": "Retinol",
        "维a醇": "Retinol",
        "a醇": "Retinol",
        
        // Hyaluronic Acid
        "透明质酸": "Hyaluronic Acid",
        "玻尿酸": "Hyaluronic Acid",
        "透明质酸钠": "Sodium Hyaluronate",
        
        // Salicylic Acid
        "水杨酸": "Salicylic Acid",
        
        // Vitamin C
        "抗坏血酸": "Ascorbic Acid",
        "维生素c": "Ascorbic Acid",
        "维c": "Ascorbic Acid",
        
        // Glycerin
        "甘油": "Glycerin",
        "丙三醇": "Glycerin",
        
        // Common preservatives
        "苯氧乙醇": "Phenoxyethanol",
        "羟苯甲酯": "Methylparaben",
        
        // Fragrance
        "香精": "Fragrance",
        "香料": "Fragrance",
        "parfum": "Fragrance",
    ]
    
    func normalize(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove concentration info like (5%) or percentages
        let cleaned = lowercased.replacingOccurrences(
            of: "\\s*\\([^)]*\\)|\\s*\\d+(\\.\\d+)?%",
            with: "",
            options: .regularExpression
        )
        
        // Check alias map
        if let normalized = aliasMap[cleaned] {
            return normalized
        }
        
        // Capitalize first letter of each word
        return ingredient.capitalized
    }
}

// MARK: - Ingredient Analysis Result
struct IngredientScanResult: Identifiable {
    let id = UUID()
    let rawText: String
    let ingredients: [ParsedIngredient]
    let overallSafety: SafetyLevel
    let highlights: [String]
    let warnings: [String]
    let scanDate: Date
    
    struct ParsedIngredient: Identifiable {
        let id = UUID()
        let name: String
        let normalizedName: String
        let function: IngredientFunction?
        let safetyRating: Int?
        let isHighlight: Bool
        let isWarning: Bool
    }
    
    enum SafetyLevel: String {
        case safe = "安全"
        case caution = "谨慎"
        case warning = "警告"
        
        var color: String {
            switch self {
            case .safe: return "green"
            case .caution: return "orange"
            case .warning: return "red"
            }
        }
    }
}

// MARK: - Local Ingredient Database
final class IngredientDatabase: Sendable {
    static let shared = IngredientDatabase()

    // Immutable after init - thread safe
    private let ingredients: [String: IngredientInfo]

    struct IngredientInfo: Codable, Sendable {
        let name: String
        let function: String
        let safetyRating: Int        // 1-10, 10 safest
        let irritationRisk: String
        let benefits: [String]
        let warnings: [String]?
    }

    init() {
        // Built-in database of common ingredients
        ingredients = [
            "water": IngredientInfo(
                name: "Water",
                function: "solvent",
                safetyRating: 10,
                irritationRisk: "none",
                benefits: ["基础溶剂"],
                warnings: nil
            ),
            "niacinamide": IngredientInfo(
                name: "Niacinamide",
                function: "brightening",
                safetyRating: 9,
                irritationRisk: "low",
                benefits: ["美白", "控油", "收缩毛孔", "抗氧化"],
                warnings: nil
            ),
            "retinol": IngredientInfo(
                name: "Retinol",
                function: "antiAging",
                safetyRating: 6,
                irritationRisk: "medium",
                benefits: ["抗老", "促进细胞更新", "淡化细纹"],
                warnings: ["孕妇禁用", "需要建立耐受", "注意防晒"]
            ),
            "hyaluronic acid": IngredientInfo(
                name: "Hyaluronic Acid",
                function: "moisturizing",
                safetyRating: 10,
                irritationRisk: "none",
                benefits: ["保湿", "锁水", "填充细纹"],
                warnings: nil
            ),
            "salicylic acid": IngredientInfo(
                name: "Salicylic Acid",
                function: "exfoliating",
                safetyRating: 7,
                irritationRisk: "medium",
                benefits: ["祛痘", "去角质", "疏通毛孔"],
                warnings: ["敏感肌慎用", "孕妇慎用"]
            ),
            "ascorbic acid": IngredientInfo(
                name: "Ascorbic Acid",
                function: "brightening",
                safetyRating: 8,
                irritationRisk: "low",
                benefits: ["美白", "抗氧化", "促进胶原蛋白"],
                warnings: ["不稳定易氧化", "注意保存"]
            ),
            "fragrance": IngredientInfo(
                name: "Fragrance",
                function: "fragrance",
                safetyRating: 4,
                irritationRisk: "medium",
                benefits: [],
                warnings: ["可能致敏", "敏感肌慎用"]
            ),
            "alcohol": IngredientInfo(
                name: "Alcohol Denat.",
                function: "solvent",
                safetyRating: 5,
                irritationRisk: "medium",
                benefits: ["促进吸收", "清爽感"],
                warnings: ["可能刺激", "干性敏感肌慎用"]
            ),
            "glycerin": IngredientInfo(
                name: "Glycerin",
                function: "moisturizing",
                safetyRating: 10,
                irritationRisk: "none",
                benefits: ["保湿", "温和"],
                warnings: nil
            ),
            "phenoxyethanol": IngredientInfo(
                name: "Phenoxyethanol",
                function: "preservative",
                safetyRating: 7,
                irritationRisk: "low",
                benefits: ["防腐"],
                warnings: ["常规防腐剂，正常使用安全"]
            )
        ]
    }

    func lookup(_ name: String) -> IngredientInfo? {
        let key = name.lowercased()
        return ingredients[key]
    }
    
    func analyze(_ ingredientNames: [String]) -> IngredientScanResult {
        var parsed: [IngredientScanResult.ParsedIngredient] = []
        var highlights: [String] = []
        var warnings: [String] = []
        var totalSafety: Int = 0
        var ratedCount = 0
        
        for name in ingredientNames {
            let info = lookup(name)
            let isHighlight = info?.function == "brightening" || 
                             info?.function == "antiAging" ||
                             info?.function == "moisturizing"
            let isWarning = (info?.safetyRating ?? 10) < 5
            
            let function: IngredientFunction? = {
                guard let funcStr = info?.function else { return nil }
                return IngredientFunction(rawValue: funcStr)
            }()
            
            parsed.append(IngredientScanResult.ParsedIngredient(
                name: name,
                normalizedName: name,
                function: function,
                safetyRating: info?.safetyRating,
                isHighlight: isHighlight,
                isWarning: isWarning
            ))
            
            if isHighlight, let info = info {
                highlights.append("\(info.name): \(info.benefits.joined(separator: "、"))")
            }
            
            if let warning = info?.warnings?.first {
                warnings.append("\(info?.name ?? name): \(warning)")
            }
            
            if let rating = info?.safetyRating {
                totalSafety += rating
                ratedCount += 1
            }
        }
        
        let avgSafety = ratedCount > 0 ? totalSafety / ratedCount : 7
        let safetyLevel: IngredientScanResult.SafetyLevel = {
            switch avgSafety {
            case 8...10: return .safe
            case 5..<8: return .caution
            default: return .warning
            }
        }()
        
        return IngredientScanResult(
            rawText: ingredientNames.joined(separator: ", "),
            ingredients: parsed,
            overallSafety: safetyLevel,
            highlights: highlights,
            warnings: warnings,
            scanDate: Date()
        )
    }
}
