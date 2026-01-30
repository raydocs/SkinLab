import Foundation

// MARK: - Conflict Severity

enum ConflictSeverity: String, Codable, Sendable {
    case warning = "警告" // 建议分开使用
    case danger = "危险" // 不建议同时使用

    var displayColor: String {
        switch self {
        case .warning: "orange"
        case .danger: "red"
        }
    }

    var icon: String {
        switch self {
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "xmark.octagon.fill"
        }
    }
}

// MARK: - Ingredient Conflict

struct IngredientConflict: Codable, Identifiable, Sendable {
    let id: UUID
    let ingredient1: String // normalized ingredient name
    let ingredient2: String
    let severity: ConflictSeverity
    let description: String // Chinese description
    let recommendation: String // Usage recommendation like "间隔12小时"

    init(
        id: UUID = UUID(),
        ingredient1: String,
        ingredient2: String,
        severity: ConflictSeverity,
        description: String,
        recommendation: String
    ) {
        self.id = id
        self.ingredient1 = ingredient1
        self.ingredient2 = ingredient2
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
    }
}

// MARK: - Conflict Knowledge Base

enum ConflictKnowledgeBase {
    /// Static knowledge base of known ingredient conflicts (at least 15 pairs)
    static let conflicts: [IngredientConflict] = [
        // Retinol conflicts (6 pairs)
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "aha",
            severity: .danger,
            description: "过度刺激，可能损伤皮肤屏障",
            recommendation: "建议分开早晚使用，或间隔24小时"
        ),
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "bha",
            severity: .danger,
            description: "刺激叠加，可能引起脱皮和干燥",
            recommendation: "建议分开早晚使用，或间隔24小时"
        ),
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "benzoyl peroxide",
            severity: .danger,
            description: "相互作用使两者失效",
            recommendation: "建议分开早晚使用，避免同时涂抹"
        ),
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "vitamin c",
            severity: .warning,
            description: "pH环境冲突，影响各自效果",
            recommendation: "建议早C晚A，分开使用效果更佳"
        ),
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "azelaic acid",
            severity: .warning,
            description: "刺激叠加，敏感肌需注意",
            recommendation: "建议先建立耐受再联用，或间隔使用"
        ),
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "salicylic acid",
            severity: .danger,
            description: "刺激叠加，可能引起严重干燥脱皮",
            recommendation: "避免同时使用，建议间隔24小时"
        ),
        IngredientConflict(
            ingredient1: "retinol",
            ingredient2: "lactic acid",
            severity: .danger,
            description: "过度刺激，屏障易受损",
            recommendation: "避免同时使用，建议间隔24小时"
        ),

        // Vitamin C conflicts (3 pairs)
        IngredientConflict(
            ingredient1: "vitamin c",
            ingredient2: "niacinamide",
            severity: .warning,
            description: "高浓度时可能产生冲突",
            recommendation: "低浓度可以同用，高浓度建议间隔15-30分钟"
        ),
        IngredientConflict(
            ingredient1: "aha",
            ingredient2: "vitamin c",
            severity: .warning,
            description: "刺激叠加，可能引起不适",
            recommendation: "建议分开使用，间隔12小时"
        ),
        IngredientConflict(
            ingredient1: "benzoyl peroxide",
            ingredient2: "vitamin c",
            severity: .danger,
            description: "过氧化苯甲酰会氧化VC使其失效",
            recommendation: "避免同时使用，分开早晚更佳"
        ),
        IngredientConflict(
            ingredient1: "glycolic acid",
            ingredient2: "vitamin c",
            severity: .warning,
            description: "pH冲突，影响VC稳定性",
            recommendation: "建议分开使用，间隔12小时"
        ),

        // AHA/BHA conflicts (2 pairs)
        IngredientConflict(
            ingredient1: "aha",
            ingredient2: "bha",
            severity: .warning,
            description: "过度去角质，可能损伤屏障",
            recommendation: "新手避免同时使用，建议隔天交替"
        ),
        IngredientConflict(
            ingredient1: "niacinamide",
            ingredient2: "aha",
            severity: .warning,
            description: "酸性环境影响烟酰胺稳定性",
            recommendation: "建议间隔15-30分钟使用"
        ),

        // Other dangerous combinations (3 pairs)
        IngredientConflict(
            ingredient1: "hydroquinone",
            ingredient2: "benzoyl peroxide",
            severity: .danger,
            description: "可能导致皮肤染色",
            recommendation: "严禁同时使用"
        ),
        IngredientConflict(
            ingredient1: "benzoyl peroxide",
            ingredient2: "retinoid",
            severity: .danger,
            description: "相互作用使两者失效",
            recommendation: "建议分开早晚使用"
        ),
        IngredientConflict(
            ingredient1: "copper peptide",
            ingredient2: "vitamin c",
            severity: .warning,
            description: "铜离子会加速VC氧化",
            recommendation: "避免同时使用，建议间隔12小时"
        )
    ]
}

