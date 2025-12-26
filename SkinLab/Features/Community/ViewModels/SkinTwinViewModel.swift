// SkinLab/Features/Community/ViewModels/SkinTwinViewModel.swift
import Foundation
import SwiftData
import Observation

/// 皮肤双胞胎视图模型 - 管理匹配流程和状态
///
/// 职责:
/// - 协调匹配服务和推荐引擎
/// - 管理匹配结果状态
/// - 处理用户交互和反馈
/// - 缓存管理和数据持久化
@MainActor
@Observable
final class SkinTwinViewModel {

    // MARK: - Dependencies

    private var matcher: SkinMatcher?
    private var repository: MatchPoolRepository?
    private var recommendationEngine: ProductRecommendationEngine?
    private var historyStore: UserHistoryStore?
    private var matchCache: MatchCache
    private var modelContext: ModelContext?

    // MARK: - Published State

    /// 是否正在加载
    var isLoading: Bool = false

    /// 错误消息
    var errorMessage: String?

    /// 匹配结果列表
    var matches: [SkinTwin] = []

    /// 当前选中的双胞胎
    var selectedTwin: SkinTwin?

    /// 产品推荐列表
    var recommendations: [ProductRecommendationScore] = []

    /// 选中双胞胎的产品推荐
    var selectedTwinRecommendations: [ProductRecommendationScore] = []

    /// 当前用户资料
    var currentUserProfile: UserProfile?

    /// 当前同意等级
    var consentLevel: ConsentLevel = .none

    /// 匹配统计
    var matchStats: MatchStats?

    /// 是否显示同意设置
    var showConsentSettings: Bool = false

    /// 是否显示反馈表单
    var showFeedbackForm: Bool = false

    /// 当前反馈的匹配ID
    var feedbackMatchId: UUID?

    // MARK: - Computed Properties

    /// 是否可以进行匹配
    var canMatch: Bool {
        currentUserProfile != nil &&
        currentUserProfile?.skinType != nil &&
        consentLevel != .none
    }

    /// 是否有匹配结果
    var hasMatches: Bool {
        !matches.isEmpty
    }

    /// 匹配结果数量
    var matchCount: Int {
        matches.count
    }

    /// 顶级匹配 (相似度最高的3个)
    var topMatches: [SkinTwin] {
        Array(matches.prefix(3))
    }

    /// 推荐产品数量
    var recommendationCount: Int {
        recommendations.count
    }

    // MARK: - Initialization

    init() {
        self.matchCache = MatchCache()
    }

    /// 配置依赖
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.historyStore = UserHistoryStore(modelContext: modelContext)
        self.matcher = SkinMatcher()
        self.repository = MatchPoolRepository(modelContext: modelContext)
        self.recommendationEngine = ProductRecommendationEngine(
            historyStore: historyStore!,
            modelContext: modelContext
        )

