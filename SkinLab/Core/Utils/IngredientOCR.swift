import CoreImage
import Foundation
import UIKit
import Vision

// MARK: - Ingredient OCR Service

actor IngredientOCRService {
    static let shared = IngredientOCRService()

    private let normalizer = IngredientNormalizer()
    private let ciContext = CIContext()

    // MARK: - Image Preprocessing

    private func preprocessImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // Step 1: Resize to reasonable dimensions (max 1024px on longest side)
        let resizedImage = resizeImage(image, maxDimension: 1024)
        guard let resized = resizedImage, let resizedCG = resized.cgImage else { return nil }

        // Step 2: Convert to grayscale and enhance contrast
        let ciImage = CIImage(cgImage: resizedCG)
        let context = ciContext

        // Grayscale conversion
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return resizedImage }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)

        // Enhance contrast for better text recognition
        guard let contrastFilter = CIFilter(name: "CIColorControls"),
              let grayscaleOutput = grayscaleFilter.outputImage else { return resizedImage }

        contrastFilter.setValue(grayscaleOutput, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.3, forKey: kCIInputContrastKey) // Increase contrast
        contrastFilter.setValue(1.1, forKey: kCIInputBrightnessKey) // Slightly increase brightness

        guard let outputImage = contrastFilter.outputImage,
              let processedCG = context.createCGImage(outputImage, from: outputImage.extent) else {
            return resizedImage
        }

        return UIImage(cgImage: processedCG)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let maxSide = max(size.width, size.height)

        if maxSide <= maxDimension {
            return image
        }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized
    }

    // MARK: - Recognize Text

    func recognizeIngredients(from image: UIImage) async throws -> [String] {
        // Preprocess image for better OCR accuracy
        guard let processedImage = preprocessImage(image),
              let cgImage = processedImage.cgImage else {
            throw OCRError.invalidImage
        }

        // Get correct orientation from original image
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        // Create handler with proper orientation
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            throw OCRError.visionError(error)
        }

        guard let observations = request.results, !observations.isEmpty else {
            throw OCRError.noTextFound
        }

        // Calculate average confidence
        let confidenceSum = observations.compactMap { $0.topCandidates(1).first?.confidence }.reduce(0, +)
        let avgConfidence = Float(confidenceSum) / Float(observations.count)

        // If confidence is too low, throw specific error
        if avgConfidence < 0.3 {
            throw OCRError.lowConfidence(avgConfidence)
        }

        // Preserve line structure for better parsing
        let lines = observations
            .compactMap { $0.topCandidates(1).first }
            .filter { $0.confidence > 0.5 } // Filter out low-confidence results
            .map(\.string)

        // Parse ingredients from structured lines
        return parseIngredients(fromLines: lines)
    }

    // MARK: - Parse Ingredients (from structured lines)

    private func parseIngredients(fromLines lines: [String]) -> [String] {
        var ingredientLines: [String] = []
        var foundHeader = false

        // Enhanced headers in multiple languages (EN, CN, KR, JP)
        let headers = [
            // English
            "ingredients:", "ingredient list:", "composition:", "inci:",
            "contains:", "formula:",
            // Chinese Simplified & Traditional
            "成分:", "成分表:", "全成分:", "成份:", "配方:", "配方表:",
            "成分列表:", "原料:", "組成:", "全成份:",
            // Korean
            "성분:", "전성분:", "함유성분:",
            // Japanese
            "成分:", "全成分:", "配合成分:",
            // Alternative formats
            "ingredients list:", "full ingredients:"
        ]

        for line in lines {
            let lowercased = line.lowercased()

            // Check if this line contains a header
            let hasHeader = headers.contains { lowercased.contains($0) }

            if hasHeader {
                foundHeader = true
                // Extract content after header if on same line
                // Support both : and : (Chinese colon)
                if let colonIndex = line.firstIndex(of: ":") ?? line.firstIndex(of: ":") {
                    let afterColon = String(line[line.index(after: colonIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !afterColon.isEmpty {
                        ingredientLines.append(afterColon)
                    }
                }
                continue
            }

            // After finding header, collect all subsequent lines
            // Stop at common footer indicators
            if foundHeader {
                let footerIndicators = [
                    "net wt", "net weight", "净含量", "용량", "内容量",
                    "exp", "mfg", "batch", "lot",
                    "made in", "manufactured", "生产", "제조",
                    "©", "®", "™"
                ]

                let lineContainsFooter = footerIndicators.contains {
                    lowercased.contains($0)
                }

                if !lineContainsFooter {
                    ingredientLines.append(line)
                } else {
                    // Stop collecting after footer
                    break
                }
            }
        }

        // If no header found, try to parse all lines
        if !foundHeader {
            ingredientLines = lines
        }

        // Join and split by common separators with smarter parsing
        let fullText = ingredientLines.joined(separator: " ")
        return parseIngredientsAdvanced(from: fullText)
    }

    // MARK: - Advanced Ingredient Parsing

    private func parseIngredientsAdvanced(from text: String) -> [String] {
        // Find the ingredients section
        var ingredientText = text

        // Look for common headers
        let headers = ["ingredients:", "成分:", "成分表:", "全成分:", "成份:", "inci:"]
        for header in headers {
            if let range = text.range(of: header, options: .caseInsensitive) {
                ingredientText = String(text[range.upperBound...])
                break
            }
        }

        // Smart splitting that preserves parentheses content
        var ingredients: [String] = []
        var currentIngredient = ""
        var parenDepth = 0
        var bracketDepth = 0

        for char in ingredientText {
            switch char {
            case "(", "（":
                parenDepth += 1
                currentIngredient.append(char)
            case ")", "）":
                parenDepth = max(0, parenDepth - 1)
                currentIngredient.append(char)
            case "[":
                bracketDepth += 1
                currentIngredient.append(char)
            case "]":
                bracketDepth = max(0, bracketDepth - 1)
                currentIngredient.append(char)
            case ",", "，", "、", ";", "；":
                // Only split if not inside parentheses or brackets
                if parenDepth == 0, bracketDepth == 0 {
                    let trimmed = currentIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        ingredients.append(trimmed)
                    }
                    currentIngredient = ""
                } else {
                    currentIngredient.append(char)
                }
            case "/":
                // Handle "/" carefully - could be separator OR part of name
                // Only treat as separator if surrounded by spaces and not in parens
                if parenDepth == 0, bracketDepth == 0 {
                    let lastChar = currentIngredient.last
                    if lastChar == " " || lastChar == nil {
                        // Likely a separator
                        let trimmed = currentIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            ingredients.append(trimmed)
                        }
                        currentIngredient = ""
                    } else {
                        currentIngredient.append(char)
                    }
                } else {
                    currentIngredient.append(char)
                }
            default:
                currentIngredient.append(char)
            }
        }

        // Add the last ingredient
        let trimmed = currentIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            ingredients.append(trimmed)
        }

        // Post-process each ingredient
        return ingredients
            .map { cleanIngredient($0) }
            .filter { isValidIngredient($0) }
            .map { normalizer.normalize($0) }
    }

    // MARK: - Clean Individual Ingredient

    private func cleanIngredient(_ ingredient: String) -> String {
        var cleaned = ingredient

        // Remove leading/trailing punctuation
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: ".,;、，。；:：-–—"))

        // Remove standalone concentration indicators at the end (e.g., "5%", "0.5%")
        // But preserve them if they're part of a longer phrase
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+\\d+(\\.\\d+)?%$",
            with: "",
            options: .regularExpression
        )

        // Remove common OCR artifacts
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Remove bullet points and list markers
        let bulletPoints = ["•", "·", "◦", "▪", "▫", "■", "□", "○", "●"]
        for bullet in bulletPoints {
            cleaned = cleaned.replacingOccurrences(of: "^\(bullet)\\s*", with: "", options: .regularExpression)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Validate Ingredient

    private func isValidIngredient(_ ingredient: String) -> Bool {
        let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

        // Minimum length check
        guard trimmed.count >= 2 else { return false }

        // Filter out common non-ingredient text
        let invalidPatterns = [
            "^\\d+$", // Pure numbers
            "^[^a-zA-Z\\u4e00-\\u9fa5\\uac00-\\ud7af\\u3040-\\u309f\\u30a0-\\u30ff]+$", // No letters (any language)
            "^(and|or|the|of|with)$", // Common connecting words alone
        ]

        for pattern in invalidPatterns {
            if let _ = trimmed.range(of: pattern, options: .regularExpression) {
                return false
            }
        }

        // Filter out obvious non-ingredients (manufacturing info, etc.)
        let nonIngredientKeywords = [
            "made in", "manufactured", "batch", "lot", "exp", "mfg",
            "net wt", "net weight", "volume", "size",
            "for external use", "shake well", "keep out of reach",
            "生产", "制造", "批号", "净含量", "保质期"
        ]

        let lowercased = trimmed.lowercased()
        for keyword in nonIngredientKeywords {
            if lowercased.contains(keyword) {
                return false
            }
        }

        return true
    }
}

