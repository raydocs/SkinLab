// SkinLab/Features/Community/Models/UserFeedbackRecord.swift
import Foundation
import SwiftData

/// 用户反馈记录 (SwiftData持久化)
@Model
final class UserFeedbackRecord {
    @Attribute(.unique) var id: UUID
    var matchId: UUID // 关联的匹配记录ID
    var accuracyScore: Int // 匹配准确度评分 1-5
    var productFeedbackText: String? // 产品推荐反馈文本
    var isHelpful: Bool // 推荐是否有帮助
    var createdAt: Date // 创建时间

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