// MARK: - Enhanced Ingredient Scan Result

struct EnhancedIngredientScanResult {
    let baseResult: IngredientScanResult
    let groupedByFunction: [IngredientFunction: [IngredientScanResult.ParsedIngredient]]
    let personalizedWarnings: [String]
    let personalizedRecommendations: [String]
    let suitabilityScore: Int // 0-100
    let suitableForUser: Bool
    let allergyMatches: [String]
    let concernMatches: [SkinConcern: [String]]
    let userReactions: [String: IngredientUserReaction] // 新增：成分名 -> 用户反应
    let conflicts: [IngredientConflict] // 成分冲突检测结果

    var hasPersonalizedInfo: Bool {
        !personalizedWarnings.isEmpty || !personalizedRecommendations.isEmpty || !allergyMatches
            .isEmpty || !userReactions.isEmpty || !conflicts.isEmpty
    }

    /// Convenience computed properties for conflict summary
    var hasDangerConflicts: Bool {
        conflicts.contains { $0.severity == .danger }
    }

    var hasWarningConflicts: Bool {
        conflicts.contains { $0.severity == .warning }
    }

    var dangerConflicts: [IngredientConflict] {
        conflicts.filter { $0.severity == .danger }
    }

    var warningConflicts: [IngredientConflict] {
        conflicts.filter { $0.severity == .warning }
    }
}

// MARK: - User Reaction Summary

struct IngredientUserReaction {
    let ingredientName: String
    let totalUses: Int
    let betterCount: Int
    let worseCount: Int
    let effectivenessRating: EffectivenessRating
    let confidenceLevel: ConfidenceLevel

    var displaySummary: String {
        switch effectivenessRating {
        case .insufficient:
            "使用次数较少（\(totalUses)次）"
        case .positive:
            "你的反应：\(totalUses)次使用中\(betterCount)次变好 ✓"
        case .neutral:
            "你的反应：\(totalUses)次使用效果平平"
        case .negative:
            "你的反应：\(totalUses)次使用中\(worseCount)次变差 ⚠️"
        }
    }
}

// MARK: - Function Group

struct FunctionGroup: Identifiable {
    let id = UUID()
    let function: IngredientFunction
    let ingredients: [IngredientScanResult.ParsedIngredient]
    let description: String
    let icon: String

    var displayName: String {
        function.displayName
    }
}

// MARK: - Risk Analyzer

@MainActor
final class IngredientRiskAnalyzer {
    /// 增强版分析，整合历史数据
    func analyze(
        scanResult: IngredientScanResult,
        profile: UserProfile?,
        historyStore: UserHistoryStore? = nil,
        userPreferences: [UserIngredientPreference] = []
    ) -> EnhancedIngredientScanResult {
        // Group by function
        let grouped = groupByFunction(scanResult.ingredients)

        // Get user reactions from history
        let userReactions = getUserReactions(
            for: scanResult.ingredients,
            historyStore: historyStore
        )

        // Detect ingredient conflicts
        let conflicts = detectConflicts(ingredients: scanResult.ingredients)

        // Analyze for user with enhanced context
        let (warnings, recommendations, suitability, allergies, concerns) = analyzeForUser(
            ingredients: scanResult.ingredients,
            profile: profile,
            historyStore: historyStore,
            userReactions: userReactions,
            userPreferences: userPreferences
        )

        return EnhancedIngredientScanResult(
            baseResult: scanResult,
            groupedByFunction: grouped,
            personalizedWarnings: warnings,
            personalizedRecommendations: recommendations,
            suitabilityScore: suitability,
            suitableForUser: suitability >= 60,
            allergyMatches: allergies,
            concernMatches: concerns,
            userReactions: userReactions,
            conflicts: conflicts
        )
    }

