// SkinLab/Features/Community/Services/SkinMatcher.swift
import Foundation

// MARK: - Match Candidate (Sendable value type for concurrency safety)

/// Pre-extracted candidate data for concurrency-safe matching
/// This captures all necessary data from UserProfile before crossing concurrency boundaries
struct MatchCandidate: Sendable {
    let userId: UUID
    let fingerprint: SkinFingerprint
    let vector: [Double]
    let anonymousProfile: AnonymousProfile
}

// MARK: - SkinMatcher

/// 皮肤匹配服务 - 核心算法实现
///
/// 支持单条和批量处理模式:
/// - 单条处理: `findMatches(for:in:limit:)` - 接受 UserProfile 数组
/// - 批量处理: `findMatchesBatch(for:candidates:limit:)` - 接受预提取的 MatchCandidate 数组
///
/// **Concurrency Safety**: Batch methods accept `[MatchCandidate]` (Sendable) instead of
/// `[UserProfile]` (SwiftData model). Callers must extract candidates on the main actor
/// before calling batch methods.
class SkinMatcher {

    // MARK: - Configuration

    /// 批处理配置
    struct BatchConfig: Sendable {
        /// 每批最大处理数量
        let maxBatchSize: Int
        /// 最小相似度阈值
        let minSimilarity: Double
        /// 是否启用并行处理
        let enableParallelProcessing: Bool

        static let `default` = BatchConfig(
            maxBatchSize: 5,
            minSimilarity: 0.6,
            enableParallelProcessing: true
        )
    }

    private let config: BatchConfig

    // MARK: - Initialization

    init(config: BatchConfig = .default) {
        self.config = config
    }

    // MARK: - Candidate Extraction (call on main actor)

    /// Extract match candidates from UserProfile array
    /// - Parameter pool: Array of UserProfile (must be called on main actor for SwiftData safety)
    /// - Returns: Array of Sendable MatchCandidate for use in batch processing
    ///
    /// **Important**: Call this method on the main actor before passing to batch methods.
    static func extractCandidates(from pool: [UserProfile]) -> [MatchCandidate] {
        pool.compactMap { profile -> MatchCandidate? in
            guard let fingerprint = profile.getFingerprint() else { return nil }
            return MatchCandidate(
                userId: profile.id,
                fingerprint: fingerprint,
                vector: fingerprint.vector,  // Pre-compute vector once
                anonymousProfile: profile.toAnonymousProfile()
            )
        }
    }

    // MARK: - Public Methods (Single Processing)

    /// 查找皮肤双胞胎（单条处理）
    /// - Parameters:
    ///   - fingerprint: 当前用户的皮肤指纹
    ///   - pool: 候选用户池
    ///   - limit: 返回结果数量限制 (默认20)
    /// - Returns: 匹配结果列表，按相似度降序排列
    ///
    /// **Note**: For batch processing, use `findMatchesBatch(for:candidates:limit:)` with
    /// pre-extracted candidates for better performance and concurrency safety.
    func findMatches(
        for fingerprint: SkinFingerprint,
        in pool: [UserProfile],
        limit: Int = 20
    ) async -> [SkinTwin] {
        // Extract candidates synchronously (assumes caller is on main actor)
        let candidates = Self.extractCandidates(from: pool)
        return findMatchesFromCandidates(for: fingerprint, candidates: candidates, limit: limit)
    }

    /// 查找皮肤双胞胎（使用预提取的候选）
    /// - Parameters:
    ///   - fingerprint: 当前用户的皮肤指纹
    ///   - candidates: 预提取的候选列表
    ///   - limit: 返回结果数量限制 (默认20)
    /// - Returns: 匹配结果列表，按相似度降序排列
    func findMatchesFromCandidates(
        for fingerprint: SkinFingerprint,
        candidates: [MatchCandidate],
        limit: Int = 20
    ) -> [SkinTwin] {
        let userVector = fingerprint.vector  // Pre-compute once
        return computeMatches(
            userVector: userVector,
            userFingerprint: fingerprint,
            candidates: candidates,
            limit: limit
        )
    }

    // MARK: - Public Methods (Batch Processing)

    /// 批量查找皮肤双胞胎
    /// - Parameters:
    ///   - fingerprints: 多个用户的皮肤指纹
    ///   - candidates: 预提取的候选列表（一次提取，多次复用）
    ///   - limit: 每个指纹返回的结果数量限制 (默认20)
    /// - Returns: 每个指纹对应的匹配结果列表
    ///
    /// 批量处理优势:
    /// - 候选池只需预提取一次（调用前通过 `extractCandidates` 完成）
    /// - 候选向量预计算，避免重复计算
    /// - 并行计算多个指纹的匹配
    /// - 减少50%以上的重复计算
    func findMatchesBatch(
        for fingerprints: [SkinFingerprint],
        candidates: [MatchCandidate],
        limit: Int = 20
    ) async -> [[SkinTwin]] {
        guard !fingerprints.isEmpty else { return [] }
        guard !candidates.isEmpty else { return fingerprints.map { _ in [] } }

        // Pre-compute all user vectors once
        let userVectors = fingerprints.map { ($0, $0.vector) }

        if config.enableParallelProcessing {
            // Parallel processing via TaskGroup
            return await withTaskGroup(of: (Int, [SkinTwin]).self) { group in
                for (index, (fingerprint, userVector)) in userVectors.enumerated() {
                    group.addTask {
                        let matches = self.computeMatches(
                            userVector: userVector,
                            userFingerprint: fingerprint,
                            candidates: candidates,
                            limit: limit
                        )
                        return (index, matches)
                    }
                }

                var results: [(Int, [SkinTwin])] = []
                for await result in group {
                    results.append(result)
                }

                // Return in original order
                return results.sorted { $0.0 < $1.0 }.map { $0.1 }
            }
        } else {
            // Serial processing
            return userVectors.map { (fingerprint, userVector) in
                computeMatches(
                    userVector: userVector,
                    userFingerprint: fingerprint,
                    candidates: candidates,
                    limit: limit
                )
            }
        }
    }

