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
              !checkIns.isEmpty else {
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
        // 基于用户感受评分计算改善百分比
        let feelings = checkIns.compactMap { $0.feeling }
        guard !feelings.isEmpty else { return 0.5 }
        
        let avgFeeling = Double(feelings.map { $0.score }.reduce(0, +)) / Double(feelings.count)
        // 将 feeling score (-1, 0, 1) 转换到 [0, 1] 范围
        return max(0, min(1, (avgFeeling + 1) / 2))
    }
}
