import Foundation
import SwiftData

/// Scores the reliability of individual check-ins based on photo conditions,
/// analysis confidence, and timing consistency
struct ReliabilityScorer {

    /// Generate reliability metadata for a check-in
    func score(
        checkIn: CheckIn,
        analysis: SkinAnalysis?,
        session: TrackingSession,
        expectedDay: Int,
        cameraPositionConsistency: Bool = true
    ) -> ReliabilityMetadata {
        var reasons: [ReliabilityMetadata.ReliabilityReason] = []
        var score: Double = 1.0

        // 1. Check photo standardization
        if let photoMeta = checkIn.photoStandardization {
            // Lighting check (weight: 0.25)
            if photoMeta.lighting == .tooDark {
                reasons.append(.lowLight)
                score -= 0.25
            } else if photoMeta.lighting == .tooBright {
                reasons.append(.highLight)
                score -= 0.25
            } else if photoMeta.lighting == .slightlyDark || photoMeta.lighting == .slightlyBright {
                score -= 0.10
            }

            // Face angle check
            let yawAbs = abs(photoMeta.yawDegrees)
            let pitchAbs = abs(photoMeta.pitchDegrees)
            let rollAbs = abs(photoMeta.rollDegrees)

            if yawAbs > 20 || pitchAbs > 20 || rollAbs > 15 {
                reasons.append(.angleOff)
                score -= 0.20
            } else if yawAbs > 15 || pitchAbs > 15 || rollAbs > 10 {
                score -= 0.05
            }

            // Distance check
            if photoMeta.distance == .tooFar || photoMeta.distance == .tooClose {
                reasons.append(.distanceOff)
                score -= 0.15
            } else if photoMeta.distance == .slightlyFar || photoMeta.distance == .slightlyClose {
                score -= 0.05
            }

            // Centering check
            switch photoMeta.centering {
            case .tooLeft, .tooRight, .tooHigh, .tooLow:
                reasons.append(.centeringOff)
                score -= 0.10
            case .optimal:
                break
            }

            // Sharpness check
            if photoMeta.sharpness == .blurry {
                reasons.append(.blurry)
                score -= 0.20
            } else if photoMeta.sharpness == .slightlyBlurry {
                score -= 0.05
            }

            // Face detection
            if !photoMeta.faceDetected {
                reasons.append(.noFaceDetected)
                score -= 0.20
            }

            // User override
            if photoMeta.userOverride == .userFlaggedIssue {
                reasons.append(.userFlaggedIssue)
                score -= 0.10
            }

            // Library photo
            if photoMeta.captureSource == .library {
                reasons.append(.missingLiveConditions)
                score -= 0.15
            }

            // Camera position
            if !cameraPositionConsistency {
                reasons.append(.inconsistentCameraPosition)
                score -= 0.10
            }
        } else {
            reasons.append(.missingLiveConditions)
            score -= 0.30
        }

        // 2. Analysis confidence
        if let analysis = analysis {
            let confidence = analysis.confidenceScore
            if confidence < 50 {
                reasons.append(.lowAnalysisConfidence)
                score -= 0.20
            } else if confidence < 70 {
                score -= 0.10
            }
        }

        // 3. Timing - compute from captureDate, not day integer
        // Expected date for this checkpoint = session.startDate + expectedDay days
        let expectedDate = Calendar.current.date(byAdding: .day, value: expectedDay, to: session.startDate) ?? checkIn.captureDate
        let daysOffTarget = Calendar.current.dateComponents([.day], from: expectedDate, to: checkIn.captureDate).day ?? 0
        let dayDiff = abs(daysOffTarget)

        if dayDiff > 3 {
            reasons.append(.longInterval)
            score -= 0.10
        } else if dayDiff > 1 {
            score -= 0.05
        }

        score = max(0, min(1, score))

        let level: ReliabilityMetadata.ReliabilityLevel
        if score >= 0.7 {
            level = .high
        } else if score >= 0.4 {
            level = .medium
        } else {
            level = .low
        }

        return ReliabilityMetadata(score: score, level: level, reasons: reasons)
    }

    /// Score all check-ins
    func scoreAll(
        checkIns: [CheckIn],
        analyses: [UUID: SkinAnalysis],
        session: TrackingSession
    ) -> [UUID: ReliabilityMetadata] {
        var result: [UUID: ReliabilityMetadata] = [:]

        let positionCounts = Dictionary(grouping: checkIns.compactMap { $0.photoStandardization?.cameraPosition },
                                       by: { $0 })
            .mapValues { $0.count }
        let commonPosition = positionCounts.max(by: { $0.value < $1.value })?.key

        for checkIn in checkIns {
            let expectedDay = session.expectedDay(for: checkIn.day)

            let positionConsistent: Bool
            if let commonPosition = commonPosition,
               let checkInPosition = checkIn.photoStandardization?.cameraPosition {
                positionConsistent = (checkInPosition == commonPosition)
            } else {
                positionConsistent = true
            }

            let analysis = checkIn.analysisId.flatMap { analyses[$0] }
            result[checkIn.id] = score(
                checkIn: checkIn,
                analysis: analysis,
                session: session,
                expectedDay: expectedDay,
                cameraPositionConsistency: positionConsistent
            )
        }

        return result
    }
}

extension TrackingSession {
    func expectedDay(for day: Int) -> Int {
        return TrackingConstants.checkInDays.min(by: { abs($0 - day) < abs($1 - day) }) ?? day
    }
}
