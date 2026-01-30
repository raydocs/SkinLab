// SkinLab/Features/Community/Models/MatchResultRecord.swift
import Foundation
import SwiftData

/// 匹配结果记录 (SwiftData持久化)
@Model
final class MatchResultRecord {
    @Attribute(.unique) var id: UUID
    var userId: UUID // 当前用户ID
    var twinUserId: UUID // 匹配到的用户ID
    var similarity: Double // 相似度 0-1
    var matchLevelRaw: String // 匹配等级原始值
    var createdAt: Date // 创建时间
    var expiresAt: Date? // 过期时间 (24小时缓存)
    var anonymousProfileData: Data? // 序列化的 AnonymousProfile
    var effectiveProductsData: Data? // 序列化的产品列表

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