// MARK: - OCR Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case lowConfidence(Float)
    case visionError(Error)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "图片无效"
        case .noTextFound:
            "未识别到文字，请确保：\n• 图片清晰且光线充足\n• 成分表文字完整可见\n• 避免反光和阴影"
        case let .lowConfidence(confidence):
            "识别置信度较低 (\(Int(confidence * 100))%)，请尝试：\n• 重新拍摄更清晰的照片\n• 确保成分表文字对焦清晰\n• 或点击手动输入"
        case let .visionError(error):
            "OCR引擎错误: \(error.localizedDescription)"
        case .parseError:
            "解析成分失败，请尝试手动输入"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noTextFound, .lowConfidence:
            "您可以选择手动输入成分表或重新拍摄"
        case .invalidImage:
            "请选择其他图片"
        case .visionError:
            "请重试或联系技术支持"
        case .parseError:
            "请使用手动输入功能"
        }
    }
}

// MARK: - UIImage Orientation Extension

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Ingredient Normalizer

struct IngredientNormalizer {
    /// Comprehensive ingredient aliases mapping (multi-language)
    private let aliasMap: [String: String] = [
        // ===== WATER & SOLVENTS =====
        "水": "Water",
        "纯净水": "Water",
        "去离子水": "Water",
        "蒸馏水": "Water",
        "aqua": "Water",
        "purified water": "Water",
        "deionized water": "Water",
        "정제수": "Water",
        "精製水": "Water",

        // ===== HUMECTANTS & MOISTURIZERS =====
        "甘油": "Glycerin",
        "丙三醇": "Glycerin",
        "glycerol": "Glycerin",
        "글리세린": "Glycerin",
        "グリセリン": "Glycerin",

        "透明质酸": "Hyaluronic Acid",
        "玻尿酸": "Hyaluronic Acid",
        "히알루론산": "Hyaluronic Acid",
        "ヒアルロン酸": "Hyaluronic Acid",
        "透明质酸钠": "Sodium Hyaluronate",
        "玻尿酸钠": "Sodium Hyaluronate",
        "sodium hyaluronate": "Sodium Hyaluronate",

        "丁二醇": "Butylene Glycol",
        "butylene glycol": "Butylene Glycol",
        "1,3-butylene glycol": "Butylene Glycol",

        "丙二醇": "Propylene Glycol",
        "propylene glycol": "Propylene Glycol",

        "山梨糖醇": "Sorbitol",
        "山梨醇": "Sorbitol",

        "泛醇": "Panthenol",
        "维生素b5": "Panthenol",
        "d-panthenol": "Panthenol",
        "provitamin b5": "Panthenol",

        // ===== ACTIVE INGREDIENTS =====
        // Niacinamide
        "烟酰胺": "Niacinamide",
        "维生素b3": "Niacinamide",
        "烟碱酰胺": "Niacinamide",
        "nicotinamide": "Niacinamide",
        "나이아신아마이드": "Niacinamide",
        "ナイアシンアミド": "Niacinamide",

        // Retinoids
        "视黄醇": "Retinol",
        "维a醇": "Retinol",
        "a醇": "Retinol",
        "레티놀": "Retinol",
        "レチノール": "Retinol",
        "视黄醛": "Retinal",
        "a醛": "Retinal",
        "视黄酯": "Retinyl Palmitate",
        "棕榈酸视黄酯": "Retinyl Palmitate",

        // Vitamin C
        "抗坏血酸": "Ascorbic Acid",
        "维生素c": "Ascorbic Acid",
        "维c": "Ascorbic Acid",
        "l-抗坏血酸": "Ascorbic Acid",
        "아스코르브산": "Ascorbic Acid",
        "アスコルビン酸": "Ascorbic Acid",
        "抗坏血酸葡糖苷": "Ascorbyl Glucoside",
        "vc衍生物": "Ascorbyl Glucoside",
        "抗坏血酸棕榈酸酯": "Ascorbyl Palmitate",
        "3-o-乙基抗坏血酸": "Ethyl Ascorbic Acid",

        // AHAs
        "水杨酸": "Salicylic Acid",
        "살리실산": "Salicylic Acid",
        "サリチル酸": "Salicylic Acid",
        "乙醇酸": "Glycolic Acid",
        "羟基乙酸": "Glycolic Acid",
        "글리콜산": "Glycolic Acid",
        "乳酸": "Lactic Acid",
        "젖산": "Lactic Acid",
        "杏仁酸": "Mandelic Acid",

        // Peptides
        "棕榈酰五肽": "Palmitoyl Pentapeptide",
        "棕榈酰五肽-4": "Palmitoyl Pentapeptide-4",
        "六胜肽": "Acetyl Hexapeptide",
        "乙酰基六肽-8": "Acetyl Hexapeptide-8",
        "铜肽": "Copper Peptide",
        "三肽": "Tripeptide",

        // ===== ANTIOXIDANTS =====
        "生育酚": "Tocopherol",
        "维生素e": "Tocopherol",
        "ve": "Tocopherol",
        "α-生育酚": "Tocopherol",

        "辅酶q10": "Ubiquinone",
        "泛醌": "Ubiquinone",
        "coenzyme q10": "Ubiquinone",
        "coq10": "Ubiquinone",

        "熊果苷": "Arbutin",
        "α-熊果苷": "Alpha Arbutin",
        "beta-arbutin": "Arbutin",

        "曲酸": "Kojic Acid",

        "阿魏酸": "Ferulic Acid",

        "白藜芦醇": "Resveratrol",

        // ===== EMOLLIENTS & OILS =====
        "角鲨烷": "Squalane",
        "角鲨烯": "Squalene",
        "스쿠알란": "Squalane",

        "霍霍巴油": "Jojoba Oil",
        "荷荷巴油": "Jojoba Oil",
        "jojoba seed oil": "Jojoba Oil",

        "乳木果油": "Shea Butter",
        "牛油果树果脂": "Shea Butter",
        "시어버터": "Shea Butter",

        "鲸蜡硬脂醇": "Cetearyl Alcohol",
        "十六十八醇": "Cetearyl Alcohol",

        "神经酰胺": "Ceramide",
        "神经酰胺3": "Ceramide 3",
        "세라마이드": "Ceramide",
        "セラミド": "Ceramide",

        // ===== PRESERVATIVES =====
        "苯氧乙醇": "Phenoxyethanol",
        "페녹시에탄올": "Phenoxyethanol",

        "羟苯甲酯": "Methylparaben",
        "尼泊金甲酯": "Methylparaben",

        "羟苯丙酯": "Propylparaben",
        "尼泊金丙酯": "Propylparaben",

        "苯甲酸钠": "Sodium Benzoate",

        "山梨酸钾": "Potassium Sorbate",

        "edta二钠": "Disodium EDTA",
        "乙二胺四乙酸二钠": "Disodium EDTA",

        // ===== UV FILTERS =====
        "二氧化钛": "Titanium Dioxide",
        "티타늄디옥사이드": "Titanium Dioxide",

        "氧化锌": "Zinc Oxide",
        "징크옥사이드": "Zinc Oxide",

        "阿伏苯宗": "Avobenzone",
        "甲氧基肉桂酸辛酯": "Octinoxate",
        "奥克立林": "Octocrylene",

        // ===== SURFACTANTS & EMULSIFIERS =====
        "聚山梨醇酯20": "Polysorbate 20",
        "吐温20": "Polysorbate 20",

        "聚山梨醇酯80": "Polysorbate 80",
        "吐温80": "Polysorbate 80",

        "十二烷基硫酸钠": "Sodium Lauryl Sulfate",
        "sls": "Sodium Lauryl Sulfate",

        "月桂醇聚醚硫酸酯钠": "Sodium Laureth Sulfate",
        "sles": "Sodium Laureth Sulfate",

        // ===== PLANT EXTRACTS =====
        "芦荟": "Aloe Vera",
        "库拉索芦荟": "Aloe Barbadensis",
        "알로에베라": "Aloe Vera",

        "绿茶": "Green Tea",
        "绿茶提取物": "Green Tea Extract",
        "camellia sinensis": "Green Tea Extract",

        "洋甘菊": "Chamomile",
        "洋甘菊提取物": "Chamomile Extract",
        "카모마일": "Chamomile",

        "积雪草": "Centella Asiatica",
        "积雪草提取物": "Centella Asiatica Extract",
        "병풀": "Centella Asiatica",
        "センテラアジアチカ": "Centella Asiatica",

        "甘草": "Licorice",
        "甘草提取物": "Licorice Extract",
        "光果甘草": "Glabridin",
        "감초": "Licorice",

        // ===== OTHER COMMON =====
        "香精": "Fragrance",
        "香料": "Fragrance",
        "parfum": "Fragrance",
        "향료": "Fragrance",

        "酒精": "Alcohol",
        "乙醇": "Alcohol Denat.",
        "alcohol denat.": "Alcohol Denat.",
        "변성알코올": "Alcohol Denat.",

        "卡波姆": "Carbomer",
        "carbopol": "Carbomer",

        "黄原胶": "Xanthan Gum",
        "잔탄검": "Xanthan Gum",
    ]

