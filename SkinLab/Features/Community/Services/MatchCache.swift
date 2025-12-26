// SkinLab/Features/Community/Services/MatchCache.swift
import Foundation

/// 匹配结果内存缓存管理器
///
/// 多层缓存策略:
/// - L1: 内存缓存 (MatchCache) - 24小时有效
/// - L2: SwiftData缓存 (MatchResultRecord) - 24小时有效
/// - L3: 实时计算 - 缓存未命中时触发
@MainActor
final class MatchCache {

    // MARK: - Configuration

    /// 缓存过期时间 (24小时)
    private let cacheExpiration: TimeInterval = 86400

    /// 最大缓存用户数
    private let maxCacheSize: Int = 100

    // MARK: - Storage

    /// 内存缓存存储
    private var cache: [UUID: CacheEntry] = [:]

    /// 访问顺序记录 (LRU)
    private var accessOrder: [UUID] = []

    // MARK: - Cache Entry

    /// 缓存条目
    struct CacheEntry {
        let matches: [SkinTwin]
        let recommendations: [ProductRecommendationScore]
        let timestamp: Date
        let fingerprintHash: Int

        /// 是否已过期
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 86400
        }

        /// 缓存年龄 (秒)
        var age: TimeInterval {
            Date().timeIntervalSince(timestamp)
        }
    }

    // MARK: - Public Methods

    /// 获取缓存的匹配结果
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - fingerprintHash: 当前指纹的哈希值 (用于检测变化)
    /// - Returns: 缓存的匹配结果，如果无效则返回nil
    func getMatches(
        for userId: UUID,
        fingerprintHash: Int? = nil
    ) -> [SkinTwin]? {
        guard let entry = cache[userId] else { return nil }

        // 检查是否过期
        guard !entry.isExpired else {
            invalidate(for: userId)
            return nil
        }

        // 检查指纹是否变化
        if let hash = fingerprintHash, hash != entry.fingerprintHash {
            invalidate(for: userId)
            return nil
        }

        // 更新访问顺序 (LRU)
        updateAccessOrder(for: userId)

        return entry.matches
    }

    /// 获取缓存的产品推荐
    /// - Parameter userId: 用户ID
    /// - Returns: 缓存的产品推荐，如果无效则返回nil
    func getRecommendations(for userId: UUID) -> [ProductRecommendationScore]? {
        guard let entry = cache[userId], !entry.isExpired else {
            return nil
        }

        updateAccessOrder(for: userId)
        return entry.recommendations
    }

    /// 获取完整缓存条目
    /// - Parameter userId: 用户ID
    /// - Returns: 缓存条目
    func getEntry(for userId: UUID) -> CacheEntry? {
        guard let entry = cache[userId], !entry.isExpired else {
            return nil
        }

        updateAccessOrder(for: userId)
        return entry
    }

    /// 设置缓存
    /// - Parameters:
    ///   - matches: 匹配结果
    ///   - recommendations: 产品推荐
    ///   - userId: 用户ID
    ///   - fingerprintHash: 指纹哈希值
    func set(
        matches: [SkinTwin],
        recommendations: [ProductRecommendationScore] = [],
        for userId: UUID,
        fingerprintHash: Int = 0
    ) {
        // 检查容量，必要时淘汰旧条目
        ensureCapacity()

        let entry = CacheEntry(
            matches: matches,
            recommendations: recommendations,
            timestamp: Date(),
            fingerprintHash: fingerprintHash
        )

        cache[userId] = entry
        updateAccessOrder(for: userId)
    }

    /// 更新推荐缓存 (保留匹配结果)
    /// - Parameters:
    ///   - recommendations: 新的产品推荐
    ///   - userId: 用户ID
    func updateRecommendations(
        _ recommendations: [ProductRecommendationScore],
        for userId: UUID
    ) {
        guard let existing = cache[userId] else { return }

        let entry = CacheEntry(
            matches: existing.matches,
            recommendations: recommendations,
            timestamp: existing.timestamp,
            fingerprintHash: existing.fingerprintHash
        )

        cache[userId] = entry
    }

    /// 使特定用户的缓存失效
    /// - Parameter userId: 用户ID
    func invalidate(for userId: UUID) {
        cache.removeValue(forKey: userId)
        accessOrder.removeAll { $0 == userId }
    }

    /// 清除所有过期缓存
    func clearExpired() {
        let expiredKeys = cache.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            invalidate(for: key)
        }
    }

    /// 清除所有缓存
    func clearAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    /// 获取缓存统计信息
    func getStats() -> CacheStats {
        let validEntries = cache.filter { !$0.value.isExpired }
        let expiredEntries = cache.filter { $0.value.isExpired }

        let avgAge = validEntries.isEmpty ? 0 :
            validEntries.values.map(\.age).reduce(0, +) / Double(validEntries.count)

        let totalMatches = validEntries.values.map { $0.matches.count }.reduce(0, +)
        let totalRecommendations = validEntries.values.map { $0.recommendations.count }.reduce(0, +)

        return CacheStats(
            totalEntries: cache.count,
            validEntries: validEntries.count,
            expiredEntries: expiredEntries.count,
            avgAge: avgAge,
            totalMatches: totalMatches,
            totalRecommendations: totalRecommendations,
            memoryUsageEstimate: estimateMemoryUsage()
        )
    }

    // MARK: - Private Methods

    /// 更新访问顺序 (LRU)
    private func updateAccessOrder(for userId: UUID) {
        accessOrder.removeAll { $0 == userId }
        accessOrder.append(userId)
    }

    /// 确保缓存容量 (LRU淘汰)
    private func ensureCapacity() {
        while cache.count >= maxCacheSize, let oldestUserId = accessOrder.first {
            invalidate(for: oldestUserId)
        }
    }

    /// 估算内存使用量 (字节)
    private func estimateMemoryUsage() -> Int {
        // 粗略估算每个匹配结果约 500 字节
        let matchBytes = cache.values.map { $0.matches.count * 500 }.reduce(0, +)
        // 每个推荐约 300 字节
        let recommendationBytes = cache.values.map { $0.recommendations.count * 300 }.reduce(0, +)
        // 基础开销
        let overhead = cache.count * 100

        return matchBytes + recommendationBytes + overhead
    }
}

// MARK: - Cache Statistics

/// 缓存统计信息
struct CacheStats {
    let totalEntries: Int
    let validEntries: Int
    let expiredEntries: Int
    let avgAge: TimeInterval
    let totalMatches: Int
    let totalRecommendations: Int
    let memoryUsageEstimate: Int

    /// 格式化的平均年龄
    var formattedAvgAge: String {
        let hours = Int(avgAge / 3600)
        let minutes = Int((avgAge.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    /// 格式化的内存使用
    var formattedMemoryUsage: String {
        if memoryUsageEstimate < 1024 {
            return "\(memoryUsageEstimate) B"
        } else if memoryUsageEstimate < 1024 * 1024 {
            return String(format: "%.1f KB", Double(memoryUsageEstimate) / 1024)
        } else {
            return String(format: "%.1f MB", Double(memoryUsageEstimate) / 1024 / 1024)
        }
    }
}

// MARK: - SkinFingerprint Extension

extension SkinFingerprint {
    /// 计算指纹哈希值 (用于缓存验证)
    var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(skinType)
        hasher.combine(ageRange)
        hasher.combine(concerns)
        hasher.combine(fragranceTolerance)
        hasher.combine(uvExposure)
        hasher.combine(budgetLevel)
        return hasher.finalize()
    }
}
