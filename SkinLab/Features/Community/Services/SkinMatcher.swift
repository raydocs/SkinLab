// SkinLab/Features/Community/Services/SkinMatcher.swift
import Foundation

/// 皮肤匹配服务 - 核心算法实现
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
