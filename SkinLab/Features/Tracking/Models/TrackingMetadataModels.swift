import Foundation
import SwiftData
import AVFoundation

// MARK: - Photo Standardization Metadata
struct PhotoStandardizationMetadata: Codable, Sendable {
    let capturedAt: Date
    let cameraPosition: CameraPosition
    let captureSource: CaptureSource
    let lighting: LightingRating
    let faceDetected: Bool
    let yawDegrees: Double
    let pitchDegrees: Double
    let rollDegrees: Double
    let distance: DistanceRating
    let isReady: Bool
    let suggestions: [String]
    let userOverride: UserOverride?

    enum CameraPosition: String, Codable, Sendable {
        case front
        case back
        case unknown

        init(from position: AVCaptureDevice.Position) {
            switch position {
            case .front:
                self = .front
            case .back:
                self = .back
            @unknown default:
                self = .unknown
            }
        }
    }

    enum CaptureSource: String, Codable, Sendable {
        case camera
        case library
    }

    enum LightingRating: String, Codable, Sendable {
        case tooDark
        case slightlyDark
        case optimal
        case slightlyBright
        case tooBright

        init(from condition: LightingCondition) {
            switch condition {
            case .tooDark: self = .tooDark
            case .slightlyDark: self = .slightlyDark
            case .optimal: self = .optimal
            case .slightlyBright: self = .slightlyBright
            case .tooBright: self = .tooBright
            case .unknown: self = .optimal
            }
        }
    }

    enum DistanceRating: String, Codable, Sendable {
        case tooFar
        case slightlyFar
        case optimal
        case slightlyClose
        case tooClose

        init(from condition: DistanceCondition) {
            switch condition {
            case .tooFar: self = .tooFar
            case .slightlyFar: self = .slightlyFar
            case .optimal: self = .optimal
            case .slightlyClose: self = .slightlyClose
            case .tooClose: self = .tooClose
            case .unknown: self = .optimal
            }
        }
    }

    enum UserOverride: String, Codable, Sendable {
        case userConfirmedGood  // User says "photo is fine despite conditions"
        case userFlaggedIssue   // User says "photo is not standard"
    }

    /// Create from CameraService.PhotoCondition
    init(
        capturedAt: Date,
        cameraPosition: CameraPosition,
        captureSource: CaptureSource = .camera,
        lighting: LightingRating,
        faceDetected: Bool,
        yawDegrees: Double,
        pitchDegrees: Double,
        rollDegrees: Double,
        distance: DistanceRating,
        isReady: Bool,
        suggestions: [String],
        userOverride: UserOverride? = nil
    ) {
        self.capturedAt = capturedAt
        self.cameraPosition = cameraPosition
        self.captureSource = captureSource
        self.lighting = lighting
        self.faceDetected = faceDetected
        self.yawDegrees = yawDegrees
        self.pitchDegrees = pitchDegrees
        self.rollDegrees = rollDegrees
        self.distance = distance
        self.isReady = isReady
        self.suggestions = suggestions
        self.userOverride = userOverride
    }
}

// MARK: - Lifestyle Factors
struct LifestyleFactors: Codable, Sendable {
    let sleepHours: Double?          // e.g., 6.5, 7.0, 8.5
    let stressLevel: Int?            // 1-5 scale
    let waterIntakeLevel: Int?       // 1-5 scale
    let alcoholConsumed: Bool?
    let exerciseMinutes: Int?        // minutes of exercise
    let sunExposureLevel: Int?       // 1-5 scale
    let dietNotes: String?           // optional short notes
    let cyclePhase: CyclePhase?      // menstrual cycle phase
    let sceneContext: SkinScenario?  // current skincare scenario context

    enum StressLevel: Int, Codable, Sendable {
        case veryLow = 1
        case low = 2
        case neutral = 3
        case high = 4
        case veryHigh = 5
    }

    enum CyclePhase: String, Codable, Sendable {
        case menstrual
        case follicular
        case ovulation
        case luteal
        case notApplicable
        case preferNotToSay
    }

    /// Default initializer with all optional fields
    init(
        sleepHours: Double? = nil,
        stressLevel: Int? = nil,
        waterIntakeLevel: Int? = nil,
        alcoholConsumed: Bool? = nil,
        exerciseMinutes: Int? = nil,
        sunExposureLevel: Int? = nil,
        dietNotes: String? = nil,
        cyclePhase: CyclePhase? = nil,
        sceneContext: SkinScenario? = nil
    ) {
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
        self.waterIntakeLevel = waterIntakeLevel
        self.alcoholConsumed = alcoholConsumed
        self.exerciseMinutes = exerciseMinutes
        self.sunExposureLevel = sunExposureLevel
        self.dietNotes = dietNotes
        self.cyclePhase = cyclePhase
        self.sceneContext = sceneContext
    }
}

// MARK: - Reliability Metadata
struct ReliabilityMetadata: Codable, Sendable {
    let score: Double                // 0-1
    let level: ReliabilityLevel
    let reasons: [ReliabilityReason]
    let computedAt: Date