        // 加载当前用户资料
        loadCurrentUserProfile()
    }

    // MARK: - Public Actions

    /// 加载匹配结果
    /// - Parameter forceRefresh: 是否强制刷新（忽略缓存）
    func loadMatches(forceRefresh: Bool = false) async {
        guard let profile = currentUserProfile else {
            errorMessage = "请先完善个人资料"
            return
        }

        guard consentLevel != .none else {
            showConsentSettings = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 1. 获取指纹
            guard let fingerprint = profile.getFingerprint(with: historyStore) else {
                throw MatchError.invalidFingerprint
            }

            let fingerprintHash = fingerprint.hashValue

            // 2. 检查缓存 (非强制刷新时)
            if !forceRefresh,
               let cachedMatches = matchCache.getMatches(for: profile.id, fingerprintHash: fingerprintHash),
               let cachedRecommendations = matchCache.getRecommendations(for: profile.id) {
                matches = cachedMatches
                recommendations = cachedRecommendations
                updateMatchStats()
                isLoading = false
                return
            }

            // 3. 检查 SwiftData 缓存
            if !forceRefresh,
               let cachedRecords = try? await repository?.getCachedMatches(for: profile.id),
               !cachedRecords.isEmpty {
                let cachedTwins = cachedRecords.compactMap { $0.toSkinTwin() }
                if !cachedTwins.isEmpty {
                    matches = cachedTwins
                    // 重新计算推荐
                    recommendations = await recommendationEngine?.rankProducts(
                        for: fingerprint,
                        basedOn: cachedTwins
                    ) ?? []

                    // 更新内存缓存
                    matchCache.set(
                        matches: matches,
                        recommendations: recommendations,
                        for: profile.id,
                        fingerprintHash: fingerprintHash
                    )

                    updateMatchStats()
                    isLoading = false
                    return
                }
            }

            // 4. 执行新的匹配
            guard let repository = repository,
                  let matcher = matcher,
                  let recommendationEngine = recommendationEngine else {
                throw MatchError.serviceUnavailable
            }

            // 5. 获取匹配池
            let pool = try await repository.fetchEligibleProfiles(excludingUserId: profile.id)

            guard !pool.isEmpty else {
                throw MatchError.emptyPool
            }

            // 6. 执行匹配算法
            var newMatches = await matcher.findMatches(for: fingerprint, in: pool)

            // 7. 为每个匹配加载有效产品
            newMatches = await loadEffectiveProducts(for: newMatches)

            // 8. 生成产品推荐
            let newRecommendations = await recommendationEngine.rankProducts(
                for: fingerprint,
                basedOn: newMatches
            )

            // 9. 更新状态
            matches = newMatches
            recommendations = newRecommendations

            // 10. 更新缓存
            matchCache.set(
                matches: newMatches,
                recommendations: newRecommendations,
                for: profile.id,
                fingerprintHash: fingerprintHash
            )

            // 11. 持久化到 SwiftData
            try await repository.saveMatches(newMatches, for: profile.id)

            // 12. 记录匹配活动
            profile.recordMatchActivity()

            updateMatchStats()

        } catch let error as MatchError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "匹配失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 选择双胞胎查看详情
    /// - Parameter twin: 选中的双胞胎
    func selectTwin(_ twin: SkinTwin) async {
        selectedTwin = twin

        // 加载该双胞胎的详细推荐
        guard let profile = currentUserProfile,
              let fingerprint = profile.getFingerprint(with: historyStore),
              let engine = recommendationEngine else {
            return
        }

        selectedTwinRecommendations = await engine.getProductsFromTwin(twin, for: fingerprint)
    }

    /// 清除选中状态
    func clearSelection() {
        selectedTwin = nil
        selectedTwinRecommendations = []
    }

    /// 提交反馈
    /// - Parameters:
    ///   - matchId: 匹配记录ID
    ///   - accuracy: 准确度评分 (1-5)
    ///   - isHelpful: 推荐是否有帮助
    ///   - feedbackText: 反馈文本
    func submitFeedback(
        matchId: UUID,
        accuracy: Int,
        isHelpful: Bool,
        feedbackText: String? = nil
    ) async {
        guard let modelContext = modelContext else { return }

        let feedback = UserFeedbackRecord(
            matchId: matchId,
            accuracyScore: accuracy,
            productFeedbackText: feedbackText,
            isHelpful: isHelpful
        )

        modelContext.insert(feedback)

        do {
            try modelContext.save()
            showFeedbackForm = false
            feedbackMatchId = nil
        } catch {
            errorMessage = "反馈提交失败: \(error.localizedDescription)"
        }
    }

    /// 显示反馈表单
    /// - Parameter matchId: 匹配记录ID
    func showFeedback(for matchId: UUID) {
        feedbackMatchId = matchId
        showFeedbackForm = true
    }

    /// 更新同意等级
    /// - Parameter level: 新的同意等级
    func updateConsent(_ level: ConsentLevel) async {
        currentUserProfile?.updateConsentLevel(level)
        consentLevel = level

        if let modelContext = modelContext {
            try? modelContext.save()
        }

        showConsentSettings = false

        // 如果用户同意，自动开始匹配
        if level != .none {
            await loadMatches(forceRefresh: true)
        } else {
            // 用户撤销同意，清除数据
            matches = []
            recommendations = []
            matchCache.clearAll()

            if let userId = currentUserProfile?.id {
                try? await repository?.invalidateCache(for: userId)
            }
        }
    }

    /// 刷新匹配结果
    func refresh() async {
        await loadMatches(forceRefresh: true)
    }

    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// 加载当前用户资料
    private func loadCurrentUserProfile() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        if let profiles = try? modelContext.fetch(descriptor),
           let profile = profiles.first {
            currentUserProfile = profile
            consentLevel = profile.consentLevel
        }
    }

    /// 为匹配结果加载有效产品
    private func loadEffectiveProducts(for twins: [SkinTwin]) async -> [SkinTwin] {
        // 实际实现中，这里会从 TrackingSession 获取每个用户验证有效的产品
        // 目前返回模拟数据
        return twins.map { twin in
            var mutableTwin = twin
            // 根据用户ID查询其有效产品记录
            mutableTwin.effectiveProducts = loadEffectiveProductsForUser(twin.userId)
            return mutableTwin
        }
    }

    /// 为特定用户加载有效产品
    private func loadEffectiveProductsForUser(_ userId: UUID) -> [EffectiveProduct] {
        // TODO: 实际实现需要从 TrackingSession 查询
        // 这里返回空数组，实际匹配时会填充
        return []
    }

    /// 更新匹配统计
    private func updateMatchStats() {
        guard !matches.isEmpty else {
            matchStats = nil
            return
        }

        let avgSimilarity = matches.map(\.similarity).reduce(0, +) / Double(matches.count)
        let twinCount = matches.filter { $0.matchLevel == .twin }.count
        let verySimilarCount = matches.filter { $0.matchLevel == .verySimilar }.count
        let totalProducts = matches.flatMap(\.effectiveProducts).count

        matchStats = MatchStats(
            totalMatches: matches.count,
            avgSimilarity: avgSimilarity,
            twinCount: twinCount,
            verySimilarCount: verySimilarCount,
            recommendedProductCount: recommendations.count,
            totalEffectiveProducts: totalProducts
        )
    }
}

