import Foundation
import SwiftData

// MARK: - Ingredient Exposure Record

/// 追踪用户对特定成分的暴露和实际反应
/// 用于构建个性化的成分-效果映射
@Model
final class IngredientExposureRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var ingredientName: String
    var productId: String
    var productName: String

    /// 用户在使用该成分后的主观感受
    var feeling: FeelingType

    /// 关联的追踪会话ID
    var sessionId: UUID

    /// 关联的打卡ID
    var checkInId: UUID

    /// 使用该成分时的皮肤状态（可选）
    var skinConditionSnapshot: String?

    init(
        id: UUID = UUID(),
        date: Date,
        ingredientName: String,
        productId: String,
        productName: String,
        feeling: FeelingType,
        sessionId: UUID,
        checkInId: UUID,
        skinConditionSnapshot: String? = nil
    ) {
        self.id = id
        self.date = date
        self.ingredientName = ingredientName
        self.productId = productId
        self.productName = productName
        self.feeling = feeling
        self.sessionId = sessionId
        self.checkInId = checkInId
        self.skinConditionSnapshot = skinConditionSnapshot
    }
}

// MARK: - Feeling Type

enum FeelingType: String, Codable, Sendable {
    case better = "变好"
    case same = "相同"
    case worse = "变差"

    var score: Int {
        switch self {
        case .better: 1
        case .same: 0
        case .worse: -1
        }
    }

    var color: String {
        switch self {
        case .better: "green"
        case .same: "gray"
        case .worse: "red"
        }
    }
}

// MARK: - Ingredient Effect Statistics

/// 成分效果统计数据
struct IngredientEffectStats: Codable, Sendable {
    let ingredientName: String
    let totalUses: Int
    let betterCount: Int
    let sameCount: Int
    let worseCount: Int
    let lastUsedAt: Date

    /// 平均效果分数 (-1 到 1)
    var avgEffectiveness: Double {
        let totalScore = betterCount - worseCount
        return totalUses > 0 ? Double(totalScore) / Double(totalUses) : 0
    }

    /// 效果评级
    var effectivenessRating: EffectivenessRating {
        if totalUses < 2 {
            return .insufficient
        }

        if avgEffectiveness > 0.3 {
            return .positive
        } else if avgEffectiveness < -0.3 {
            return .negative
        } else {
            return .neutral
        }
    }

    /// 信心等级
    var confidenceLevel: ConfidenceLevel {
        if totalUses < 2 {
            .low
        } else if totalUses < 5 {
            .medium
        } else {
            .high
        }
    }

    /// 生成用户可读的摘要
    var summary: String {
        switch effectivenessRating {
        case .insufficient:
            "数据不足，需要更多使用记录"
        case .positive:
            "使用(totalUses)次，(betterCount)次变好 - 效果良好"
        case .negative:
            "使用(totalUses)次，(worseCount)次变差 - 可能不适合你"
        case .neutral:
            "使用(totalUses)次，效果平平"
        }
    }
}

// MARK: - Effectiveness Rating

enum EffectivenessRating: String, Codable, Sendable {
    case insufficient = "数据不足"
    case positive = "效果良好"
    case neutral = "效果一般"
    case negative = "可能不适合"
}

// MARK: - Confidence Level

enum ConfidenceLevel: String, Codable, Sendable {
    case low = "低"
    case medium = "中"
    case high = "高"
}
