import CryptoKit
import Foundation

// MARK: - Ingredient AI Analyzer

actor IngredientAIAnalyzer {
    static let shared = IngredientAIAnalyzer()

    private let aiService: IngredientAIServiceProtocol
    private var cache: [String: CachedResult] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    private struct CachedResult {
        let result: IngredientAIResult
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600
        }
    }

    init(aiService: IngredientAIServiceProtocol? = nil) {
        self.aiService = aiService ?? GeminiService.shared
    }

    // MARK: - Analyze with AI

    func analyze(
        baseResult: IngredientScanResult,
        profile: UserProfile?,
        historyStore: UserHistoryStore?,
        preferences: [UserIngredientPreference]
    ) async throws -> IngredientAIResult {
        // Generate cache key
        let cacheKey = generateCacheKey(
            ingredients: baseResult.ingredients.map(\.normalizedName),
            profile: profile
        )

        // Check cache
        if let cached = cache[cacheKey], !cached.isExpired {
            return cached.result
        }

        // Build request
        let request = IngredientAIRequest(
            ingredients: baseResult.ingredients.map(\.normalizedName),
            profileSnapshot: ProfileSnapshot(profile: profile),
            historySnapshot: HistorySnapshot(historyStore: historyStore),
            preferences: preferences.map(\.ingredientName)
        )

        // Call AI service
        let result = try await aiService.analyzeIngredients(request: request)

        // Cache result
        cache[cacheKey] = CachedResult(result: result, timestamp: Date())

        return result
    }

    // MARK: - Analyze with Enhanced Result

    func analyzeWithEnhanced(
        baseResult: IngredientScanResult,
        enhancedResult: EnhancedIngredientScanResult,
        profile: UserProfile?,
        historyStore: UserHistoryStore?,
        preferences: [UserIngredientPreference]
    ) async -> EnhancedIngredientScanResultWithAI {
        do {
            let aiResult = try await analyze(
                baseResult: baseResult,
                profile: profile,
                historyStore: historyStore,
                preferences: preferences
            )

            return EnhancedIngredientScanResultWithAI(
                baseEnhanced: enhancedResult,
                aiResult: aiResult,
                aiStatus: .success,
                aiErrorMessage: nil
            )
        } catch {
            return EnhancedIngredientScanResultWithAI(
                baseEnhanced: enhancedResult,
                aiResult: nil,
                aiStatus: .failed,
                aiErrorMessage: error.localizedDescription
            )
        }
    }

    // MARK: - Cache Management

    private func generateCacheKey(ingredients: [String], profile: UserProfile?) -> String {
        // Build comprehensive cache key components
        var keyComponents: [String] = []

        // 1. Sorted ingredients
        keyComponents.append(ingredients.sorted().joined(separator: ","))

        // 2. User profile components that affect analysis
        if let profile {
            keyComponents.append(profile.skinType?.rawValue ?? "none")
            keyComponents.append(profile.concerns.map(\.rawValue).sorted().joined(separator: ","))
            keyComponents.append(profile.allergies.sorted().joined(separator: ","))
            keyComponents.append(profile.pregnancyStatus.rawValue)
            keyComponents.append(profile.fragranceTolerance.rawValue)
        }

        // Create stable hash using SHA-256
        let keyString = keyComponents.joined(separator: "|")
        let data = Data(keyString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func clearCache() {
        cache.removeAll()
    }

    func clearExpiredCache() {
        cache = cache.filter { !$0.value.isExpired }
    }
}
