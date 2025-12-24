import Foundation
import SwiftData

// MARK: - User Ingredient Preference
/// 用户对特定成分的偏好设置
/// 支持手动标记和自动学习
@Model
final class UserIngredientPreference {
    @Attribute(.unique) var id: UUID
    var ingredientName: String
    
    /// 偏好分数：-100 (极度不喜欢) 到 100 (极度喜欢)
    var preferenceScore: Int
    
    /// 最后更新时间
    var lastUpdated: Date
    
    /// 偏好来源
    var source: PreferenceSource
    
    /// 用户备注
    var notes: String?
    
    /// 是否手动设置（手动设置优先级更高）
    var isManual: Bool {
        source == .manual
    }
    
    init(
        id: UUID = UUID(),
        ingredientName: String,
        preferenceScore: Int,
        lastUpdated: Date = Date(),
        source: PreferenceSource,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.preferenceScore = max(-100, min(100, preferenceScore))
        self.lastUpdated = lastUpdated
        self.source = source
        self.notes = notes
    }
    
    /// 更新偏好分数
    func updateScore(_ newScore: Int, source: PreferenceSource) {
        // 手动设置的偏好不会被自动学习覆盖
        guard !isManual || source == .manual else { return }
        
        self.preferenceScore = max(-100, min(100, newScore))
        self.source = source
        self.lastUpdated = Date()
    }
}

// MARK: - Preference Source
enum PreferenceSource: String, Codable, Sendable {
    case manual = "手动标记"
    case autoFromCheckIn = "从打卡自动学习"
    case autoFromAnalysis = "从分析自动学习"
    case imported = "导入"
    
    var priority: Int {
        switch self {
        case .manual: return 3
        case .imported: return 2
        case .autoFromCheckIn: return 1
        case .autoFromAnalysis: return 0
        }
    }
}

// MARK: - Preference Extensions
extension UserIngredientPreference {
    /// 偏好类型
    var preferenceType: PreferenceType {
        if preferenceScore > 30 {
            return .loved
        } else if preferenceScore > 0 {
            return .liked
        } else if preferenceScore < -30 {
            return .disliked
        } else if preferenceScore < 0 {
            return .avoided
        } else {
            return .neutral
        }
    }
    
    /// 偏好标签
    var label: String {
        preferenceType.label
    }
    
    /// 偏好颜色
    var color: String {
        preferenceType.color
    }
}

// MARK: - Preference Type
enum PreferenceType: String, Codable, Sendable {
    case loved = "喜爱"
    case liked = "喜欢"
    case neutral = "中性"
    case avoided = "避免"
    case disliked = "不喜欢"
    
    var label: String {
        rawValue
    }
    
    var color: String {
        switch self {
        case .loved: return "pink"
        case .liked: return "green"
        case .neutral: return "gray"
        case .avoided: return "orange"
        case .disliked: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .loved: return "heart.fill"
        case .liked: return "hand.thumbsup.fill"
        case .neutral: return "minus.circle"
        case .avoided: return "hand.raised.fill"
        case .disliked: return "hand.thumbsdown.fill"
        }
    }
}
