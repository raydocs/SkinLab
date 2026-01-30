// SkinLab/Features/Community/Services/FeedbackAnalyticsService.swift
import Foundation
import SwiftData

/// 反馈分析服务 - 收集和分析用户反馈数据
///
/// 功能:
/// - 聚合反馈统计数据
/// - 分析匹配准确度趋势
/// - 识别需要优化的匹配场景
/// - 导出反馈数据供进一步分析
@MainActor
final class FeedbackAnalyticsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 获取反馈统计摘要
    func getStatsSummary() async throws -> FeedbackStatsSummary {
        let allFeedback = try await fetchAllFeedback()

        guard !allFeedback.isEmpty else {
            return FeedbackStatsSummary.empty
        }

        // 计算统计数据
        let totalCount = allFeedback.count
        let avgAccuracy = Double(allFeedback.map(\.accuracyScore).reduce(0, +)) / Double(totalCount)
        let helpfulCount = allFeedback.filter(\.isHelpful).count
        let helpfulRate = Double(helpfulCount) / Double(totalCount)

        // 按评分分布
        let scoreDistribution = Dictionary(grouping: allFeedback, by: \.accuracyScore)
            .mapValues { $0.count }

        // 按日期分组 (最近7天)
        let recentFeedback = allFeedback.filter {
            $0.createdAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
        let recentCount = recentFeedback.count
        let recentAvgAccuracy =
            recentFeedback.isEmpty
                ? 0
                : Double(recentFeedback.map(\.accuracyScore).reduce(0, +))
                / Double(recentFeedback.count)

        return FeedbackStatsSummary(
            totalFeedbackCount: totalCount,
            averageAccuracyScore: avgAccuracy,
            helpfulRate: helpfulRate,
            scoreDistribution: scoreDistribution,
            recentFeedbackCount: recentCount,
            recentAverageAccuracy: recentAvgAccuracy,
            lastUpdated: Date()
        )
    }

    /// 获取匹配准确度趋势 (按周)
    func getAccuracyTrend(weeks: Int = 4) async throws -> [AccuracyTrendPoint] {
        let allFeedback = try await fetchAllFeedback()

        var trends: [AccuracyTrendPoint] = []
        let calendar = Calendar.current

        for weekOffset in 0 ..< weeks {
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date())!
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekEnd)!

            let weekFeedback = allFeedback.filter {
                $0.createdAt >= weekStart && $0.createdAt < weekEnd
            }

            if !weekFeedback.isEmpty {
                let avgScore =
                    Double(weekFeedback.map(\.accuracyScore).reduce(0, +))
                        / Double(weekFeedback.count)
                let helpfulRate =
                    Double(weekFeedback.filter(\.isHelpful).count) / Double(weekFeedback.count)

                trends.append(
                    AccuracyTrendPoint(
                        weekStart: weekStart,
                        weekEnd: weekEnd,
                        averageAccuracy: avgScore,
                        helpfulRate: helpfulRate,
                        sampleCount: weekFeedback.count
                    )
                )
            }
        }

        return trends.reversed() // 按时间正序
    }

    /// 识别低评分匹配 (用于算法优化)
    func getLowRatedMatches(threshold: Int = 2) async throws -> [LowRatedMatchInfo] {
        let descriptor = FetchDescriptor<UserFeedbackRecord>(
            predicate: #Predicate { $0.accuracyScore <= threshold },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let lowRatedFeedback = try modelContext.fetch(descriptor)

        return lowRatedFeedback.map { feedback in
            LowRatedMatchInfo(
                feedbackId: feedback.id,
                matchId: feedback.matchId,
                accuracyScore: feedback.accuracyScore,
                isHelpful: feedback.isHelpful,
                feedbackText: feedback.productFeedbackText,
                createdAt: feedback.createdAt
            )
        }
    }

    /// 获取反馈文本分析 (关键词提取)
    func getTextFeedbackAnalysis() async throws -> TextFeedbackAnalysis {
        let allFeedback = try await fetchAllFeedback()

        let textsWithFeedback = allFeedback.compactMap(\.productFeedbackText)

        guard !textsWithFeedback.isEmpty else {
            return TextFeedbackAnalysis(
                totalWithText: 0,
                commonKeywords: [],
                averageLengthChars: 0
            )
        }

        // 关键词统计 (简单实现)
        let allWords =
            textsWithFeedback
                .flatMap { $0.components(separatedBy: CharacterSet.alphanumerics.inverted) }
                .filter { $0.count > 1 }

        let wordCounts = Dictionary(grouping: allWords, by: { $0.lowercased() })
            .mapValues { $0.count }
            .filter { $0.value >= 2 } // 至少出现2次
            .sorted { $0.value > $1.value }
            .prefix(20)

        let avgLength = textsWithFeedback.map(\.count).reduce(0, +) / textsWithFeedback.count

        return TextFeedbackAnalysis(
            totalWithText: textsWithFeedback.count,
            commonKeywords: Array(wordCounts.map { KeywordCount(word: $0.key, count: $0.value) }),
            averageLengthChars: avgLength
        )
    }

    /// 根据反馈调整算法权重建议
    func getAlgorithmTuningRecommendations() async throws -> [AlgorithmTuningRecommendation] {
        let stats = try await getStatsSummary()
        var recommendations: [AlgorithmTuningRecommendation] = []

        // 基于平均准确度给出建议
        if stats.averageAccuracyScore < 3.0 {
            recommendations.append(
                AlgorithmTuningRecommendation(
                    area: .similarityThreshold,
                    suggestion: "考虑提高最低相似度阈值 (当前0.6 → 建议0.7)",
                    priority: .high,
                    basedOn: "平均准确度评分 \(String(format: "%.1f", stats.averageAccuracyScore)) < 3.0"
                )
            )
        }

        if stats.helpfulRate < 0.5 {
            recommendations.append(
                AlgorithmTuningRecommendation(
                    area: .productRecommendation,
                    suggestion: "优化产品推荐算法，增加成分匹配权重",
                    priority: .high,
                    basedOn: "有帮助率 \(String(format: "%.0f%%", stats.helpfulRate * 100)) < 50%"
                )
            )
        }

        // 检查评分分布
        if let lowScoreCount = stats.scoreDistribution[1],
           let highScoreCount = stats.scoreDistribution[5],
           lowScoreCount > highScoreCount {
            recommendations.append(
                AlgorithmTuningRecommendation(
                    area: .skinTypeMatching,
                    suggestion: "增强肤质类型匹配权重，减少不匹配情况",
                    priority: .medium,
                    basedOn: "1分评价 (\(lowScoreCount)) > 5分评价 (\(highScoreCount))"
                )
            )
        }

        if recommendations.isEmpty {
            recommendations.append(
                AlgorithmTuningRecommendation(
                    area: .general,
                    suggestion: "当前算法表现良好，继续收集数据",
                    priority: .low,
                    basedOn: "各项指标正常"
                )
            )
        }

        return recommendations
    }

    // MARK: - Private Methods

    private func fetchAllFeedback() async throws -> [UserFeedbackRecord] {
        let descriptor = FetchDescriptor<UserFeedbackRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Data Models

/// 反馈统计摘要
struct FeedbackStatsSummary: Codable {
    let totalFeedbackCount: Int
    let averageAccuracyScore: Double
    let helpfulRate: Double
    let scoreDistribution: [Int: Int]
    let recentFeedbackCount: Int
    let recentAverageAccuracy: Double
    let lastUpdated: Date

    static let empty = FeedbackStatsSummary(
        totalFeedbackCount: 0,
        averageAccuracyScore: 0,
        helpfulRate: 0,
        scoreDistribution: [:],
        recentFeedbackCount: 0,
        recentAverageAccuracy: 0,
        lastUpdated: Date()
    )

    /// 格式化的平均准确度
    var formattedAccuracy: String {
        String(format: "%.1f", averageAccuracyScore)
    }

    /// 格式化的有帮助率
    var formattedHelpfulRate: String {
        String(format: "%.0f%%", helpfulRate * 100)
    }
}

/// 准确度趋势点
struct AccuracyTrendPoint: Codable, Identifiable {
    var id: Date {
        weekStart
    }

    let weekStart: Date
    let weekEnd: Date
    let averageAccuracy: Double
    let helpfulRate: Double
    let sampleCount: Int

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: weekStart)
    }
}