    func normalize(_ ingredient: String) -> String {
        var cleaned = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 1: Extract and preserve INCI name if in parentheses
        var inciName: String?
        if let parenRange = cleaned.range(of: "\\([^)]+\\)", options: .regularExpression) {
            let inParens = String(cleaned[parenRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if what's in parens is likely an INCI name (Latin/English scientific name)
            if isLikelyINCI(inParens) {
                inciName = inParens
            }

            // Remove parentheses content for alias matching
            cleaned = cleaned.replacingOccurrences(
                of: "\\([^)]+\\)",
                with: "",
                options: .regularExpression
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Step 2: Remove concentration indicators
        cleaned = cleaned.replacingOccurrences(
            of: "\\s*\\d+(\\.\\d+)?%",
            with: "",
            options: .regularExpression
        )

        // Step 3: Normalize whitespace
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 4: Check alias map
        let lowercased = cleaned.lowercased()
        if let normalized = aliasMap[lowercased] {
            return normalized
        }

        // Step 5: If we have INCI name, prefer it
        if let inci = inciName {
            return capitalizeIngredient(inci)
        }

        // Step 6: Smart capitalization
        return capitalizeIngredient(cleaned)
    }

    /// Check if a string is likely an INCI name
    private func isLikelyINCI(_ text: String) -> Bool {
        // INCI names are typically:
        // - Latin plant names (e.g., "Aloe Barbadensis")
        // - Chemical names in English (e.g., "Sodium Hyaluronate")
        // - Mostly ASCII characters

        let latinPattern = "^[A-Za-z][a-z]+\\s+[A-Za-z][a-z]+$" // "Genus species"
        let chemicalPattern = "^[A-Z][a-z]+.*[A-Z][a-z]+.*$" // Capitalized words

        return text.range(of: latinPattern, options: .regularExpression) != nil ||
            text.range(of: chemicalPattern, options: .regularExpression) != nil
    }

    /// Smart capitalization for ingredient names
    private func capitalizeIngredient(_ ingredient: String) -> String {
        // Don't capitalize if already in proper INCI format
        if ingredient.contains(where: \.isUppercase) {
            return ingredient
        }

        // Capitalize first letter of each word
        let words = ingredient.components(separatedBy: " ")
        let capitalized = words.map { word -> String in
            guard !word.isEmpty else { return word }

            // Keep short words like "of", "and" lowercase unless first word
            let lowercaseWords = ["of", "and", "or", "the", "in", "with"]
            if lowercaseWords.contains(word.lowercased()), word != words.first {
                return word.lowercased()
            }

            return word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }

        return capitalized.joined(separator: " ")
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
            case .safe: "green"
            case .caution: "orange"
            case .warning: "red"
            }
        }
    }
}

// MARK: - Local Ingredient Database

final class IngredientDatabase: Sendable {
    static let shared = IngredientDatabase()

    /// Immutable after init - thread safe
    private let ingredients: [String: IngredientInfo]

    struct IngredientInfo: Codable, Sendable {
        let name: String
        let function: String
        let safetyRating: Int // 1-10, 10 safest
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
        var totalSafety = 0
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

            if isHighlight, let info {
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
        let safetyLevel: IngredientScanResult.SafetyLevel = switch avgSafety {
        case 8 ... 10: .safe
        case 5 ..< 8: .caution
        default: .warning
        }

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
