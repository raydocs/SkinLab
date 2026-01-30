// SkinLab/Features/Community/Models/SkinTwin.swift
import Foundation

/// 皮肤双胞胎匹配结果
struct SkinTwin: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    let userId: UUID // 双胞胎用户ID
    let similarity: Double // 相似度 0-1
    let matchLevel: MatchLevel // 匹配等级
    let anonymousProfile: AnonymousProfile // 匿名化资料
    var effectiveProducts: [EffectiveProduct] // 有效产品列表
    let matchedAt: Date // 匹配时间

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
struct EffectiveProduct: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    let product: Product // 产品信息
    let usageDuration: Int // 使用天数
    let improvementPercent: Double // 改善百分比 0-1
    let verifiedAt: Date // 验证时间

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
        case 0.7...: .veryEffective
        case 0.4 ..< 0.7: .effective
        case 0.1 ..< 0.4: .neutral
        default: .ineffective
        }
    }

    enum Effectiveness: String, Sendable {
        case veryEffective = "非常有效"
        case effective = "有效"
        case neutral = "一般"
        case ineffective = "无效"

        var icon: String {
            switch self {
            case .veryEffective: "checkmark.circle.fill"
            case .effective: "checkmark.circle"
            case .neutral: "minus.circle"
            case .ineffective: "xmark.circle"
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