/// 低评分匹配信息
struct LowRatedMatchInfo: Codable, Identifiable {
    var id: UUID {
        feedbackId
    }

    let feedbackId: UUID
    let matchId: UUID
    let accuracyScore: Int
    let isHelpful: Bool
    let feedbackText: String?
    let createdAt: Date
}

/// 文本反馈分析
struct TextFeedbackAnalysis: Codable {
    let totalWithText: Int
    let commonKeywords: [KeywordCount]
    let averageLengthChars: Int
}

struct KeywordCount: Codable, Identifiable {
    var id: String {
        word
    }

    let word: String
    let count: Int
}

/// 算法调优建议
struct AlgorithmTuningRecommendation: Codable, Identifiable {
    var id: String {
        area.rawValue
    }

    let area: TuningArea
    let suggestion: String
    let priority: Priority
    let basedOn: String

    enum TuningArea: String, Codable {
        case similarityThreshold = "相似度阈值"
        case skinTypeMatching = "肤质匹配"
        case productRecommendation = "产品推荐"
        case ageMatching = "年龄匹配"
        case concernMatching = "关注点匹配"
        case general = "综合"
    }

    enum Priority: String, Codable {
        case high = "高"
        case medium = "中"
        case low = "低"

        var color: String {
            switch self {
            case .high: "red"
            case .medium: "orange"
            case .low: "green"
            }
        }
    }
}
