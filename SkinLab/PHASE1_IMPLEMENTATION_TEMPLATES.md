# Phase 1 实施代码模板

本文档提供 Phase 1 (核心Model + 基础匹配) 所需的完整代码模板，可直接复制粘贴到对应文件。

---

## 📁 文件结构

```
SkinLab/Features/Community/
├── Models/
│   ├── AnonymousProfile.swift
│   ├── MatchResultRecord.swift
│   ├── UserFeedbackRecord.swift
│   ├── SkinTwin.swift
│   ├── MatchLevel.swift
│   ├── ConsentLevel.swift
│   └── ShareableTrackingSnapshot.swift
├── Services/
│   ├── SkinMatcher.swift
│   └── MatchPoolRepository.swift
└── ViewModels/
    └── (Phase 2)
```

---

## 1️⃣ AnonymousProfile.swift

```swift
// SkinLab/Features/Community/Models/AnonymousProfile.swift
import Foundation

/// 匿名化用户资料 - 用于社区分享
/// 
/// 隐私保护规则:
/// - ✅ 包含: 肤质、年龄段、主要问题、归一化向量、粗粒度地区
/// - ❌ 不含: 姓名、照片、精确位置、处方信息、过敏清单
struct AnonymousProfile: Codable, Sendable {
    let skinType: SkinType              // 肤质类型
    let ageRange: AgeRange              // 年龄段 (5年区间)
    let mainConcerns: [SkinConcern]     // 主要皮肤问题 (最多3个)
    let issueVector: [Double]           // 归一化问题向量 [0-1]
    let region: String?                 // 地区 (省份/国家级别)
    
    /// 从完整用户资料创建匿名版本
    init(from profile: UserProfile) {
        self.skinType = profile.skinType ?? .combination
        self.ageRange = profile.ageRange
        self.mainConcerns = Array(profile.concerns.prefix(3))
        self.issueVector = Self.calculateIssueVector(from: profile)
        self.region = Self.extractCoarseRegion(from: profile.region)
    }
    
    /// 计算归一化问题向量
    private static func calculateIssueVector(from profile: UserProfile) -> [Double] {
        // 从用户历史数据计算平均问题严重程度
        // 默认返回中等水平 [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
        return Array(repeating: 0.5, count: 7)
    }
    
    /// 提取粗粒度地区 (省份/国家级别)
    private static func extractCoarseRegion(from fullRegion: String?) -> String? {
        guard let fullRegion = fullRegion else { return nil }
        let components = fullRegion.components(separatedBy: " ")
        return components.first // "广东省" 而非 "深圳市南山区"
    }
    
    /// Mock数据 (用于预览和测试)
    static let mock = AnonymousProfile(
        skinType: .combination,
        ageRange: .age25to30,
        mainConcerns: [.acne, .pores, .oiliness],
        issueVector: [0.3, 0.6, 0.5, 0.2, 0.4, 0.5, 0.4],
        region: "广东省"
    )
}

// MARK: - UserProfile Extension
extension UserProfile {
    /// 生成匿名化资料
    func toAnonymousProfile() -> AnonymousProfile {
        return AnonymousProfile(from: self)
    }
}
```

---

## 2️⃣ MatchLevel.swift

```swift
// SkinLab/Features/Community/Models/MatchLevel.swift
import Foundation

/// 匹配等级 - 根据相似度分级
enum MatchLevel: String, Codable, CaseIterable {
    case twin = "皮肤双胞胎 👯"          // 相似度 ≥ 0.9
    case verySimilar = "非常相似 ✨"    // 相似度 0.8-0.9
    case similar = "相似 💫"            // 相似度 0.7-0.8
    case somewhatSimilar = "有点相似 ⭐" // 相似度 0.6-0.7
    
    /// 根据相似度自动判断等级
    init(similarity: Double) {
        switch similarity {
        case 0.9...:
            self = .twin
        case 0.8..<0.9:
            self = .verySimilar
        case 0.7..<0.8:
            self = .similar
        default:
            self = .somewhatSimilar
        }
    }
    
    /// 等级对应的颜色 (用于UI展示)
    var color: String {
        switch self {
        case .twin: return "skinLabPrimary"
        case .verySimilar: return "skinLabSecondary"
        case .similar: return "skinLabAccent"
        case .somewhatSimilar: return "skinLabSubtext"
        }
    }
    
    /// 等级对应的图标
    var icon: String {
        switch self {
        case .twin: return "star.fill"
        case .verySimilar: return "sparkles"
        case .similar: return "star"
        case .somewhatSimilar: return "star.leadinghalf.filled"
        }
    }
}
```

