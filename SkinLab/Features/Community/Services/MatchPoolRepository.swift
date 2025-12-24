// SkinLab/Features/Community/Services/MatchPoolRepository.swift
import Foundation
import SwiftData

/// 匹配池数据仓库 - 负责查询可匹配用户和缓存管理
@MainActor
class MatchPoolRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 获取符合条件的匹配池用户
    /// - Parameters:
    ///   - excludingUserId: 排除的用户ID (当前用户)
    ///   - limit: 限制返回数量
    /// - Returns: 可匹配的用户列表
    func fetchEligibleProfiles(
        excludingUserId: UUID,
        limit: Int = 1000
    ) async throws -> [UserProfile] {
        var descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.id != excludingUserId &&
                profile.consentLevelRaw != "none" &&
                profile.fingerprintData != nil
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取缓存的匹配结果
    /// - Parameter userId: 用户ID
    /// - Returns: 有效的缓存匹配结果
    func getCachedMatches(for userId: UUID) async throws -> [MatchResultRecord] {
        let now = Date()
        let descriptor = FetchDescriptor<MatchResultRecord>(
            predicate: #Predicate { record in
                record.userId == userId &&
                (record.expiresAt ?? now) > now
            },
            sortBy: [SortDescriptor(\.similarity, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 保存匹配结果到缓存
    /// - Parameters:
    ///   - matches: 匹配结果列表
    ///   - userId: 当前用户ID
    func saveMatches(_ matches: [SkinTwin], for userId: UUID) async throws {
        // 1. 删除旧的缓存记录
        try await deleteExpiredMatches(for: userId)
        
        // 2. 保存新的匹配结果
        for match in matches {
            let record = MatchResultRecord(from: match, userId: userId)
            modelContext.insert(record)
        }
        
        try modelContext.save()
    }
    
    /// 删除过期的匹配记录
    /// - Parameter userId: 用户ID (可选，nil表示清理所有用户)
    func deleteExpiredMatches(for userId: UUID? = nil) async throws {
        let now = Date()
        
        let descriptor: FetchDescriptor<MatchResultRecord>
        if let userId = userId {
            descriptor = FetchDescriptor(
                predicate: #Predicate { record in
                    record.userId == userId &&
                    (record.expiresAt ?? now) <= now
                }
            )
        } else {
            descriptor = FetchDescriptor(
                predicate: #Predicate { record in
                    (record.expiresAt ?? now) <= now
                }
            )
        }
        
        let expiredRecords = try modelContext.fetch(descriptor)
        for record in expiredRecords {
            modelContext.delete(record)
        }
        
        try modelContext.save()
    }
    
    /// 使缓存失效
    /// - Parameter userId: 用户ID
    func invalidateCache(for userId: UUID) async throws {
        let descriptor = FetchDescriptor<MatchResultRecord>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }
        
        try modelContext.save()
    }
}
