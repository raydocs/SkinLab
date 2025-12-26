import Foundation

// MARK: - AI Request Models

struct IngredientAIRequest: Codable, Sendable {
    let ingredients: [String]
    let profileSnapshot: ProfileSnapshot?
    let historySnapshot: HistorySnapshot?
    let preferences: [String]
}

struct ProfileSnapshot: Codable, Sendable {
    let skinType: String?
    let concerns: [String]
    let allergies: [String]
    let pregnancyStatus: String?
    let fragranceTolerance: String?
    
    init(profile: UserProfile?) {
        guard let profile = profile else {
            self.skinType = nil
            self.concerns = []
            self.allergies = []
            self.pregnancyStatus = nil
            self.fragranceTolerance = nil
            return
        }
        
        self.skinType = profile.skinType?.rawValue
        self.concerns = profile.concerns.map { $0.rawValue }
        self.allergies = profile.allergies
        self.pregnancyStatus = profile.pregnancyStatus.rawValue
        self.fragranceTolerance = profile.fragranceTolerance.rawValue
    }
}

struct HistorySnapshot: Codable, Sendable {
    let severeIssues: [String]
    let ingredientStats: [String: IngredientEffectSummary]
    
    init(historyStore: UserHistoryStore?) {
        guard let store = historyStore else {
            self.severeIssues = []
            self.ingredientStats = [:]
            return
        }
        
        var issues: [String] = []
        let issueTypes: [(SkinIssueType, String)] = [
            (.acne, "acne"),
            (.redness, "redness"),
            (.spots, "spots"),
            (.pores, "pores")
        ]
        for (issue, name) in issueTypes {
            if store.hasSevereIssue(issue, threshold: 7) {
                issues.append(name)
            }
        }
        self.severeIssues = issues
        
        let allStats = store.getAllIngredientStats()
        self.ingredientStats = allStats.mapValues { stats in
            IngredientEffectSummary(
                totalUses: stats.totalUses,
                betterCount: stats.betterCount,
                worseCount: stats.worseCount
            )
        }
    }
}

struct IngredientEffectSummary: Codable, Sendable {
    let totalUses: Int
    let betterCount: Int
    let worseCount: Int
}

// MARK: - AI Response Models

// Risk level enum for type safety
enum RiskLevel: String, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "yellow"
        }
    }
}

struct IngredientAIResult: Codable, Sendable {
    let summary: String
    let riskTags: [String]
    let ingredientConcerns: [IngredientConcern]
    let compatibilityScore: Int
    let usageTips: [String]
    let avoidCombos: [String]
    let confidence: Int
    let evidence: [IngredientEvidence]
    let overallEvidenceLevel: EvidenceLevel?

    static let empty = IngredientAIResult(
        summary: "",
        riskTags: [],
        ingredientConcerns: [],
        compatibilityScore: 0,
        usageTips: [],
        avoidCombos: [],
        confidence: 0,
        evidence: [],
        overallEvidenceLevel: nil
    )

    // Custom decoding with validation and fallbacks
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields with fallbacks
        summary = (try? container.decode(String.self, forKey: .summary)) ?? ""
        riskTags = (try? container.decode([String].self, forKey: .riskTags)) ?? []
        ingredientConcerns = (try? container.decode([IngredientConcern].self, forKey: .ingredientConcerns)) ?? []
        usageTips = (try? container.decode([String].self, forKey: .usageTips)) ?? []
        avoidCombos = (try? container.decode([String].self, forKey: .avoidCombos)) ?? []

        // Scores with clamping
        let rawCompatibility = (try? container.decode(Int.self, forKey: .compatibilityScore)) ?? 50
        compatibilityScore = min(100, max(0, rawCompatibility))

        let rawConfidence = (try? container.decode(Int.self, forKey: .confidence)) ?? 0
        confidence = min(100, max(0, rawConfidence))
        
