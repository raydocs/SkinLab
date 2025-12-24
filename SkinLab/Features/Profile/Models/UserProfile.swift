import Foundation
import SwiftData

// MARK: - Age Range
enum AgeRange: String, Codable, CaseIterable, Sendable {
    case under20 = "under20"
    case age20to25 = "20-25"
    case age25to30 = "25-30"
    case age30to35 = "30-35"
    case age35to40 = "35-40"
    case over40 = "over40"
    
    var displayName: String {
        switch self {
        case .under20: return "20岁以下"
        case .age20to25: return "20-25岁"
        case .age25to30: return "25-30岁"
        case .age30to35: return "30-35岁"
        case .age35to40: return "35-40岁"
        case .over40: return "40岁以上"
        }
    }
    
    var normalized: Double {
        switch self {
        case .under20: return 0.1
        case .age20to25: return 0.25
        case .age25to30: return 0.4
        case .age30to35: return 0.55
        case .age35to40: return 0.7
        case .over40: return 0.85
        }
    }
}

// MARK: - Skin Concern
enum SkinConcern: String, Codable, CaseIterable, Sendable {
    case acne = "acne"
    case aging = "aging"
    case dryness = "dryness"
    case oiliness = "oiliness"
    case sensitivity = "sensitivity"
    case pigmentation = "pigmentation"
    case pores = "pores"
    case redness = "redness"
    
    var displayName: String {
        switch self {
        case .acne: return "痘痘"
        case .aging: return "抗老"
        case .dryness: return "干燥"
        case .oiliness: return "出油"
        case .sensitivity: return "敏感"
        case .pigmentation: return "色斑"
        case .pores: return "毛孔"
        case .redness: return "泛红"
        }
    }
    
    var icon: String {
        switch self {
        case .acne: return "circle.fill"
        case .aging: return "clock"
        case .dryness: return "drop.triangle"
        case .oiliness: return "drop.fill"
        case .sensitivity: return "exclamationmark.shield"
        case .pigmentation: return "circle.lefthalf.filled"
        case .pores: return "circle.grid.3x3"
        case .redness: return "flame"
        }
    }
}

// MARK: - Gender
enum Gender: String, Codable, Sendable {
    case male, female, other, preferNotToSay
    
    var displayName: String {
        switch self {
        case .male: return "男"
        case .female: return "女"
        case .other: return "其他"
        case .preferNotToSay: return "不愿透露"
        }
    }
}

// MARK: - Climate Type
enum ClimateType: String, Codable, CaseIterable, Sendable {
    case tropical = "热带"
    case subtropical = "亚热带"
    case temperate = "温带"
    case cold = "寒带"
    case dry = "干燥"
    
    var displayName: String { rawValue }
}

// MARK: - UV Exposure Level
enum UVExposureLevel: String, Codable, CaseIterable, Sendable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case veryHigh = "极高"
    
    var displayName: String { rawValue }
    
    var normalized: Double {
        switch self {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .veryHigh: return 1.0
        }
    }
}

// MARK: - Pregnancy Status
enum PregnancyStatus: String, Codable, CaseIterable, Sendable {
    case notPregnant = "未怀孕"
    case pregnant = "怀孕中"
    case breastfeeding = "哺乳期"
    
    var displayName: String { rawValue }
    
    /// 怀孕或哺乳期需要特别注意成分安全
    var requiresSpecialCare: Bool {
        self != .notPregnant
    }
}

// MARK: - Texture Preference
enum TexturePreference: String, Codable, CaseIterable, Sendable {
    case lightweight = "轻薄"
    case medium = "适中"
    case rich = "滋润"
    case anyTexture = "无偏好"
    
    var displayName: String { rawValue }
}

// MARK: - Fragrance Tolerance
enum FragranceTolerance: String, Codable, CaseIterable, Sendable {
    case love = "喜欢香味"
    case neutral = "可以接受"
    case sensitive = "敏感"
    case avoid = "完全避免"
    
