import Foundation
import SwiftData

// MARK: - User History Store
/// 管理用户历史数据的缓存和统计
/// 提供快速访问最近的分析记录和成分效果统计
final class UserHistoryStore {
    private let modelContext: ModelContext

    /// 缓存的最近分析记录数量
    private let maxRecentAnalyses = 10

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Skin Analysis History

    /// 获取最近的皮肤分析记录
    func getRecentAnalyses(limit: Int? = nil) -> [SkinAnalysis] {
        let fetchLimit = limit ?? maxRecentAnalyses

        let descriptor = FetchDescriptor<SkinAnalysisRecord>(
            sortBy: [SortDescriptor(\SkinAnalysisRecord.analyzedAt, order: .reverse)]
        )

        do {
            let records = try modelContext.fetch(descriptor)
            AppLogger.data(operation: .fetch, entity: "SkinAnalysisRecord", success: true, count: records.count)
            return records
                .prefix(fetchLimit)
                .compactMap { $0.toAnalysis() }
        } catch {
            AppLogger.data(operation: .fetch, entity: "SkinAnalysisRecord", success: false, error: error)
            return []
        }
    }
    
    /// 获取用户的基线数据（最近N次分析的平均值）
    func getBaseline(count: Int = 5) -> SkinBaseline? {
        let recent = getRecentAnalyses(limit: count)
        guard !recent.isEmpty else { return nil }
        
        let avgOverallScore = recent.map { $0.overallScore }.reduce(0, +) / recent.count
        let avgSkinAge = recent.map { $0.skinAge }.reduce(0, +) / recent.count
        
        // 计算各项问题的平均分
        let avgSpots = recent.compactMap { $0.issues.spots }.reduce(0, +) / recent.count
        let avgAcne = recent.compactMap { $0.issues.acne }.reduce(0, +) / recent.count
        let avgPores = recent.compactMap { $0.issues.pores }.reduce(0, +) / recent.count
        let avgWrinkles = recent.compactMap { $0.issues.wrinkles }.reduce(0, +) / recent.count
        let avgRedness = recent.compactMap { $0.issues.redness }.reduce(0, +) / recent.count
        
        return SkinBaseline(
            overallScore: avgOverallScore,
            skinAge: avgSkinAge,
            avgSpots: avgSpots,
            avgAcne: avgAcne,
            avgPores: avgPores,
            avgWrinkles: avgWrinkles,
            avgRedness: avgRedness,
            sampleCount: recent.count
        )
    }
    
    /// 检查用户是否有特定问题的历史
    func hasSevereIssue(_ issue: SkinIssueType, threshold: Int = 7) -> Bool {
        let recent = getRecentAnalyses(limit: 5)
        
        return recent.contains { analysis in
            switch issue {
            case .spots: return analysis.issues.spots > threshold
            case .acne: return analysis.issues.acne > threshold
            case .pores: return analysis.issues.pores > threshold
            case .wrinkles: return analysis.issues.wrinkles > threshold
            case .redness: return analysis.issues.redness > threshold
            case .evenness: return analysis.issues.evenness > threshold
            case .texture: return analysis.issues.texture > threshold
            }
        }
    }
    
    // MARK: - Ingredient Exposure History
    
    /// 获取特定成分的暴露记录
    func getIngredientExposures(
        ingredientName: String,
        limit: Int = 20
    ) -> [IngredientExposureRecord] {
        var descriptor = FetchDescriptor<IngredientExposureRecord>(
            predicate: #Predicate { $0.ingredientName == ingredientName },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            let records = try modelContext.fetch(descriptor)
            AppLogger.data(operation: .fetch, entity: "IngredientExposureRecord", success: true, count: records.count)
            return records
        } catch {
            AppLogger.data(operation: .fetch, entity: "IngredientExposureRecord", success: false, error: error)
            return []
        }
    }
    
    /// 计算特定成分的效果统计
    func getIngredientStats(ingredientName: String) -> IngredientEffectStats? {
        let exposures = getIngredientExposures(ingredientName: ingredientName)
        guard !exposures.isEmpty else { return nil }
        
        let betterCount = exposures.filter { $0.feeling == .better }.count
        let sameCount = exposures.filter { $0.feeling == .same }.count
        let worseCount = exposures.filter { $0.feeling == .worse }.count
        let lastUsed = exposures.first?.date ?? Date()
        
        return IngredientEffectStats(
            ingredientName: ingredientName,
            totalUses: exposures.count,
            betterCount: betterCount,
            sameCount: sameCount,
            worseCount: worseCount,
            lastUsedAt: lastUsed
        )
    }
    