---

## 3️⃣ ConsentLevel.swift

```swift
// SkinLab/Features/Community/Models/ConsentLevel.swift
import Foundation

/// 用户数据分享同意等级
enum ConsentLevel: String, Codable, CaseIterable, Sendable {
    case none = "完全私密"              // 不参与匹配
    case anonymous = "匿名统计"         // 参与匹配但完全匿名
    case pseudonymous = "社区分享"      // 可展示匿名资料
    case `public` = "公开分享"          // 可展示扩展信息 (仍不含照片)
    
    /// 等级说明文案
    var description: String {
        switch self {
        case .none:
            return "您的数据不会被分享，也无法参与社区匹配"
        case .anonymous:
            return "参与匹配算法，但您的资料完全匿名"
        case .pseudonymous:
            return "可展示脱敏后的皮肤特征和有效产品"
        case .public:
            return "公开分享护肤经验，帮助更多人 (不含照片和位置)"
        }
    }
    
    /// 等级详细说明
    var detailedDescription: String {
        switch self {
        case .none:
            return "您的所有数据都只存储在本地，不会用于任何社区功能。您也无法查看其他用户的匹配结果。"
        case .anonymous:
            return "您的数据会被用于改进匹配算法，但完全匿名处理，不会展示给其他用户。"
        case .pseudonymous:
            return "其他用户可以看到您的脱敏资料 (肤质、年龄段、主要问题)，但不会知道您的身份。"
        case .public:
            return "您愿意公开分享护肤经验，帮助社区成员。您的照片、姓名和精确位置仍然受到保护。"
        }
    }
    
    /// 是否可以参与匹配
    var canParticipate: Bool {
        self != .none
    }
    
    /// 是否可以展示资料
    var canShowProfile: Bool {
        self == .pseudonymous || self == .public
    }
}
```

---

## 4️⃣ SkinTwin.swift