    var displayName: String { rawValue }
    
    var normalized: Double {
        switch self {
        case .love: return 1.0
        case .neutral: return 0.5
        case .sensitive: return 0.25
        case .avoid: return 0.0
        }
    }
}

// MARK: - Budget Level
enum BudgetLevel: String, Codable, CaseIterable, Sendable {
    case economy = "经济型"
    case moderate = "中档"
    case premium = "高端"
    case luxury = "奢侈"
    case noBudget = "无预算限制"
    
    var displayName: String { rawValue }
    
    var maxPricePerProduct: Int? {
        switch self {
        case .economy: return 100
        case .moderate: return 300
        case .premium: return 800
        case .luxury: return 2000
        case .noBudget: return nil
        }
    }
}

// MARK: - Routine Preferences
struct RoutinePreferences: Codable, Sendable {
    var maxAMSteps: Int
    var maxPMSteps: Int
    var preferVegan: Bool
    var preferCrueltyFree: Bool
    var avoidAlcohol: Bool
    var avoidFragrance: Bool
    var avoidEssentialOils: Bool
    var preferNatural: Bool
    
    static let `default` = RoutinePreferences(
        maxAMSteps: 5,
        maxPMSteps: 7,
        preferVegan: false,
        preferCrueltyFree: false,
        avoidAlcohol: false,
        avoidFragrance: false,
        avoidEssentialOils: false,
        preferNatural: false
    )
}

// MARK: - Skin Fingerprint
struct SkinFingerprint: Codable, Sendable {
    let skinType: SkinType
    let ageRange: AgeRange
    let concerns: [SkinConcern]
    let issueVector: [Double]
    let fragranceTolerance: FragranceTolerance
    let uvExposure: UVExposureLevel
    let irritationHistory: Double // 0-1，基于历史分析的平均刺激水平
    let budgetLevel: BudgetLevel
    
    var vector: [Double] {
        var v: [Double] = []
        
        // One-hot encode skin type
        for type in SkinType.allCases {
            v.append(type == skinType ? 1.0 : 0.0)
        }
        
        // Normalized age
        v.append(ageRange.normalized)
        
        // Multi-hot encode concerns
        for concern in SkinConcern.allCases {
            v.append(concerns.contains(concern) ? 1.0 : 0.0)
        }
        
        // Issue vector (历史问题平均值)
        v.append(contentsOf: issueVector)
        
        // Fragrance tolerance
        v.append(fragranceTolerance.normalized)
        
        // UV exposure
        v.append(uvExposure.normalized)
        
        // Irritation history
        v.append(irritationHistory)
        
        // Budget level (normalized)
        let budgetNormalized: Double = {
            switch budgetLevel {
            case .economy: return 0.2
            case .moderate: return 0.4
            case .premium: return 0.6
            case .luxury: return 0.8
            case .noBudget: return 1.0
            }
        }()
        v.append(budgetNormalized)
        
        return v
    }
    
