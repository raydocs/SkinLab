import Foundation
import SwiftData

// MARK: - Tracking Status
enum TrackingStatus: String, Codable, Sendable {
    case active
    case completed
    case abandoned
}

// MARK: - Check In
struct CheckIn: Codable, Identifiable, Sendable {
    let id: UUID
    let sessionId: UUID
    let day: Int
    let captureDate: Date
    let photoPath: String?
    let analysisId: UUID?
    let usedProducts: [String]
    let notes: String?
    let feeling: Feeling?
    
    // MARK: - New Fields for Photo Standardization & Lifestyle
    let photoStandardization: PhotoStandardizationMetadata?
    let lifestyle: LifestyleFactors?
    let reliability: ReliabilityMetadata?
    
    enum Feeling: String, Codable, Sendable {
        case better, same, worse

        var displayName: String {
            switch self {
            case .better: return "变好了"
            case .same: return "差不多"
            case .worse: return "变差了"
            }
        }

        var icon: String {
            switch self {
            case .better: return "arrow.up.circle.fill"
            case .same: return "minus.circle.fill"
            case .worse: return "arrow.down.circle.fill"
            }
        }

        var score: Int {
            switch self {
            case .better: return 1
            case .same: return 0
            case .worse: return -1
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        sessionId: UUID,
        day: Int,
        captureDate: Date = Date(),
        photoPath: String? = nil,
        analysisId: UUID? = nil,
        usedProducts: [String] = [],
        notes: String? = nil,
        feeling: Feeling? = nil,
        photoStandardization: PhotoStandardizationMetadata? = nil,
        lifestyle: LifestyleFactors? = nil,
        reliability: ReliabilityMetadata? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.day = day
        self.captureDate = captureDate
        self.photoPath = photoPath
        self.analysisId = analysisId
        self.usedProducts = usedProducts
        self.notes = notes
        self.feeling = feeling
        self.photoStandardization = photoStandardization
        self.lifestyle = lifestyle
        self.reliability = reliability
    }
}

// MARK: - Tracking Session (SwiftData)
@Model
final class TrackingSession {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var statusRaw: String
    var targetProducts: [String]
    var checkInsData: Data?
    var notes: String?
    
    var status: TrackingStatus {
        get { TrackingStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
    
    var checkIns: [CheckIn] {
        get {
            guard let data = checkInsData else { return [] }
            return (try? JSONDecoder().decode([CheckIn].self, from: data)) ?? []
        }
        set {
            checkInsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var duration: Int {
        let end = endDate ?? Date()
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day ?? 0
    }
    
    var progress: Double {
        min(1.0, Double(duration) / 28.0)
    }
    
    var nextCheckInDay: Int? {
        let checkInDays = [0, 7, 14, 21, 28]
        let completedDays = Set(checkIns.map(\.day))
        return checkInDays.first { !completedDays.contains($0) && $0 >= duration }
    }
    
    init(
        id: UUID = UUID(),
        targetProducts: [String] = []
    ) {
        self.id = id
        self.startDate = Date()
        self.statusRaw = TrackingStatus.active.rawValue
        self.targetProducts = targetProducts
    }
    
    func addCheckIn(_ checkIn: CheckIn) {
        var current = checkIns
        current.append(checkIn)
        checkIns = current
    }
}

// MARK: - Tracking Report
struct TrackingReport: Codable {
    let sessionId: UUID
    let duration: Int
    let checkInCount: Int
    let completionRate: Double
    
    let beforePhotoPath: String?
    let afterPhotoPath: String?
    
    let overallImprovement: Double
    let scoreChange: Int
    let skinAgeChange: Int
    
    let dimensionChanges: [DimensionChange]
    let usedProducts: [ProductUsage]
    let aiSummary: String?
    let recommendations: [String]
    
    struct DimensionChange: Codable {
        let dimension: String
        let beforeScore: Int
        let afterScore: Int
        let improvement: Double
        
        var trend: String {
            if improvement > 5 { return "↑" }
            if improvement < -5 { return "↓" }
            return "→"
        }
    }
    
    struct ProductUsage: Codable {
        let productId: String
        let productName: String
        let usageDays: Int
        let effectiveness: Effectiveness?
        
        enum Effectiveness: String, Codable {
            case effective, neutral, ineffective
        }
    }
}