    // MARK: - Detect Conflicts

    /// Detects ingredient conflicts by matching parsed ingredients against the knowledge base
    /// - Parameter ingredients: List of parsed ingredients from the scan
    /// - Returns: Array of detected conflicts between ingredient pairs
    private func detectConflicts(ingredients: [IngredientScanResult.ParsedIngredient]) -> [IngredientConflict] {
        var detectedConflicts: [IngredientConflict] = []

        // Build a set of normalized ingredient names (lowercased) for efficient lookup
        let normalizedNames = Set(ingredients.map { $0.normalizedName.lowercased() })

        // Also create a mapping for common ingredient aliases that might match conflict keywords
        // This handles cases like "Ascorbic Acid" matching "vitamin c" in conflicts
        let ingredientKeywords = buildIngredientKeywordMap(ingredients: ingredients)

        // Check each conflict in the knowledge base
        for conflict in ConflictKnowledgeBase.conflicts {
            let ing1 = conflict.ingredient1.lowercased()
            let ing2 = conflict.ingredient2.lowercased()

            // Check if both ingredients are present
            let hasIngredient1 = matchesIngredient(ing1, in: normalizedNames, keywords: ingredientKeywords)
            let hasIngredient2 = matchesIngredient(ing2, in: normalizedNames, keywords: ingredientKeywords)

            if hasIngredient1, hasIngredient2 {
                detectedConflicts.append(conflict)
            }
        }

        return detectedConflicts
    }

    /// Builds a keyword map from ingredients for flexible conflict matching
    /// Maps common terms to whether they're present in the ingredient list
    private func buildIngredientKeywordMap(ingredients: [IngredientScanResult.ParsedIngredient]) -> Set<String> {
        var keywords = Set<String>()

        for ingredient in ingredients {
            let name = ingredient.normalizedName.lowercased()

            // Add the full normalized name
            keywords.insert(name)

            // Add specific keyword mappings for common ingredients
            if name.contains("ascorbic") || name.contains("vitamin c") || name.contains("vc") {
                keywords.insert("vitamin c")
            }
            if name.contains("retinol") || name.contains("retinal") || name.contains("retinoid") || name
                .contains("retin") {
                keywords.insert("retinol")
                keywords.insert("retinoid")
            }
            if name.contains("salicylic") {
                keywords.insert("salicylic acid")
                keywords.insert("bha")
            }
            if name.contains("glycolic") || name.contains("lactic") || name.contains("mandelic") {
                keywords.insert("aha")
            }
            if name.contains("niacinamide") || name.contains("nicotinamide") {
                keywords.insert("niacinamide")
            }
            if name.contains("benzoyl peroxide") || name.contains("过氧化苯甲酰") {
                keywords.insert("benzoyl peroxide")
            }
            if name.contains("azelaic") {
                keywords.insert("azelaic acid")
            }
            if name.contains("hydroquinone") || name.contains("氢醌") {
                keywords.insert("hydroquinone")
            }
            if name.contains("copper peptide") || name.contains("铜肽") {
                keywords.insert("copper peptide")
            }
        }

        return keywords
    }

    /// Checks if a conflict ingredient matches any ingredient in the scanned list
    /// - Parameters:
    ///   - conflictIngredient: The ingredient name from the conflict knowledge base
    ///   - normalizedNames: Set of normalized ingredient names from the scan
    ///   - keywords: Additional keyword mappings for flexible matching
    /// - Returns: True if the ingredient is present in the scanned list
    private func matchesIngredient(
        _ conflictIngredient: String,
        in normalizedNames: Set<String>,
        keywords: Set<String>
    ) -> Bool {
        // Direct match in keywords (which includes mapped terms)
        if keywords.contains(conflictIngredient) {
            return true
        }

        // Check if any normalized name contains the conflict ingredient
        for name in normalizedNames {
            if name.contains(conflictIngredient) {
                return true
            }
        }

        return false
    }