    /// 计算与另一个指纹的相似度 (0-1)
    func similarity(to other: SkinFingerprint) -> Double {
        let v1 = self.vector
        let v2 = other.vector
        
        guard v1.count == v2.count else { return 0 }
        
        // 计算余弦相似度
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let magnitude1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0, magnitude2 > 0 else { return 0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
}

// MARK: - User Profile (SwiftData)
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var skinTypeRaw: String?
    var ageRangeRaw: String
    var concernsRaw: [String]
    var allergies: [String]
    var gender: String?
    var region: String?
    
    // 新增个性化字段
    var climateRaw: String?
    var uvExposureRaw: String?
    var pregnancyStatusRaw: String
    var activePrescriptions: [String]
    var preferredTextureRaw: String?
    var fragranceToleranceRaw: String
    var budgetLevelRaw: String
    var routinePreferencesData: Data?
    
    // 指纹缓存
    var fingerprintData: Data?
    var fingerprintUpdatedAt: Date?
    
    // 社区匹配同意相关
    var consentLevelRaw: String = "none"     // 同意等级
    var consentUpdatedAt: Date?                // 同意更新时间
    var consentVersion: String?                // 同意协议版本
    var anonymousProfileData: Data?            // 缓存的匿名化资料
    var lastMatchedAt: Date?                   // 最后匹配时间
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    var skinType: SkinType? {
        get { skinTypeRaw.flatMap { SkinType(rawValue: $0) } }
        set {
            skinTypeRaw = newValue?.rawValue
            invalidateFingerprint()
        }
    }
    
    var ageRange: AgeRange {
        get { AgeRange(rawValue: ageRangeRaw) ?? .age25to30 }
        set {
            ageRangeRaw = newValue.rawValue
            invalidateFingerprint()
        }
    }
    
    var concerns: [SkinConcern] {
        get { concernsRaw.compactMap { SkinConcern(rawValue: $0) } }
        set {
            concernsRaw = newValue.map(\.rawValue)
            invalidateFingerprint()
        }
    }
    
    var climate: ClimateType? {
        get { climateRaw.flatMap { ClimateType(rawValue: $0) } }
        set { climateRaw = newValue?.rawValue }
    }
    
    var uvExposure: UVExposureLevel {
        get { uvExposureRaw.flatMap { UVExposureLevel(rawValue: $0) } ?? .medium }
        set {
            uvExposureRaw = newValue.rawValue
            invalidateFingerprint()
        }
    }
    
    var pregnancyStatus: PregnancyStatus {
        get { PregnancyStatus(rawValue: pregnancyStatusRaw) ?? .notPregnant }
        set { pregnancyStatusRaw = newValue.rawValue }
    }
    
    var preferredTexture: TexturePreference? {
        get { preferredTextureRaw.flatMap { TexturePreference(rawValue: $0) } }
        set { preferredTextureRaw = newValue?.rawValue }
    }
    
    var fragranceTolerance: FragranceTolerance {
        get { FragranceTolerance(rawValue: fragranceToleranceRaw) ?? .neutral }
        set {
            fragranceToleranceRaw = newValue.rawValue
            invalidateFingerprint()
        }
    }
    
    var budgetLevel: BudgetLevel {
        get { BudgetLevel(rawValue: budgetLevelRaw) ?? .moderate }
        set {
            budgetLevelRaw = newValue.rawValue
            invalidateFingerprint()
        }
    }
    
    var routinePreferences: RoutinePreferences {
        get {
            guard let data = routinePreferencesData,
                  let prefs = try? JSONDecoder().decode(RoutinePreferences.self, from: data) else {
                return .default
            }
            return prefs
        }
        set {
            routinePreferencesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Fingerprint Management
    
    /// 获取或构建指纹
    func getFingerprint(with historyStore: UserHistoryStore? = nil) -> SkinFingerprint? {
        // 检查缓存是否有效（24小时内）
        if let cachedData = fingerprintData,
           let updatedAt = fingerprintUpdatedAt,
           Date().timeIntervalSince(updatedAt) < 86400,
           let cached = try? JSONDecoder().decode(SkinFingerprint.self, from: cachedData) {
            return cached
        }
        
        // 重新构建指纹
        guard let skinType = self.skinType else { return nil }
        
        // 获取历史问题向量
        let issueVector: [Double]
        if let historyStore = historyStore,
           let baseline = historyStore.getBaseline() {
            issueVector = [
                Double(baseline.avgSpots) / 10.0,
                Double(baseline.avgAcne) / 10.0,
                Double(baseline.avgPores) / 10.0,
                Double(baseline.avgWrinkles) / 10.0,
                Double(baseline.avgRedness) / 10.0
            ]
        } else {
            issueVector = [0.5, 0.5, 0.5, 0.5, 0.5] // 默认中等水平
        }
        
        // 计算刺激历史
        let irritationHistory: Double
        if let historyStore = historyStore {
            let hasRedness = historyStore.hasSevereIssue(.redness)
            let hasAcne = historyStore.hasSevereIssue(.acne)
            irritationHistory = (hasRedness || hasAcne) ? 0.7 : 0.3
        } else {
            irritationHistory = 0.5
        }
        
        let fingerprint = SkinFingerprint(
            skinType: skinType,
            ageRange: ageRange,
            concerns: concerns,
            issueVector: issueVector,
            fragranceTolerance: fragranceTolerance,
            uvExposure: uvExposure,
            irritationHistory: irritationHistory,
            budgetLevel: budgetLevel
        )
        
        // 缓存指纹
        cacheFingerprint(fingerprint)
        
        return fingerprint
    }
    
    /// 缓存指纹
    private func cacheFingerprint(_ fingerprint: SkinFingerprint) {
        fingerprintData = try? JSONEncoder().encode(fingerprint)
        fingerprintUpdatedAt = Date()
    }
    
    /// 使指纹缓存失效
    private func invalidateFingerprint() {
        fingerprintData = nil
        fingerprintUpdatedAt = nil
    }
    
    // MARK: - Consent Management
    
    /// 同意等级计算属性
    var consentLevel: ConsentLevel {
        get { ConsentLevel(rawValue: consentLevelRaw) ?? .none }
        set {
            consentLevelRaw = newValue.rawValue
            updateConsentTimestamp()
        }
    }
    
    /// 更新同意等级
    /// - Parameter level: 新的同意等级
    func updateConsentLevel(_ level: ConsentLevel) {
        self.consentLevelRaw = level.rawValue
        self.consentUpdatedAt = Date()
        self.consentVersion = "v1.0"
        
        if level != .none {
            // 生成并缓存匿名资料
            self.anonymousProfileData = try? JSONEncoder().encode(toAnonymousProfile())
        } else {
            // 清空匿名资料
            self.anonymousProfileData = nil
        }
    }
    
    /// 更新同意时间戳
    private func updateConsentTimestamp() {
        self.consentUpdatedAt = Date()
        if consentLevel != .none {
            self.anonymousProfileData = try? JSONEncoder().encode(toAnonymousProfile())
        }
    }
    
    /// 记录匹配活动时间
    func recordMatchActivity() {
        self.lastMatchedAt = Date()
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        skinType: SkinType? = nil,
        ageRange: AgeRange = .age25to30,
        concerns: [SkinConcern] = [],
        allergies: [String] = [],
        gender: String? = nil,
        region: String? = nil,
        climate: ClimateType? = nil,
        uvExposure: UVExposureLevel = .medium,
        pregnancyStatus: PregnancyStatus = .notPregnant,
        activePrescriptions: [String] = [],
        preferredTexture: TexturePreference? = nil,
        fragranceTolerance: FragranceTolerance = .neutral,
        budgetLevel: BudgetLevel = .moderate,
        routinePreferences: RoutinePreferences = .default
    ) {
        self.id = id
        self.skinTypeRaw = skinType?.rawValue
        self.ageRangeRaw = ageRange.rawValue
        self.concernsRaw = concerns.map(\.rawValue)
        self.allergies = allergies
        self.gender = gender
        self.region = region
        
        self.climateRaw = climate?.rawValue
        self.uvExposureRaw = uvExposure.rawValue
        self.pregnancyStatusRaw = pregnancyStatus.rawValue
        self.activePrescriptions = activePrescriptions
        self.preferredTextureRaw = preferredTexture?.rawValue
        self.fragranceToleranceRaw = fragranceTolerance.rawValue
        self.budgetLevelRaw = budgetLevel.rawValue
        self.routinePreferencesData = try? JSONEncoder().encode(routinePreferences)
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