    /// 批量查找皮肤双胞胎（从 UserProfile 数组，便捷方法）
    /// - Parameters:
    ///   - fingerprints: 多个用户的皮肤指纹
    ///   - pool: 候选用户池
    ///   - limit: 每个指纹返回的结果数量限制 (默认20)
    /// - Returns: 每个指纹对应的匹配结果列表
    ///
    /// **Note**: This method extracts candidates internally. For multiple calls with the
    /// same pool, prefer extracting candidates once and using `findMatchesBatch(for:candidates:limit:)`.
    func findMatchesBatch(
        for fingerprints: [SkinFingerprint],
        in pool: [UserProfile],
        limit: Int = 20
    ) async -> [[SkinTwin]] {
        let candidates = Self.extractCandidates(from: pool)
        return await findMatchesBatch(for: fingerprints, candidates: candidates, limit: limit)
    }

    // MARK: - Internal Match Computation

    /// Compute matches for a single fingerprint against candidates
    /// All inputs are Sendable, safe for concurrent execution
    private func computeMatches(
        userVector: [Double],
        userFingerprint: SkinFingerprint,
        candidates: [MatchCandidate],
        limit: Int
    ) -> [SkinTwin] {
        candidates
            .compactMap { candidate -> SkinTwin? in
                let similarity = weightedSimilarity(
                    userVector: userVector,
                    userFingerprint: userFingerprint,
                    candidateVector: candidate.vector,
                    candidateFingerprint: candidate.fingerprint
                )

                guard similarity >= config.minSimilarity else { return nil }

                return SkinTwin(
                    userId: candidate.userId,
                    similarity: similarity,
                    matchLevel: MatchLevel(similarity: similarity),
                    anonymousProfile: candidate.anonymousProfile,
                    effectiveProducts: []
                )
            }
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Similarity Algorithm

    /// 加权相似度算法（使用预计算向量）
    ///
    /// 公式:
    /// finalScore = baseSimilarity (60%)
    ///            + skinTypeBonus (±20%)
    ///            + ageBonus (±10%)
    ///            + concernBonus (0-10%)
    ///            + sensitivityBonus (0-5%)
    ///
    private func weightedSimilarity(
        userVector: [Double],
        userFingerprint: SkinFingerprint,
        candidateVector: [Double],
        candidateFingerprint: SkinFingerprint
    ) -> Double {
        // 1. 基础余弦相似度 (使用预计算向量)
        let baseSimilarity = cosineSimilarity(userVector, candidateVector)

        // 2. 肤质类型匹配加成/惩罚 (±20%)
        let skinTypeBonus = userFingerprint.skinType == candidateFingerprint.skinType ? 0.2 : -0.3

        // 3. 年龄段接近加成 (±10%)
        let ageDiff = abs(userFingerprint.ageRange.normalized - candidateFingerprint.ageRange.normalized)
        let ageBonus: Double
        if ageDiff < 0.2 {
            ageBonus = 0.1      // 年龄非常接近
        } else if ageDiff > 0.4 {
            ageBonus = -0.1     // 年龄差距较大
        } else {
            ageBonus = 0        // 年龄适中
        }

        // 4. 共同关注点加成 (0-10%)
        let concernOverlap = Set(userFingerprint.concerns).intersection(candidateFingerprint.concerns)
        let concernBonus = Double(concernOverlap.count) * 0.03

        // 5. 敏感度一致性加成 (0-5%)
        let sensitivityBonus = abs(userFingerprint.irritationHistory - candidateFingerprint.irritationHistory) < 0.2
            ? 0.05
            : 0

        // 最终分数归一化到 [0, 1]
        let finalScore = baseSimilarity + skinTypeBonus + ageBonus + concernBonus + sensitivityBonus
        return min(1.0, max(0, finalScore))
    }

    /// Legacy weighted similarity (for backward compatibility with tests)
    private func weightedSimilarity(
        user: SkinFingerprint,
        other: SkinFingerprint
    ) -> Double {
        weightedSimilarity(
            userVector: user.vector,
            userFingerprint: user,
            candidateVector: other.vector,
            candidateFingerprint: other
        )
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

// MARK: - Array Extension

extension Array {
    /// 将数组分割成指定大小的块
    /// - Parameter size: 每块的最大元素数量
    /// - Returns: 分块后的二维数组
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