    // MARK: - User Reactions

    private func getUserReactions(
        for ingredients: [IngredientScanResult.ParsedIngredient],
        historyStore: UserHistoryStore?
    ) -> [String: IngredientUserReaction] {
        guard let historyStore else { return [:] }

        var reactions: [String: IngredientUserReaction] = [:]

        for ingredient in ingredients {
            if let stats = historyStore.getIngredientStats(ingredientName: ingredient.normalizedName) {
                reactions[ingredient.name] = IngredientUserReaction(
                    ingredientName: ingredient.name,
                    totalUses: stats.totalUses,
                    betterCount: stats.betterCount,
                    worseCount: stats.worseCount,
                    effectivenessRating: stats.effectivenessRating,
                    confidenceLevel: stats.confidenceLevel
                )
            }
        }

        return reactions
    }

    // MARK: - Group by Function

    private func groupByFunction(_ ingredients: [IngredientScanResult.ParsedIngredient])
        -> [IngredientFunction: [IngredientScanResult.ParsedIngredient]] {
        var groups: [IngredientFunction: [IngredientScanResult.ParsedIngredient]] = [:]

        for ingredient in ingredients {
            if let function = ingredient.function {
                groups[function, default: []].append(ingredient)
            }
        }

        return groups
    }

    // MARK: - Enhanced Analysis for User