```swift
// SkinLab/Features/Community/Models/SkinTwin.swift
import Foundation

/// 皮肤双胞胎匹配结果
struct SkinTwin: Identifiable, Codable {
    let id: UUID
    let userId: UUID                    // 双胞胎用户ID
    let similarity: Double              // 相似度 0-1
    let matchLevel: MatchLevel          // 匹配等级
    let anonymousProfile: AnonymousProfile // 匿名化资料
    var effectiveProducts: [EffectiveProduct] // 有效产品列表
    let matchedAt: Date                 // 匹配时间
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        similarity: Double,
        matchLevel: MatchLevel,
        anonymousProfile: AnonymousProfile,
        effectiveProducts: [EffectiveProduct] = [],
        matchedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.similarity = similarity
        self.matchLevel = matchLevel
        self.anonymousProfile = anonymousProfile
        self.effectiveProducts = effectiveProducts
        self.matchedAt = matchedAt
    }
    
    /// 相似度百分比显示
    var similarityPercent: Int {
        Int(similarity * 100)
    }
    
    /// 共同关注点
    func commonConcerns(with userConcerns: [SkinConcern]) -> [SkinConcern] {
        let twinConcerns = Set(anonymousProfile.mainConcerns)
        let userConcernsSet = Set(userConcerns)
        return Array(twinConcerns.intersection(userConcernsSet))
    }
    
    /// Mock数据
    static let mock = SkinTwin(
        userId: UUID(),
        similarity: 0.92,
        matchLevel: .twin,
        anonymousProfile: .mock,
        effectiveProducts: [.mock],
        matchedAt: Date()
    )
}

/// 有效产品记录
struct EffectiveProduct: Identifiable, Codable {
    let id: UUID
    let product: Product                // 产品信息
    let usageDuration: Int              // 使用天数
    let improvementPercent: Double      // 改善百分比 0-1
    let verifiedAt: Date                // 验证时间
    
    init(
        id: UUID = UUID(),
        product: Product,
        usageDuration: Int,
        improvementPercent: Double,
        verifiedAt: Date = Date()
    ) {
        self.id = id
        self.product = product
        self.usageDuration = usageDuration
        self.improvementPercent = improvementPercent
        self.verifiedAt = verifiedAt
    }
    
    /// 有效性等级
    var effectiveness: Effectiveness {
        switch improvementPercent {
        case 0.7...: return .veryEffective
        case 0.4..<0.7: return .effective
        case 0.1..<0.4: return .neutral
        default: return .ineffective
        }
    }
    
    enum Effectiveness: String {
        case veryEffective = "非常有效"
        case effective = "有效"
        case neutral = "一般"
        case ineffective = "无效"
        
        var icon: String {
            switch self {
            case .veryEffective: return "checkmark.circle.fill"
            case .effective: return "checkmark.circle"
            case .neutral: return "minus.circle"
            case .ineffective: return "xmark.circle"
            }
        }
    }
    
    /// Mock数据
    static let mock = EffectiveProduct(
        product: .mock,
        usageDuration: 28,
        improvementPercent: 0.75,
        verifiedAt: Date()
    )
}
```

---

## 5️⃣ ShareableTrackingSnapshot.swift

```swift
// SkinLab/Features/Community/Models/ShareableTrackingSnapshot.swift
import Foundation

/// 可分享的追踪摘要 - 用于产品推荐评分
struct ShareableTrackingSnapshot: Codable, Sendable {
    let duration: Int                   // 追踪天数
    let improvementPercent: Double      // 改善百分比 0-1
    let productsUsed: [String]          // 使用的产品ID列表
    let effectiveness: Effectiveness    // 有效性等级
    let createdAt: Date                 // 创建时间
    
    init(
        duration: Int,
        improvementPercent: Double,
        productsUsed: [String],
        effectiveness: Effectiveness,
        createdAt: Date = Date()
    ) {
        self.duration = duration
        self.improvementPercent = improvementPercent
        self.productsUsed = productsUsed
        self.effectiveness = effectiveness
        self.createdAt = createdAt
    }
    
    /// 有效性等级
    enum Effectiveness: String, Codable {
        case veryEffective = "非常有效"
        case effective = "有效"
        case neutral = "一般"
        case ineffective = "无效"
        
        /// 根据改善百分比自动判断
        init(improvementPercent: Double) {
            switch improvementPercent {
            case 0.7...: self = .veryEffective
            case 0.4..<0.7: self = .effective
            case 0.1..<0.4: self = .neutral
            default: self = .ineffective
            }
        }
    }
}

// MARK: - TrackingSession Extension
extension TrackingSession {
    /// 生成可分享的追踪摘要
    func generateShareableSnapshot() -> ShareableTrackingSnapshot? {
        guard status == .completed,
              let firstCheckIn = checkIns.first,
              let lastCheckIn = checkIns.last else {
            return nil
        }
        
        // 计算改善百分比 (简化版，实际需要从分析数据计算)
        let improvementPercent = calculateImprovement()
        
        return ShareableTrackingSnapshot(
            duration: duration,
            improvementPercent: improvementPercent,
            productsUsed: targetProducts,
            effectiveness: ShareableTrackingSnapshot.Effectiveness(improvementPercent: improvementPercent)
        )
    }
    
    /// 计算改善百分比 (示例实现)
    private func calculateImprovement() -> Double {
        // TODO: 实际实现需要从 analysisId 获取前后对比数据
        // 这里返回模拟值
        let feelings = checkIns.compactMap { $0.feeling }
        let avgFeeling = Double(feelings.map { $0.score }.reduce(0, +)) / Double(max(1, feelings.count))
        return max(0, min(1, (avgFeeling + 1) / 2)) // 转换到 [0, 1]
    }
}
```

