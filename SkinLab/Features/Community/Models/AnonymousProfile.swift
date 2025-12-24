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
    init(from profile: UserProfile, historyStore: UserHistoryStore? = nil) {
        self.skinType = profile.skinType ?? .combination
        self.ageRange = profile.ageRange
        self.mainConcerns = Array(profile.concerns.prefix(3))
        self.issueVector = Self.calculateIssueVector(from: profile, historyStore: historyStore)
        self.region = Self.extractCoarseRegion(from: profile.region)
    }
    
    /// 直接初始化（用于解码和测试）
    init(
        skinType: SkinType,
        ageRange: AgeRange,
        mainConcerns: [SkinConcern],
        issueVector: [Double],
        region: String?
    ) {
        self.skinType = skinType
        self.ageRange = ageRange
        self.mainConcerns = mainConcerns
        self.issueVector = issueVector
        self.region = region
    }
    
    /// 计算归一化问题向量
    private static func calculateIssueVector(from profile: UserProfile, historyStore: UserHistoryStore?) -> [Double] {
        // 从用户历史数据计算平均问题严重程度
        if let historyStore = historyStore,
           let baseline = historyStore.getBaseline() {
            return [
                Double(baseline.avgSpots) / 10.0,
                Double(baseline.avgAcne) / 10.0,
                Double(baseline.avgPores) / 10.0,
                Double(baseline.avgWrinkles) / 10.0,
                Double(baseline.avgRedness) / 10.0,
                0.5,  // evenness placeholder
                0.5   // texture placeholder
            ]
        }
        
        // 默认返回中等水平
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
    func toAnonymousProfile(historyStore: UserHistoryStore? = nil) -> AnonymousProfile {
        return AnonymousProfile(from: self, historyStore: historyStore)
    }
}