    private func analyzeForUser(
        ingredients: [IngredientScanResult.ParsedIngredient],
        profile: UserProfile?,
        historyStore: UserHistoryStore?,
        userReactions: [String: IngredientUserReaction],
        userPreferences: [UserIngredientPreference]
    )
        -> (
            warnings: [String],
            recommendations: [String],
            suitability: Int,
            allergies: [String],
            concerns: [SkinConcern: [String]]
        ) {
        var warnings: [String] = []
        var recommendations: [String] = []
        var suitability = 70 // Base score
        var allergyMatches: [String] = []
        var concernMatches: [SkinConcern: [String]] = [:]

        guard let profile else {
            return (warnings, recommendations, suitability, allergyMatches, concernMatches)
        }

        // 1. Check allergies (highest priority)
        for allergy in profile.allergies {
            let allergyLower = allergy.lowercased()
            for ingredient in ingredients {
                if ingredient.normalizedName.lowercased().contains(allergyLower) ||
                    ingredient.name.lowercased().contains(allergyLower) {
                    allergyMatches.append(ingredient.name)
                    warnings.append("⚠️ 含有过敏成分：\(ingredient.name)")
                    suitability -= 30
                }
            }
        }

        // 2. Check user historical reactions (very important!)
        for (ingredientName, reaction) in userReactions {
            if reaction.effectivenessRating == .negative {
                warnings.append("⚠️ \(ingredientName)：你曾\(reaction.totalUses)次使用中\(reaction.worseCount)次反应不佳")
                suitability -= 20
            } else if reaction.effectivenessRating == .positive, reaction.totalUses >= 3 {
                recommendations.append("✓ \(ingredientName)：你曾使用效果良好")
                suitability += 5
            }
        }

        // 3. Check manual preferences
        let preferenceMap = Dictionary(uniqueKeysWithValues: userPreferences
            .map { ($0.ingredientName.lowercased(), $0) })
        for ingredient in ingredients {
            if let pref = preferenceMap[ingredient.normalizedName.lowercased()] {
                if pref.preferenceScore < -30 {
                    warnings.append("💔 \(ingredient.name)：你标记为不喜欢")
                    suitability -= 15
                } else if pref.preferenceScore > 30 {
                    recommendations.append("❤️ \(ingredient.name)：你标记为喜欢")
                    suitability += 10
                }
            }
        }

        // 4. Pregnancy/breastfeeding safety
        if profile.pregnancyStatus.requiresSpecialCare {
            let riskyForPregnancy = ["retinol", "retinoid", "salicylic", "benzoyl", "hydroquinone"]
            for ingredient in ingredients {
                for risky in riskyForPregnancy {
                    if ingredient.normalizedName.lowercased().contains(risky) {
                        warnings.append("🤰 \(ingredient.name)：\(profile.pregnancyStatus.displayName)期间需避免")
                        suitability -= 25
                        break
                    }
                }
            }
        }

        // 5. Fragrance sensitivity (based on profile)
        if profile.fragranceTolerance == .avoid || profile.fragranceTolerance == .sensitive {
            let hasFragrance = ingredients.contains { ing in
                ing.normalizedName.lowercased().contains("fragrance") ||
                    ing.normalizedName.lowercased().contains("parfum") ||
                    ing.function == .fragrance
            }
            if hasFragrance {
                let severity = profile.fragranceTolerance == .avoid ? "必须" : "建议"
                warnings.append("🌸 含有香精成分，\(severity)避免")
                suitability -= profile.fragranceTolerance == .avoid ? 20 : 10
            }
        }

        // 6. Historical skin issues (adjust warnings based on past problems)
        if let historyStore {
            // If user has history of severe redness, warn about alcohol/fragrance more strongly
            if historyStore.hasSevereIssue(.redness, threshold: 7) {
                let irritants = ingredients.filter { ing in
                    ing.normalizedName.lowercased().contains("alcohol") ||
                        ing.normalizedName.lowercased().contains("fragrance") ||
                        ing.normalizedName.lowercased().contains("menthol")
                }
                if !irritants.isEmpty {
                    warnings.append("🔴 历史数据显示你容易泛红，需特别注意：\(irritants.map(\.name).joined(separator: "、"))")
                    suitability -= 15
                }
            }

            // If user has history of severe acne, warn about comedogenic ingredients
            if historyStore.hasSevereIssue(.acne, threshold: 7) {
                let comedogenic = ingredients.filter { ing in
                    ing.normalizedName.lowercased().contains("coconut oil") ||
                        ing.normalizedName.lowercased().contains("cocoa butter") ||
                        ing.normalizedName.lowercased().contains("isopropyl")
                }
                if !comedogenic.isEmpty {
                    warnings.append("💊 历史数据显示你易长痘，注意：\(comedogenic.map(\.name).joined(separator: "、"))")
                    suitability -= 10
                }
            }
        }

        // 7. Skin type compatibility
        if let skinType = profile.skinType {
            suitability += checkSkinTypeCompatibility(ingredients: ingredients, skinType: skinType, profile: profile)
        }

        // 8. Concern compatibility
        for concern in profile.concerns {
            let matches = checkConcernMatches(ingredients: ingredients, concern: concern)
            if !matches.isEmpty {
                concernMatches[concern] = matches
                recommendations.append("✓ 针对\(concern.displayName)：含有\(matches.joined(separator: "、"))")
                suitability += 5
            }
        }

        // 9. Age-specific recommendations
        if profile.ageRange == .under20 || profile.ageRange == .age20to25 {
            let antiAgingIngredients = ingredients.filter { $0.function == .antiAging }
            if antiAgingIngredients.count > 2 {
                recommendations.append("💡 年轻肌肤建议以保湿为主，过早使用抗老成分可能加重负担")
            }
        }

        // Ensure suitability is in valid range
        suitability = max(0, min(100, suitability))

        return (warnings, recommendations, suitability, allergyMatches, concernMatches)
    }

    // MARK: - Skin Type Compatibility