// MARK: - Match Statistics

/// 匹配统计数据
struct MatchStats {
    let totalMatches: Int
    let avgSimilarity: Double
    let twinCount: Int
    let verySimilarCount: Int
    let recommendedProductCount: Int
    let totalEffectiveProducts: Int

    /// 平均相似度百分比
    var avgSimilarityPercent: Int {
        Int(avgSimilarity * 100)
    }

    /// 摘要文本
    var summary: String {
        if twinCount > 0 {
            return "找到\(twinCount)位皮肤双胞胎和\(verySimilarCount)位相似用户"
        } else if verySimilarCount > 0 {
            return "找到\(verySimilarCount)位非常相似的用户"
        } else {
            return "找到\(totalMatches)位相似用户"
        }
    }
}

// MARK: - Match Error

/// 匹配错误类型
enum MatchError: LocalizedError {
    case invalidFingerprint
    case noMatches
    case emptyPool
    case serviceUnavailable
    case cacheError

    var errorDescription: String? {
        switch self {
        case .invalidFingerprint:
            return "无法生成皮肤指纹，请完善个人资料"
        case .noMatches:
            return "暂无匹配的皮肤双胞胎，请稍后再试"
        case .emptyPool:
            return "匹配池为空，暂无其他用户参与匹配"
        case .serviceUnavailable:
            return "服务暂不可用，请稍后重试"
        case .cacheError:
            return "缓存读取错误"
        }
    }
}

// MARK: - Preview Helper

extension SkinTwinViewModel {
    /// 预览用的mock数据
    static var preview: SkinTwinViewModel {
        let vm = SkinTwinViewModel()
        vm.matches = [.mock]
        vm.recommendations = [.mock]
        vm.consentLevel = .pseudonymous
        vm.matchStats = MatchStats(
            totalMatches: 5,
            avgSimilarity: 0.85,
            twinCount: 1,
            verySimilarCount: 2,
            recommendedProductCount: 8,
            totalEffectiveProducts: 15
        )
        return vm
    }
}