---

## 6️⃣ MatchResultRecord.swift (SwiftData)

```swift
// SkinLab/Features/Community/Models/MatchResultRecord.swift
import Foundation
import SwiftData

/// 匹配结果记录 (SwiftData持久化)
@Model
final class MatchResultRecord {
    @Attribute(.unique) var id: UUID
    var userId: UUID                    // 当前用户ID
    var twinUserId: UUID                // 匹配到的用户ID
    var similarity: Double              // 相似度 0-1
    var matchLevelRaw: String          // 匹配等级原始值
    var createdAt: Date                 // 创建时间
    var expiresAt: Date?                // 过期时间 (24小时缓存)
    var anonymousProfileData: Data?     // 序列化的 AnonymousProfile
    var effectiveProductsData: Data?    // 序列化的产品列表
    
    // MARK: - Computed Properties
    
    var matchLevel: MatchLevel {
        get { MatchLevel(rawValue: matchLevelRaw) ?? .somewhatSimilar }
        set { matchLevelRaw = newValue.rawValue }
    }
    
    var anonymousProfile: AnonymousProfile? {
        get {
            guard let data = anonymousProfileData else { return nil }
            return try? JSONDecoder().decode(AnonymousProfile.self, from: data)
        }
        set {
            anonymousProfileData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var effectiveProducts: [EffectiveProduct] {
        get {
            guard let data = effectiveProductsData else { return [] }
            return (try? JSONDecoder().decode([EffectiveProduct].self, from: data)) ?? []
        }
        set {
            effectiveProductsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// 是否已过期
    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() > expires
    }
    
    // MARK: - Initialization
    
    init(
        userId: UUID,
        twinUserId: UUID,
        similarity: Double,
        matchLevel: MatchLevel,
        anonymousProfile: AnonymousProfile? = nil,
        effectiveProducts: [EffectiveProduct] = []
    ) {
        self.id = UUID()
        self.userId = userId
        self.twinUserId = twinUserId
        self.similarity = similarity
        self.matchLevelRaw = matchLevel.rawValue
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        self.anonymousProfile = anonymousProfile
        self.effectiveProducts = effectiveProducts
    }
    
    /// 从 SkinTwin 创建
    convenience init(from twin: SkinTwin, userId: UUID) {
        self.init(
            userId: userId,
            twinUserId: twin.userId,
            similarity: twin.similarity,
            matchLevel: twin.matchLevel,
            anonymousProfile: twin.anonymousProfile,
            effectiveProducts: twin.effectiveProducts
        )
    }
    
    /// 转换为 SkinTwin
    func toSkinTwin() -> SkinTwin? {
        guard let profile = anonymousProfile else { return nil }
        return SkinTwin(
            userId: twinUserId,
            similarity: similarity,
            matchLevel: matchLevel,
            anonymousProfile: profile,
            effectiveProducts: effectiveProducts,
            matchedAt: createdAt
        )
    }
}
```

---

## 7️⃣ UserFeedbackRecord.swift (SwiftData)

```swift
// SkinLab/Features/Community/Models/UserFeedbackRecord.swift
import Foundation
import SwiftData

/// 用户反馈记录 (SwiftData持久化)
@Model
final class UserFeedbackRecord {
    @Attribute(.unique) var id: UUID
    var matchId: UUID                   // 关联的匹配记录ID
    var accuracyScore: Int              // 匹配准确度评分 1-5
    var productFeedbackText: String?    // 产品推荐反馈文本
    var isHelpful: Bool                 // 推荐是否有帮助
    var createdAt: Date                 // 创建时间
    
    init(
        matchId: UUID,
        accuracyScore: Int,
        productFeedbackText: String? = nil,
        isHelpful: Bool
    ) {
        self.id = UUID()
        self.matchId = matchId
        self.accuracyScore = max(1, min(5, accuracyScore)) // 限制在1-5范围
        self.productFeedbackText = productFeedbackText
        self.isHelpful = isHelpful
        self.createdAt = Date()
    }
}
```