    enum ReliabilityLevel: String, Codable, Sendable {
        case high
        case medium
        case low
    }

    enum ReliabilityReason: String, Codable, Sendable {
        case lowLight
        case highLight
        case angleOff
        case distanceOff
        case noFaceDetected
        case missingLiveConditions  // From library pick
        case longInterval           // Check-in was late
        case userFlaggedIssue
        case lowAnalysisConfidence
        case inconsistentCameraPosition
    }

    init(
        score: Double,
        level: ReliabilityLevel,
        reasons: [ReliabilityReason],
        computedAt: Date = Date()
    ) {
        self.score = score
        self.level = level
        self.reasons = reasons
        self.computedAt = computedAt
    }

    /// Human-readable reason descriptions
    func reasonDescriptions() -> [(reason: ReliabilityReason, description: String)] {
        return reasons.map { reason in
            let description: String
            switch reason {
            case .lowLight:
                description = "光线不足"
            case .highLight:
                description = "光线过强"
            case .angleOff:
                description = "角度偏差"
            case .distanceOff:
                description = "距离不合适"
            case .noFaceDetected:
                description = "未检测到面部"
            case .missingLiveConditions:
                description = "从相册选择"
            case .longInterval:
                description = "打卡延迟"
            case .userFlaggedIssue:
                description = "用户标记"
            case .lowAnalysisConfidence:
                description = "AI分析置信度低"
            case .inconsistentCameraPosition:
                description = "摄像头位置不一致"
            }
            return (reason, description)
        }
    }
}

// MARK: - Timeline Display Policy
struct TimelineDisplayPolicy: Codable, Sendable {
    let defaultMode: TimelineMode
    let excludedCount: Int
    let excludedRatio: Double
    let hasReliableAlternative: Bool

    enum TimelineMode: String, Codable, Sendable {
        case all
        case reliable
    }

    init(
        allCount: Int,
        reliableCount: Int
    ) {
        let excludedCount = allCount - reliableCount
        let excludedRatio = Double(excludedCount) / Double(max(allCount, 1))

        self.excludedCount = excludedCount
        self.excludedRatio = excludedRatio
        self.hasReliableAlternative = reliableCount > 0

        // Default to reliable if meaningful exclusions
        if excludedCount >= 2 || excludedRatio > 0.20 {
            self.defaultMode = .reliable
        } else {
            self.defaultMode = .all
        }
    }
}

// MARK: - Lifestyle Correlation Insight
struct LifestyleCorrelationInsight: Codable, Identifiable, Sendable {
    let id: UUID
    let factor: LifestyleFactorKey
    let targetMetric: String          // e.g., "痘痘", "泛红", "综合评分"
    let correlation: Double           // -1 to 1
    let direction: CorrelationDirection
    let sampleCount: Int
    let confidence: ConfidenceScore
    let interpretation: String        // Non-causal wording

    enum LifestyleFactorKey: String, Codable, Sendable {
        case sleepHours
        case stressLevel
        case waterIntakeLevel
        case alcohol
        case exerciseMinutes
        case sunExposureLevel
        // Weather factors
        case humidity
        case uvIndex
        case airQuality

        /// Display label for the factor
        var label: String {
            switch self {
            case .sleepHours: return "睡眠时间"
            case .stressLevel: return "压力水平"
            case .waterIntakeLevel: return "饮水量"
            case .alcohol: return "饮酒"
            case .exerciseMinutes: return "运动"
            case .sunExposureLevel: return "日晒"
            case .humidity: return "湿度"
            case .uvIndex: return "紫外线"
            case .airQuality: return "空气质量"
            }
        }

        /// SF Symbol icon for the factor
        var icon: String {
            switch self {
            case .sleepHours: return "moon.zzz.fill"
            case .stressLevel: return "brain.head.profile"
            case .waterIntakeLevel: return "drop.fill"
            case .alcohol: return "wineglass.fill"
            case .exerciseMinutes: return "figure.run"
            case .sunExposureLevel: return "sun.max.fill"
            case .humidity: return "humidity.fill"
            case .uvIndex: return "sun.max.trianglebadge.exclamationmark"
            case .airQuality: return "aqi.medium"
            }
        }
    }

    enum CorrelationDirection: String, Codable, Sendable {
        case positive    // More of factor → better metric
        case negative    // More of factor → worse metric
        case none
    }

    init(
        id: UUID = UUID(),
        factor: LifestyleFactorKey,
        targetMetric: String,
        correlation: Double,
        sampleCount: Int,
        confidence: ConfidenceScore,
        interpretation: String
    ) {
        self.id = id
        self.factor = factor
        self.targetMetric = targetMetric
        self.correlation = correlation
        self.direction = Self.direction(from: correlation)
        self.sampleCount = sampleCount
        self.confidence = confidence
        self.interpretation = interpretation
    }

    private static func direction(from correlation: Double) -> CorrelationDirection {
        let threshold = 0.3
        if correlation > threshold {
            return .positive
        } else if correlation < -threshold {
            return .negative
        } else {
            return .none
        }
    }
}
