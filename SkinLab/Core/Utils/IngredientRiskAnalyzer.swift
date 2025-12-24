import Foundation

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

    var hasPersonalizedInfo: Bool {
        !personalizedWarnings.isEmpty || !personalizedRecommendations.isEmpty || !allergyMatches.isEmpty || !userReactions.isEmpty
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
            return "使用次数较少（\(totalUses)次）"
        case .positive:
            return "你的反应：\(totalUses)次使用中\(betterCount)次变好 ✓"
        case .neutral:
            return "你的反应：\(totalUses)次使用效果平平"
        case .negative:
            return "你的反应：\(totalUses)次使用中\(worseCount)次变差 ⚠️"
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
            userReactions: userReactions
        )
    }

    // MARK: - User Reactions
    private func getUserReactions(
        for ingredients: [IngredientScanResult.ParsedIngredient],
        historyStore: UserHistoryStore?
    ) -> [String: IngredientUserReaction] {
        guard let historyStore = historyStore else { return [:] }

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
    private func groupByFunction(_ ingredients: [IngredientScanResult.ParsedIngredient]) -> [IngredientFunction: [IngredientScanResult.ParsedIngredient]] {
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
    ) -> (warnings: [String], recommendations: [String], suitability: Int, allergies: [String], concerns: [SkinConcern: [String]]) {
        var warnings: [String] = []
        var recommendations: [String] = []
        var suitability = 70 // Base score
        var allergyMatches: [String] = []
        var concernMatches: [SkinConcern: [String]] = [:]

        guard let profile = profile else {
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
            } else if reaction.effectivenessRating == .positive && reaction.totalUses >= 3 {
                recommendations.append("✓ \(ingredientName)：你曾使用效果良好")
                suitability += 5
            }
        }

        // 3. Check manual preferences
        let preferenceMap = Dictionary(uniqueKeysWithValues: userPreferences.map { ($0.ingredientName.lowercased(), $0) })
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
        if let historyStore = historyStore {
            // If user has history of severe redness, warn about alcohol/fragrance more strongly
            if historyStore.hasSevereIssue(.redness, threshold: 7) {
                let irritants = ingredients.filter { ing in
                    ing.normalizedName.lowercased().contains("alcohol") ||
                    ing.normalizedName.lowercased().contains("fragrance") ||
                    ing.normalizedName.lowercased().contains("menthol")
                }
                if !irritants.isEmpty {
                    warnings.append("🔴 历史数据显示你容易泛红，需特别注意：\(irritants.map { $0.name }.joined(separator: "、"))")
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
                    warnings.append("💊 历史数据显示你易长痘，注意：\(comedogenic.map { $0.name }.joined(separator: "、"))")
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
            if hasHydration && hasExfoliation {
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
            if hasFragrance && profile.fragranceTolerance != .love {
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
    private func checkConcernMatches(ingredients: [IngredientScanResult.ParsedIngredient], concern: SkinConcern) -> [String] {
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

        return grouped.map { (function, ingredients) in
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
        case .moisturizing: return "提供水分和锁水功效"
        case .brightening: return "淡化色斑，提亮肤色"
        case .antiAging: return "减少细纹，紧致肌肤"
        case .acneFighting: return "控痘祛痘，清洁毛孔"
        case .exfoliating: return "去除老化角质"
        case .soothing: return "舒缓敏感，减少刺激"
        case .sunProtection: return "防护紫外线伤害"
        case .fragrance: return "增加产品香味"
        case .preservative: return "延长产品保质期"
        case .other: return "其他功效成分"
        }
    }

    var icon: String {
        switch self {
        case .moisturizing: return "drop.fill"
        case .brightening: return "sun.max.fill"
        case .antiAging: return "sparkles"
        case .acneFighting: return "bubbles.and.sparkles.fill"
        case .exfoliating: return "wind"
        case .soothing: return "leaf.fill"
        case .sunProtection: return "sun.min.fill"
        case .fragrance: return "sparkle"
        case .preservative: return "lock.fill"
        case .other: return "circle.fill"
        }
    }
}
