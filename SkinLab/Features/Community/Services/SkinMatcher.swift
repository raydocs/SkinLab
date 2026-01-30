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
/// - 单条处理: `findMatches(for:in:limit:)` - 接受 UserProfile 数组 (MainActor)
/// - 批量处理: `findMatchesBatch(for:candidates:limit:)` - 接受预提取的 MatchCandidate 数组
///
/// **Concurrency Safety**:
/// - Methods accepting `[UserProfile]` are `@MainActor` to ensure SwiftData safety
/// - Methods accepting `[MatchCandidate]` are safe for background execution
/// - All computation is performed via static functions to avoid capturing `self`
final class SkinMatcher: Sendable {
    // MARK: - Configuration

    /// 批处理配置
    struct BatchConfig: Sendable {
        /// 每批最大处理数量 (controls concurrent task count)
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
        // Validate and clamp config values to prevent runtime issues
        self.config = BatchConfig(
            maxBatchSize: max(1, config.maxBatchSize),
            minSimilarity: min(1, max(0, config.minSimilarity)),
            enableParallelProcessing: config.enableParallelProcessing
        )
    }

    // MARK: - Candidate Extraction (MainActor)

    /// Extract match candidates from UserProfile array
    /// - Parameter pool: Array of UserProfile
    /// - Returns: Array of Sendable MatchCandidate for use in batch processing
    @MainActor
    static func extractCandidates(from pool: [UserProfile]) -> [MatchCandidate] {
        pool.compactMap { profile -> MatchCandidate? in
            guard let fingerprint = profile.getFingerprint() else { return nil }
            return MatchCandidate(
                userId: profile.id,
                fingerprint: fingerprint,
                vector: fingerprint.vector, // Pre-compute vector once
                anonymousProfile: profile.toAnonymousProfile()
            )
        }
    }

    // MARK: - Public Methods (Single Processing - MainActor)

    /// 查找皮肤双胞胎（单条处理）
    /// - Parameters:
    ///   - fingerprint: 当前用户的皮肤指纹
    ///   - pool: 候选用户池
    ///   - limit: 返回结果数量限制 (默认20)
    /// - Returns: 匹配结果列表，按相似度降序排列
    @MainActor
    func findMatches(
        for fingerprint: SkinFingerprint,
        in pool: [UserProfile],
        limit: Int = 20
    ) -> [SkinTwin] {
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
        let userVector = fingerprint.vector
        return Self.computeMatches(
            userVector: userVector,
            userFingerprint: fingerprint,
            candidates: candidates,
            limit: limit,
            minSimilarity: config.minSimilarity
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
    /// - 并行计算多个指纹的匹配（按 maxBatchSize 分批控制并发）
    /// - 减少50%以上的重复计算
    func findMatchesBatch(
        for fingerprints: [SkinFingerprint],
        candidates: [MatchCandidate],
        limit: Int = 20
    ) async -> [[SkinTwin]] {
        guard !fingerprints.isEmpty else { return [] }
        guard !candidates.isEmpty else { return fingerprints.map { _ in [] } }

        // Pre-compute all user vectors once
        let indexed = fingerprints.enumerated().map { (index: $0, fp: $1, vector: $1.vector) }

        // Pre-allocated results array
        var results = Array(repeating: [SkinTwin](), count: fingerprints.count)

        let minSimilarity = config.minSimilarity
        let maxBatchSize = config.maxBatchSize
        let enableParallel = config.enableParallelProcessing

        // Process in chunks to control concurrency
        for start in stride(from: 0, to: indexed.count, by: maxBatchSize) {
            let end = min(start + maxBatchSize, indexed.count)
            let batch = indexed[start ..< end]

            if enableParallel {
                // Parallel processing within batch
                await withTaskGroup(of: (Int, [SkinTwin]).self) { group in
                    for item in batch {
                        group.addTask {
                            let matches = Self.computeMatches(
                                userVector: item.vector,
                                userFingerprint: item.fp,
                                candidates: candidates,
                                limit: limit,
                                minSimilarity: minSimilarity
                            )
                            return (item.index, matches)
                        }
                    }

                    for await (index, matches) in group {
                        results[index] = matches
                    }
                }
            } else {
                // Serial processing
                for item in batch {
                    results[item.index] = Self.computeMatches(
                        userVector: item.vector,
                        userFingerprint: item.fp,
                        candidates: candidates,
                        limit: limit,
                        minSimilarity: minSimilarity
                    )
                }
            }
        }

        return results
    }

    /// 批量查找皮肤双胞胎（从 UserProfile 数组，便捷方法）
    /// - Parameters:
    ///   - fingerprints: 多个用户的皮肤指纹
    ///   - pool: 候选用户池
    ///   - limit: 每个指纹返回的结果数量限制 (默认20)
    /// - Returns: 每个指纹对应的匹配结果列表
    @MainActor
    func findMatchesBatch(
        for fingerprints: [SkinFingerprint],
        in pool: [UserProfile],
        limit: Int = 20
    ) async -> [[SkinTwin]] {
        let candidates = Self.extractCandidates(from: pool)
        return await findMatchesBatch(for: fingerprints, candidates: candidates, limit: limit)
    }

    // MARK: - Static Match Computation (Sendable-safe)

    /// Compute matches for a single fingerprint against candidates
    /// Static function - does not capture `self`, safe for TaskGroup
    private static func computeMatches(
        userVector: [Double],
        userFingerprint: SkinFingerprint,
        candidates: [MatchCandidate],
        limit: Int,
        minSimilarity: Double
    ) -> [SkinTwin] {
        candidates
            .compactMap { candidate -> SkinTwin? in
                let similarity = weightedSimilarity(
                    userVector: userVector,
                    userFingerprint: userFingerprint,
                    candidateVector: candidate.vector,
                    candidateFingerprint: candidate.fingerprint
                )

                guard similarity >= minSimilarity else { return nil }

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

    // MARK: - Static Similarity Algorithm

    /// 加权相似度算法（使用预计算向量）
    /// Static function for use in TaskGroup
    private static func weightedSimilarity(
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
        let ageBonus: Double = if ageDiff < 0.2 {
            0.1 // 年龄非常接近
        } else if ageDiff > 0.4 {
            -0.1 // 年龄差距较大
        } else {
            0 // 年龄适中
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

    /// 计算余弦相似度
    /// Static function for use in TaskGroup
    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
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
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
