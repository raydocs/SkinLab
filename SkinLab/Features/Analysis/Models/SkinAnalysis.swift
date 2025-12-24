import Foundation
import SwiftData

// MARK: - Skin Types
enum SkinType: String, Codable, CaseIterable, Sendable {
    case dry = "dry"
    case oily = "oily"
    case combination = "combination"
    case sensitive = "sensitive"
    
    var displayName: String {
        switch self {
        case .dry: return "干性"
        case .oily: return "油性"
        case .combination: return "混合性"
        case .sensitive: return "敏感性"
        }
    }
    
    var icon: String {
        switch self {
        case .dry: return "drop"
        case .oily: return "drop.fill"
        case .combination: return "circle.lefthalf.filled"
        case .sensitive: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Issue Scores
struct IssueScores: Codable, Equatable, Sendable {
    let spots: Int
    let acne: Int
    let pores: Int
    let wrinkles: Int
    let redness: Int
    let evenness: Int
    let texture: Int
    
    static let empty = IssueScores(
        spots: 0, acne: 0, pores: 0, wrinkles: 0,
        redness: 0, evenness: 0, texture: 0
    )
}

// MARK: - Region Scores
struct RegionScores: Codable, Equatable, Sendable {
    let tZone: Int
    let leftCheek: Int
    let rightCheek: Int
    let eyeArea: Int
    let chin: Int
    
    static let empty = RegionScores(
        tZone: 0, leftCheek: 0, rightCheek: 0, eyeArea: 0, chin: 0
    )
}

// MARK: - Skin Analysis Result
struct SkinAnalysis: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let skinType: SkinType
    let skinAge: Int
    let overallScore: Int
    let issues: IssueScores
    let regions: RegionScores
    let recommendations: [String]
    let analyzedAt: Date
    
    init(
        id: UUID = UUID(),
        skinType: SkinType,
        skinAge: Int,
        overallScore: Int,
        issues: IssueScores,
        regions: RegionScores,
        recommendations: [String],
        analyzedAt: Date = Date()
    ) {
        self.id = id
        self.skinType = skinType
        self.skinAge = skinAge
        self.overallScore = overallScore
        self.issues = issues
        self.regions = regions
        self.recommendations = recommendations
        self.analyzedAt = analyzedAt
    }
    
    // Mock for previews
    static let mock = SkinAnalysis(
        skinType: .combination,
        skinAge: 26,
        overallScore: 75,
        issues: IssueScores(
            spots: 3, acne: 4, pores: 5, wrinkles: 2,
            redness: 3, evenness: 4, texture: 3
        ),
        regions: RegionScores(
            tZone: 68, leftCheek: 78, rightCheek: 76, eyeArea: 72, chin: 70
        ),
        recommendations: [
            "建议使用温和的水杨酸产品控制T区油脂",
            "加强保湿，选择含透明质酸的产品",
            "日常使用SPF30+防晒霜"
        ]
    )
}

// MARK: - SwiftData Model
@Model
final class SkinAnalysisRecord {
    @Attribute(.unique) var id: UUID
    var skinType: String
    var skinAge: Int
    var overallScore: Int
    var issuesData: Data?
    var regionsData: Data?
    var recommendations: [String]
    var analyzedAt: Date
    var photoPath: String?
    
    init(from analysis: SkinAnalysis, photoPath: String? = nil) {
        self.id = analysis.id
        self.skinType = analysis.skinType.rawValue
        self.skinAge = analysis.skinAge
        self.overallScore = analysis.overallScore
        self.issuesData = try? JSONEncoder().encode(analysis.issues)
        self.regionsData = try? JSONEncoder().encode(analysis.regions)
        self.recommendations = analysis.recommendations
        self.analyzedAt = analysis.analyzedAt
        self.photoPath = photoPath
    }
    
    func toAnalysis() -> SkinAnalysis? {
        guard let skinType = SkinType(rawValue: skinType) else { return nil }
        
        let issues = issuesData.flatMap { try? JSONDecoder().decode(IssueScores.self, from: $0) } ?? .empty
        let regions = regionsData.flatMap { try? JSONDecoder().decode(RegionScores.self, from: $0) } ?? .empty
        
        return SkinAnalysis(
            id: id,
            skinType: skinType,
            skinAge: skinAge,
            overallScore: overallScore,
            issues: issues,
            regions: regions,
            recommendations: recommendations,
            analyzedAt: analyzedAt
        )
    }
}