    private func checkSkinTypeCompatibility(
        ingredients: [IngredientScanResult.ParsedIngredient],
        skinType: SkinType,
        profile: UserProfile
    ) -> Int {
        var score = 0

        switch skinType {
        case .dry:
            // Good for dry skin
            let hydrating = ingredients.filter { $0.function == .moisturizing }
            score += hydrating.count * 5

            // Bad for dry skin
            let drying = ingredients.filter { $0.function == .exfoliating }
            if drying.count > 1 {
                score -= 10
            }

        case .oily:
            // Good for oily skin
            let exfoliating = ingredients.filter { $0.function == .exfoliating }
            score += exfoliating.count * 5

            // Bad for oily skin - heavy oils
            let heavyOils = ingredients.filter { ing in
                ing.normalizedName.contains("oil") && ing.function != .exfoliating
            }
            if heavyOils.count > 2 {
                score -= 10
            }

        case .combination:
            // Balance is key
            let hasHydration = ingredients.contains { $0.function == .moisturizing }
            let hasExfoliation = ingredients.contains { $0.function == .exfoliating }
            if hasHydration, hasExfoliation {
                score += 10
            }

        case .sensitive:
            // Fewer ingredients is better
            if ingredients.count < 15 {
                score += 10
            }

            // Avoid common irritants
            let hasFragrance = ingredients.contains { ing in
                ing.normalizedName.contains("fragrance") || ing.normalizedName.contains("parfum")
            }
            if hasFragrance, profile.fragranceTolerance != .love {
                score -= 15
            }

            // Avoid alcohol for sensitive skin
            let hasAlcohol = ingredients.contains { ing in
                ing.normalizedName.lowercased().contains("alcohol denat") ||
                    ing.normalizedName.lowercased().contains("sd alcohol")
            }
            if hasAlcohol {
                score -= 10
            }
        }

        return score
    }

    // MARK: - Concern Matches

    private func checkConcernMatches(
        ingredients: [IngredientScanResult.ParsedIngredient],
        concern: SkinConcern
    ) -> [String] {
        var matches: [String] = []

        switch concern {
        case .acne:
            let beneficial = ["salicylic", "niacinamide", "benzoyl", "tea tree", "zinc"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .pigmentation:
            let beneficial = ["vitamin c", "niacinamide", "kojic", "arbutin", "licorice", "alpha arbutin"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .aging:
            let beneficial = ["retinol", "peptide", "vitamin c", "hyaluronic", "adenosine"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .dryness:
            let beneficial = ["hyaluronic", "glycerin", "ceramide", "panthenol", "squalane"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .sensitivity:
            let beneficial = ["centella", "aloe", "chamomile", "bisabolol", "allantoin", "madecassoside"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .pores:
            let beneficial = ["niacinamide", "salicylic", "retinol", "bha"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .oiliness:
            let beneficial = ["niacinamide", "salicylic", "zinc", "clay", "kaolin"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }

        case .redness:
            let beneficial = ["centella", "azelaic", "niacinamide", "green tea", "bisabolol", "cica"]
            for ingredient in ingredients {
                for keyword in beneficial {
                    if ingredient.normalizedName.lowercased().contains(keyword) {
                        matches.append(ingredient.name)
                        break
                    }
                }
            }
        }

        return matches
    }

    // MARK: - Get Function Groups

    func getFunctionGroups(from ingredients: [IngredientScanResult.ParsedIngredient]) -> [FunctionGroup] {
        let grouped = groupByFunction(ingredients)

        return grouped.map { function, ingredients in
            FunctionGroup(
                function: function,
                ingredients: ingredients,
                description: function.description,
                icon: function.icon
            )
        }.sorted { $0.function.displayName < $1.function.displayName }
    }
}

// MARK: - IngredientFunction Extensions

extension IngredientFunction {
    var description: String {
        switch self {
        case .moisturizing: "提供水分和锁水功效"
        case .brightening: "淡化色斑，提亮肤色"
        case .antiAging: "减少细纹，紧致肌肤"
        case .acneFighting: "控痘祛痘，清洁毛孔"
        case .exfoliating: "去除老化角质"
        case .soothing: "舒缓敏感，减少刺激"
        case .sunProtection: "防护紫外线伤害"
        case .fragrance: "增加产品香味"
        case .preservative: "延长产品保质期"
        case .other: "其他功效成分"
        }
    }

    var icon: String {
        switch self {
        case .moisturizing: "drop.fill"
        case .brightening: "sun.max.fill"
        case .antiAging: "sparkles"
        case .acneFighting: "bubbles.and.sparkles.fill"
        case .exfoliating: "wind"
        case .soothing: "leaf.fill"
        case .sunProtection: "sun.min.fill"
        case .fragrance: "sparkle"
        case .preservative: "lock.fill"
        case .other: "circle.fill"
        }
    }
}