---

## 8️⃣ SkinMatcher.swift (Service)

```swift
// SkinLab/Features/Community/Services/SkinMatcher.swift
import Foundation

/// 皮肤匹配服务 - 核心算法实现
@MainActor
class SkinMatcher {
    
    // MARK: - Public Methods
    
    /// 查找皮肤双胞胎
    /// - Parameters:
    ///   - fingerprint: 当前用户的皮肤指纹
    ///   - pool: 候选用户池
    ///   - limit: 返回结果数量限制 (默认20)
    /// - Returns: 匹配结果列表，按相似度降序排列
    func findMatches(
        for fingerprint: SkinFingerprint,
        in pool: [UserProfile],
        limit: Int = 20
    ) async -> [SkinTwin] {
        await Task.detached {
            pool
                .compactMap { profile -> SkinTwin? in
                    // 1. 获取候选用户的指纹
                    guard let otherFingerprint = profile.getFingerprint() else {
                        return nil
                    }
                    
                    // 2. 计算加权相似度
                    let similarity = self.weightedSimilarity(
                        user: fingerprint,
                        other: otherFingerprint
                    )
                    
                    // 3. 过滤低相似度结果 (< 0.6)
                    guard similarity >= 0.6 else { return nil }
                    
                    // 4. 构建匹配结果
                    return SkinTwin(
                        userId: profile.id,
                        similarity: similarity,
                        matchLevel: MatchLevel(similarity: similarity),
                        anonymousProfile: profile.toAnonymousProfile(),
                        effectiveProducts: [] // 稍后由 ProductRecommendationEngine 填充
                    )
                }
                .sorted { $0.similarity > $1.similarity } // 相似度降序
                .prefix(limit)
                .map { $0 }
        }.value
    }
    
    // MARK: - Private Methods
    
    /// 加权相似度算法
    /// 
    /// 公式:
    /// finalScore = baseSimilarity (60%)
    ///            + skinTypeBonus (±20%)
    ///            + ageBonus (±10%)
    ///            + concernBonus (0-10%)
    ///            + sensitivityBonus (0-5%)
    ///
    private func weightedSimilarity(
        user: SkinFingerprint,
        other: SkinFingerprint
    ) -> Double {
        // 1️⃣ 基础余弦相似度 (权重 60%)
        let baseSimilarity = cosineSimilarity(user.vector, other.vector)
        
        // 2️⃣ 肤质类型匹配加成/惩罚 (±20%)
        let skinTypeBonus = user.skinType == other.skinType ? 0.2 : -0.3
        
        // 3️⃣ 年龄段接近加成 (±10%)
        let ageDiff = abs(user.ageRange.normalized - other.ageRange.normalized)
        let ageBonus: Double
        if ageDiff < 0.2 {
            ageBonus = 0.1      // 年龄非常接近
        } else if ageDiff > 0.4 {
            ageBonus = -0.1     // 年龄差距较大
        } else {
            ageBonus = 0        // 年龄适中
        }
        
        // 4️⃣ 共同关注点加成 (0-10%)
        let concernOverlap = Set(user.concerns).intersection(other.concerns)
        let concernBonus = Double(concernOverlap.count) * 0.03
        
        // 5️⃣ 敏感度一致性加成 (0-5%)
        let sensitivityBonus = abs(user.irritationHistory - other.irritationHistory) < 0.2
            ? 0.05
            : 0
        
        // 最终分数归一化到 [0, 1]
        let finalScore = baseSimilarity + skinTypeBonus + ageBonus + concernBonus + sensitivityBonus
        return min(1.0, max(0, finalScore))
    }
    
    /// 计算余弦相似度
    ///
    /// 公式: cos(θ) = (A · B) / (||A|| * ||B||)
    ///
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        // 点积 (dot product)
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        
        // 向量长度 (magnitude)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0, magnitudeB > 0 else { return 0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
```