        // Evidence fields with fallbacks
        evidence = (try? container.decode([IngredientEvidence].self, forKey: .evidence)) ?? []
        overallEvidenceLevel = try? container.decode(EvidenceLevel.self, forKey: .overallEvidenceLevel)
    }

    init(summary: String, riskTags: [String], ingredientConcerns: [IngredientConcern],
         compatibilityScore: Int, usageTips: [String], avoidCombos: [String], confidence: Int,
         evidence: [IngredientEvidence] = [], overallEvidenceLevel: EvidenceLevel? = nil) {
        self.summary = summary
        self.riskTags = riskTags
        self.ingredientConcerns = ingredientConcerns
        self.compatibilityScore = min(100, max(0, compatibilityScore))
        self.usageTips = usageTips
        self.avoidCombos = avoidCombos
        self.confidence = min(100, max(0, confidence))
        self.evidence = evidence
        self.overallEvidenceLevel = overallEvidenceLevel
    }

    private enum CodingKeys: String, CodingKey {
        case summary, riskTags, ingredientConcerns, compatibilityScore, usageTips, avoidCombos, confidence, evidence, overallEvidenceLevel
    }
}

struct IngredientConcern: Codable, Sendable, Identifiable {
    var id: String { name }
    let name: String
    let reason: String
    let riskLevel: RiskLevel

    var riskColor: String {
        riskLevel.color
    }

    // Custom decoding with fallback for unknown risk levels
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        reason = try container.decode(String.self, forKey: .reason)

        // Try to decode risk level, fallback to low if invalid
        if let levelStr = try? container.decode(String.self, forKey: .riskLevel),
           let level = RiskLevel(rawValue: levelStr.lowercased()) {
            riskLevel = level
        } else {
            riskLevel = .low  // Safe default
        }
    }

    init(name: String, reason: String, riskLevel: RiskLevel) {
        self.name = name
        self.reason = reason
        self.riskLevel = riskLevel
    }

    private enum CodingKeys: String, CodingKey {
        case name, reason, riskLevel
    }
}

// MARK: - AI Status

enum AIAnalysisStatus: String, Sendable {
    case idle
    case analyzing
    case success
    case failed
}

// MARK: - Extended Enhanced Result

struct EnhancedIngredientScanResultWithAI {
    let baseEnhanced: EnhancedIngredientScanResult
    let aiResult: IngredientAIResult?
    let aiStatus: AIAnalysisStatus
    let aiErrorMessage: String?
    
    var hasAIInsights: Bool {
        aiResult != nil && aiStatus == .success
    }
    
    init(
        baseEnhanced: EnhancedIngredientScanResult,
        aiResult: IngredientAIResult? = nil,
        aiStatus: AIAnalysisStatus = .idle,
        aiErrorMessage: String? = nil
    ) {
        self.baseEnhanced = baseEnhanced
        self.aiResult = aiResult
        self.aiStatus = aiStatus
        self.aiErrorMessage = aiErrorMessage
    }
}

// MARK: - Evidence Models

enum EvidenceLevel: String, Codable, Sendable {
    case limited = "limited"
    case moderate = "moderate"
    case strong = "strong"
    
    var displayName: String {
        switch self {
        case .limited: return "有限证据"
        case .moderate: return "中等证据"
        case .strong: return "充分证据"
        }
    }
    
    var icon: String {
        switch self {
        case .limited: return "circle"
        case .moderate: return "circle.lefthalf.filled"
        case .strong: return "circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .limited: return "gray"
        case .moderate: return "orange"
        case .strong: return "green"
        }
    }
}

enum EvidenceSource: String, Codable, Sendable {
    case clinicalStudy = "clinical_study"
    case expertConsensus = "expert_consensus"
    case userFeedback = "user_feedback"
    case scientificReview = "scientific_review"
    
    var displayName: String {
        switch self {
        case .clinicalStudy: return "临床研究"
        case .expertConsensus: return "专家共识"
        case .userFeedback: return "用户反馈"
        case .scientificReview: return "科学文献"
        }
    }
    
    var icon: String {
        switch self {
        case .clinicalStudy: return "cross.case"
        case .expertConsensus: return "person.2"
        case .userFeedback: return "bubble.left.and.bubble.right"
        case .scientificReview: return "book"
        }
    }
}

struct IngredientEvidence: Codable, Sendable, Identifiable {
    var id: String { ingredientName }
    let ingredientName: String
    let level: EvidenceLevel
    let sources: [EvidenceSource]
    let studyCount: Int?
    let description: String?
    
    init(ingredientName: String, level: EvidenceLevel, sources: [EvidenceSource], studyCount: Int? = nil, description: String? = nil) {
        self.ingredientName = ingredientName
        self.level = level
        self.sources = sources
        self.studyCount = studyCount
        self.description = description
    }
}
