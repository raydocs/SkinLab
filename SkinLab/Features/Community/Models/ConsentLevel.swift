// SkinLab/Features/Community/Models/ConsentLevel.swift
import Foundation

/// 用户数据分享同意等级
enum ConsentLevel: String, Codable, CaseIterable, Sendable {
    case none = "完全私密" // 不参与匹配
    case anonymous = "匿名统计" // 参与匹配但完全匿名
    case pseudonymous = "社区分享" // 可展示匿名资料
    case `public` = "公开分享" // 可展示扩展信息 (仍不含照片)

    /// 等级说明文案
    var description: String {
        switch self {
        case .none:
            "您的数据不会被分享，也无法参与社区匹配"
        case .anonymous:
            "参与匹配算法，但您的资料完全匿名"
        case .pseudonymous:
            "可展示脱敏后的皮肤特征和有效产品"
        case .public:
            "公开分享护肤经验，帮助更多人 (不含照片和位置)"
        }
    }

    /// 等级详细说明
    var detailedDescription: String {
        switch self {
        case .none:
            "您的所有数据都只存储在本地，不会用于任何社区功能。您也无法查看其他用户的匹配结果。"
        case .anonymous:
            "您的数据会被用于改进匹配算法，但完全匿名处理，不会展示给其他用户。"
        case .pseudonymous:
            "其他用户可以看到您的脱敏资料 (肤质、年龄段、主要问题)，但不会知道您的身份。"
        case .public:
            "您愿意公开分享护肤经验，帮助社区成员。您的照片、姓名和精确位置仍然受到保护。"
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
