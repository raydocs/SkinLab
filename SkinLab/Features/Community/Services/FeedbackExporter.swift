// SkinLab/Features/Community/Services/FeedbackExporter.swift
import Foundation
import SwiftData

/// 反馈数据导出器 - 支持 CSV 和 JSON 格式
///
/// 用途:
/// - 导出反馈数据供外部分析工具使用
/// - 备份用户反馈历史
/// - 生成报告数据
@MainActor
final class FeedbackExporter {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Export Methods

    /// 导出所有反馈为 CSV 格式
    func exportToCSV() async throws -> String {
        let feedback = try await fetchAllFeedback()

        var csv = "id,match_id,accuracy_score,is_helpful,feedback_text,created_at\n"

        let dateFormatter = ISO8601DateFormatter()

        for record in feedback {
            let feedbackText = record.productFeedbackText?
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ") ?? ""

            let line = [
                record.id.uuidString,
                record.matchId.uuidString,
                String(record.accuracyScore),
                record.isHelpful ? "true" : "false",
                "\"\(feedbackText)\"",
                dateFormatter.string(from: record.createdAt)
            ].joined(separator: ",")

            csv += line + "\n"
        }

        return csv
    }

    /// 导出所有反馈为 JSON 格式
    func exportToJSON() async throws -> Data {
        let feedback = try await fetchAllFeedback()

        let exportData = feedback.map { record in
            FeedbackExportRecord(
                id: record.id,
                matchId: record.matchId,
                accuracyScore: record.accuracyScore,
                isHelpful: record.isHelpful,
                feedbackText: record.productFeedbackText,
                createdAt: record.createdAt
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    /// 导出统计摘要为 JSON
    func exportStatsSummary() async throws -> Data {
        let analyticsService = FeedbackAnalyticsService(modelContext: modelContext)
        let stats = try await analyticsService.getStatsSummary()
        let trends = try await analyticsService.getAccuracyTrend(weeks: 8)
        let recommendations = try await analyticsService.getAlgorithmTuningRecommendations()

        let report = FeedbackAnalyticsReport(
            generatedAt: Date(),
            summary: stats,
            weeklyTrends: trends,
            recommendations: recommendations
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(report)
    }

    /// 导出到文件并返回 URL
    func exportToFile(format: ExportFormat) async throws -> URL {
        let data: Data
        let fileName: String

        switch format {
        case .csv:
            let csvString = try await exportToCSV()
            data = csvString.data(using: .utf8)!
            fileName = "skinlab_feedback_\(dateStamp).csv"

        case .json:
            data = try await exportToJSON()
            fileName = "skinlab_feedback_\(dateStamp).json"

        case .analyticsReport:
            data = try await exportStatsSummary()
            fileName = "skinlab_analytics_report_\(dateStamp).json"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        return fileURL
    }

    // MARK: - Import Methods (for testing/restore)

    /// 从 JSON 导入反馈数据
    func importFromJSON(_ data: Data) async throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let records = try decoder.decode([FeedbackExportRecord].self, from: data)

        var importedCount = 0
        var skippedCount = 0

        for record in records {
            // 检查是否已存在
            let descriptor = FetchDescriptor<UserFeedbackRecord>(
                predicate: #Predicate { $0.id == record.id }
            )

            let existing = try modelContext.fetch(descriptor)

            if existing.isEmpty {
                let newRecord = UserFeedbackRecord(
                    matchId: record.matchId,
                    accuracyScore: record.accuracyScore,
                    productFeedbackText: record.feedbackText,
                    isHelpful: record.isHelpful
                )
                modelContext.insert(newRecord)
                importedCount += 1
            } else {
                skippedCount += 1
            }
        }

        try modelContext.save()

        return ImportResult(
            totalRecords: records.count,
            importedCount: importedCount,
            skippedCount: skippedCount
        )
    }

    // MARK: - Private Methods

    private func fetchAllFeedback() async throws -> [UserFeedbackRecord] {
        let descriptor = FetchDescriptor<UserFeedbackRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case analyticsReport = "Analytics Report"

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json, .analyticsReport: return "json"
        }
    }

    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json, .analyticsReport: return "application/json"
        }
    }
}

// MARK: - Export/Import Models

struct FeedbackExportRecord: Codable {
    let id: UUID
    let matchId: UUID
    let accuracyScore: Int
    let isHelpful: Bool
    let feedbackText: String?
    let createdAt: Date
}

struct FeedbackAnalyticsReport: Codable {
    let generatedAt: Date
    let summary: FeedbackStatsSummary
    let weeklyTrends: [AccuracyTrendPoint]
    let recommendations: [AlgorithmTuningRecommendation]
}

struct ImportResult {
    let totalRecords: Int
    let importedCount: Int
    let skippedCount: Int

    var summary: String {
        "导入完成: \(importedCount) 条新记录, \(skippedCount) 条跳过 (共 \(totalRecords) 条)"
    }
}