    /// 获取所有成分的效果统计（用于批量分析）
    func getAllIngredientStats() -> [String: IngredientEffectStats] {
        let descriptor = FetchDescriptor<IngredientExposureRecord>()
        let allExposures: [IngredientExposureRecord]
        do {
            allExposures = try modelContext.fetch(descriptor)
            AppLogger.data(operation: .fetch, entity: "IngredientExposureRecord", success: true, count: allExposures.count)
        } catch {
            AppLogger.data(operation: .fetch, entity: "IngredientExposureRecord", success: false, error: error)
            return [:]
        }
        
        // 按成分名称分组
        let grouped = Dictionary(grouping: allExposures) { $0.ingredientName }
        
        var stats: [String: IngredientEffectStats] = [:]
        for (ingredientName, exposures) in grouped {
            let betterCount = exposures.filter { $0.feeling == .better }.count
            let sameCount = exposures.filter { $0.feeling == .same }.count
            let worseCount = exposures.filter { $0.feeling == .worse }.count
            let lastUsed = exposures.max(by: { $0.date < $1.date })?.date ?? Date()
            
            stats[ingredientName] = IngredientEffectStats(
                ingredientName: ingredientName,
                totalUses: exposures.count,
                betterCount: betterCount,
                sameCount: sameCount,
                worseCount: worseCount,
                lastUsedAt: lastUsed
            )
        }
        
        return stats
    }
    
    // MARK: - Ingredient Preferences
    
    /// 获取用户的成分偏好
    func getIngredientPreference(ingredientName: String) -> UserIngredientPreference? {
        let descriptor = FetchDescriptor<UserIngredientPreference>(
            predicate: #Predicate { $0.ingredientName == ingredientName }
        )

        do {
            let preferences = try modelContext.fetch(descriptor)
            return preferences.first
        } catch {
            AppLogger.data(operation: .fetch, entity: "UserIngredientPreference", success: false, error: error)
            return nil
        }
    }
    
    /// 获取所有成分偏好
    func getAllIngredientPreferences() -> [UserIngredientPreference] {
        let descriptor = FetchDescriptor<UserIngredientPreference>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )

        do {
            let preferences = try modelContext.fetch(descriptor)
            AppLogger.data(operation: .fetch, entity: "UserIngredientPreference", success: true, count: preferences.count)
            return preferences
        } catch {
            AppLogger.data(operation: .fetch, entity: "UserIngredientPreference", success: false, error: error)
            return []
        }
    }
    
    /// 保存或更新成分偏好
    func saveIngredientPreference(
        ingredientName: String,
        score: Int,
        source: PreferenceSource,
        notes: String? = nil
    ) {
        if let existing = getIngredientPreference(ingredientName: ingredientName) {
            existing.updateScore(score, source: source)
            if let notes = notes {
                existing.notes = notes
            }
        } else {
            let preference = UserIngredientPreference(
                ingredientName: ingredientName,
                preferenceScore: score,
                source: source,
                notes: notes
            )
            modelContext.insert(preference)
        }

        do {
            try modelContext.save()
            AppLogger.data(operation: .save, entity: "UserIngredientPreference", success: true)
        } catch {
            AppLogger.data(operation: .save, entity: "UserIngredientPreference", success: false, error: error)
        }
    }
    
    // MARK: - Auto Learning
    
    /// 基于暴露记录自动学习成分偏好
    func autoLearnPreferences() {
        let allStats = getAllIngredientStats()
        
        for (ingredientName, stats) in allStats {
            // 只有足够的使用次数才自动学习
            guard stats.totalUses >= 3 else { continue }
            
            // 计算偏好分数 (-100 到 100)
            let score = Int(stats.avgEffectiveness * 100)
            
            saveIngredientPreference(
                ingredientName: ingredientName,
                score: score,
                source: .autoFromCheckIn
            )
        }
    }
}

// MARK: - Skin Baseline
/// 用户的皮肤基线数据
struct SkinBaseline: Codable, Sendable {
    let overallScore: Int
    let skinAge: Int
    let avgSpots: Int
    let avgAcne: Int
    let avgPores: Int
    let avgWrinkles: Int
    let avgRedness: Int
    let sampleCount: Int
    
    /// 是否有足够的样本
    var hasSufficientData: Bool {
        sampleCount >= 3
    }
}

// MARK: - Skin Issue Type
enum SkinIssueType {
    case spots
    case acne
    case pores
    case wrinkles
    case redness
    case evenness
    case texture
}