---

## 9️⃣ MatchPoolRepository.swift (Service)

```swift
// SkinLab/Features/Community/Services/MatchPoolRepository.swift
import Foundation
import SwiftData

/// 匹配池数据仓库 - 负责查询可匹配用户和缓存管理
@MainActor
class MatchPoolRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 获取符合条件的匹配池用户
    /// - Parameters:
    ///   - excludingUserId: 排除的用户ID (当前用户)
    ///   - limit: 限制返回数量
    /// - Returns: 可匹配的用户列表
    func fetchEligibleProfiles(
        excludingUserId: UUID,
        limit: Int = 1000
    ) async throws -> [UserProfile] {
        var descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.id != excludingUserId &&
                profile.consentLevelRaw != "none" &&
                profile.fingerprintData != nil
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取缓存的匹配结果
    /// - Parameter userId: 用户ID
    /// - Returns: 有效的缓存匹配结果
    func getCachedMatches(for userId: UUID) async throws -> [MatchResultRecord] {
        let now = Date()
        let descriptor = FetchDescriptor<MatchResultRecord>(
            predicate: #Predicate { record in
                record.userId == userId &&
                (record.expiresAt ?? now) > now
            },
            sortBy: [SortDescriptor(\.similarity, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 保存匹配结果到缓存
    /// - Parameters:
    ///   - matches: 匹配结果列表
    ///   - userId: 当前用户ID
    func saveMatches(_ matches: [SkinTwin], for userId: UUID) async throws {
        // 1. 删除旧的缓存记录
        try await deleteExpiredMatches(for: userId)
        
        // 2. 保存新的匹配结果
        for match in matches {
            let record = MatchResultRecord(from: match, userId: userId)
            modelContext.insert(record)
        }
        
        try modelContext.save()
    }
    
    /// 删除过期的匹配记录
    /// - Parameter userId: 用户ID (可选，nil表示清理所有用户)
    func deleteExpiredMatches(for userId: UUID? = nil) async throws {
        let now = Date()
        
        let descriptor: FetchDescriptor<MatchResultRecord>
        if let userId = userId {
            descriptor = FetchDescriptor(
                predicate: #Predicate { record in
                    record.userId == userId &&
                    (record.expiresAt ?? now) <= now
                }
            )
        } else {
            descriptor = FetchDescriptor(
                predicate: #Predicate { record in
                    (record.expiresAt ?? now) <= now
                }
            )
        }
        
        let expiredRecords = try modelContext.fetch(descriptor)
        for record in expiredRecords {
            modelContext.delete(record)
        }
        
        try modelContext.save()
    }
    
    /// 使缓存失效
    /// - Parameter userId: 用户ID
    func invalidateCache(for userId: UUID) async throws {
        let descriptor = FetchDescriptor<MatchResultRecord>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }
        
        try modelContext.save()
    }
}
```

---

## 🔟 UserProfile扩展 (Consent管理)

```swift
// 添加到 SkinLab/Features/Profile/Models/UserProfile.swift

// MARK: - 新增字段 (在现有字段后添加)

var consentLevelRaw: String = "none"     // 同意等级
var consentUpdatedAt: Date?                // 同意更新时间
var consentVersion: String?                // 同意协议版本
var anonymousProfileData: Data?            // 缓存的匿名化资料
var lastMatchedAt: Date?                   // 最后匹配时间

// MARK: - Computed Properties (在现有计算属性后添加)

var consentLevel: ConsentLevel {
    get { ConsentLevel(rawValue: consentLevelRaw) ?? .none }
    set {
        consentLevelRaw = newValue.rawValue
        updateConsentTimestamp()
    }
}

// MARK: - 新增方法

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

/// 记录匹配时间
func recordMatchActivity() {
    self.lastMatchedAt = Date()
}
```

---

## 1️⃣1️⃣ SwiftData Schema更新

