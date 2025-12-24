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
    var colorName: String {
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