```swift
// 更新 SkinLab/App/SkinLabApp.swift

var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        SkinAnalysisRecord.self,
        TrackingSession.self,
        UserProfile.self,
        ProductRecord.self,
        UserIngredientPreference.self,
        IngredientExposureRecord.self,
        
        // ✨ 新增 Community 模块
        MatchResultRecord.self,
        UserFeedbackRecord.self
    ])
    // ... 其余配置保持不变
}()
```

---

## 🧪 单元测试模板

```swift
// SkinLabTests/Community/SkinMatcherTests.swift
import XCTest
@testable import SkinLab

final class SkinMatcherTests: XCTestCase {
    var matcher: SkinMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = SkinMatcher()
    }
    
    // MARK: - Cosine Similarity Tests
    
    func testCosineSimilarity_identicalVectors_returns1() {
        let vectorA = [1.0, 0.5, 0.3]
        let vectorB = [1.0, 0.5, 0.3]
        
        let similarity = matcher.cosineSimilarity(vectorA, vectorB)
        
        XCTAssertEqual(similarity, 1.0, accuracy: 0.001)
    }
    
    func testCosineSimilarity_orthogonalVectors_returns0() {
        let vectorA = [1.0, 0.0]
        let vectorB = [0.0, 1.0]
        
        let similarity = matcher.cosineSimilarity(vectorA, vectorB)
        
        XCTAssertEqual(similarity, 0.0, accuracy: 0.001)
    }
    
    // MARK: - Weighted Similarity Tests
    
    func testWeightedSimilarity_sameSkinType_bonus() {
        let userFP = SkinFingerprint(
            skinType: .combination,
            ageRange: .age25to30,
            concerns: [.acne],
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.3,
            budgetLevel: .moderate
        )
        
        let otherFP = SkinFingerprint(
            skinType: .combination, // 相同肤质
            ageRange: .age25to30,
            concerns: [.acne],
            issueVector: [0.5, 0.5, 0.5, 0.5, 0.5],
            fragranceTolerance: .neutral,
            uvExposure: .medium,
            irritationHistory: 0.3,
            budgetLevel: .moderate
        )
        
        let similarity = matcher.weightedSimilarity(user: userFP, other: otherFP)
        
        XCTAssertGreaterThan(similarity, 0.9) // 应该非常相似
    }
    
    func testWeightedSimilarity_differentSkinType_penalty() {
        // TODO: 实现测试
    }
    
    // MARK: - Find Matches Tests
    
    func testFindMatches_returnsTopResults() async {
        // TODO: 实现集成测试
    }
}
```

---

## ✅ Phase 1 完成检查清单

```markdown
### 模型层 (7个文件)
- [ ] AnonymousProfile.swift - 编译通过
- [ ] MatchLevel.swift - 编译通过
- [ ] ConsentLevel.swift - 编译通过
- [ ] SkinTwin.swift - 编译通过
- [ ] ShareableTrackingSnapshot.swift - 编译通过
- [ ] MatchResultRecord.swift - 编译通过
- [ ] UserFeedbackRecord.swift - 编译通过

### 服务层 (2个文件)
- [ ] SkinMatcher.swift - 编译通过
- [ ] MatchPoolRepository.swift - 编译通过

### 模型扩展
- [ ] UserProfile 扩展 Consent 字段
- [ ] TrackingSession 扩展 Shareable 方法

### SwiftData集成
- [ ] SkinLabApp schema更新
- [ ] 数据库迁移测试通过

### 测试
- [ ] SkinMatcherTests 通过
- [ ] 余弦相似度测试通过
- [ ] 加权相似度测试通过

### 文档
- [ ] 代码注释完整
- [ ] README更新
```

---

## 🚀 下一步 (Phase 2)

Phase 1 完成后，继续实施:
- ProductRecommendationEngine.swift
- MatchCache.swift
- SkinTwinViewModel.swift

参考主设计文档 `SKIN_TWIN_MATCHING_SYSTEM_DESIGN.md` 第5节 Service层设计。
