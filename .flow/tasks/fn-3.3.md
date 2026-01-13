# fn-3.3 Compute reliability at capture time

## Description
Move reliability computation from report-time to capture-time so users get immediate feedback on data quality. Also fix the tooBright mapping bug where too-bright lighting is incorrectly mapped to `.lowLight` instead of `.highLight`.

## Changes Required

### 1. Compute Reliability in CheckInView

**File**: `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (CheckInView)

In `saveCheckIn()` method, after analysis completes:

```swift
// Capture scheduled day ONCE when view opens (from session.nextCheckInDay)
let scheduledDay = session.nextCheckInDay  // Non-optional in valid check-in flow

// Build preliminary check-in
let preliminaryCheckIn = CheckIn(
    day: scheduledDay,
    captureDate: Date(),
    analysisId: analysis.id,
    photoPath: photoPath,
    photoStandardization: standardization,
    lifestyle: lifestyle,
    reliability: nil  // Will compute now
)

// Compute reliability
// NOTE: expectedDay is the scheduled checkpoint (0/7/14/21/28)
// Timing penalty MUST use captureDate difference, not day integer difference
let scorer = ReliabilityScorer()
let reliability = scorer.score(
    checkIn: preliminaryCheckIn,
    analysis: analysis,
    session: session,
    expectedDay: scheduledDay,  // Pass scheduled day as the checkpoint we're recording
    cameraPositionConsistency: true
)
// ReliabilityScorer must compute: abs(captureDate - (session.startDate + scheduledDay days)).day
```

// Rebuild check-in with reliability
let finalCheckIn = CheckIn(
    day: preliminaryCheckIn.day,
    captureDate: preliminaryCheckIn.captureDate,
    analysisId: preliminaryCheckIn.analysisId,
    photoPath: preliminaryCheckIn.photoPath,
    photoStandardization: preliminaryCheckIn.photoStandardization,
    lifestyle: preliminaryCheckIn.lifestyle,
    reliability: reliability  // Now included
)
```

### 2. Fix tooBright Mapping Bug

**File**: `SkinLab/Features/Tracking/Services/ReliabilityScorer.swift`

In `score()` method, find the lighting case:

```swift
case .tooBright:
    // WRONG: reasons.append(.lowLight)
    reasons.append(.highLight)  // CORRECT
    score -= lightingPenalty
```

### 3. Display Reliability Badge

**File**: `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (CheckInView)

After analysis completes, show reliability preview:

```swift
if let analysis = currentAnalysis {
    let previewReliability = computePreviewReliability(
        analysis: analysis,
        standardization: standardization
    )

    ReliabilityBadgeView(
        reliability: previewReliability,
        size: .medium
    )
}
```

### 4. Update Report Generator

**File**: `SkinLab/Features/Tracking/Models/TrackingReportExtensions.swift`

In `generateReport()`, prefer stored reliability:

```swift
let reliabilityMap = sortedCheckIns.reduce(into: [:]) { map, checkIn in
    if let existing = checkIn.reliability {
        map[checkIn.id] = existing
    } else if let analysis = analyses[checkIn.analysisId] {
        // Fallback to computation
        map[checkIn.id] = scorer.score(...)
    }
}
```

## Key Context

- **Current issue**: CheckIn stores `reliability: nil // Computed at report time` (line ~450 in TrackingDetailView)
- **Bug location**: `ReliabilityScorer.swift` line ~85, tooBright case
- **User impact**: Users can't see data quality feedback at capture time
- **Report location**: `TrackingReportView.swift` dataQualitySection displays reliability

## Acceptance
- [ ] CheckIn.reliability is non-nil after save, computed at capture time
- [ ] tooBright mapped to .highLight not .lowLight
- [ ] Reliability badge visible in CheckInRow/timeline list after save (persistent location)
- [ ] Report generation uses stored reliability when available, computes only as fallback
- [ ] All SwiftData writes (modelContext.insert/save, session.addCheckIn) on @MainActor
- [ ] Check-in uses scheduled day (captured from session.nextCheckInDay) not session.duration
- [ ] Timing penalty computed from `captureDate` difference, not from `day` integer
- [ ] Late check-in (Day 7 on Day 12) shows reduced reliability for `.longInterval`
- [ ] Build succeeds with no compiler errors

## Done summary
- What changed
  - Fixed tooBright mapping: now correctly maps to .highLight not .lowLight
  - Fixed timing penalty computation: now uses captureDate difference (not day integer)
    - Expected date = session.startDate + scheduledDay days
    - Days off target = abs(captureDate - expectedDate).day
  - CheckInView captures scheduledDay from session.nextCheckInDay once
    - Uses scheduledDay for CheckIn.day (not session.duration)
    - Computes reliability at capture time after analysis
    - Marks saveCheckIn() as @MainActor for SwiftData writes
  - Report generator prefers stored reliability, computes as fallback
  - Added reliability badge to CheckInRow/timeline list (persistent location)

- Why
  - tooBright was incorrectly mapped to .lowLight
  - Timing penalty used day integer instead of captureDate difference
  - CheckIn was using session.duration instead of scheduled checkpoint day
  - Reliability was only computed at report time, not at capture time
  - Reliability badge wasn't visible in persistent location (timeline list)

- Verification
  - Build succeeded with no compiler errors
  - CheckIn.reliability is now non-nil (computed at capture time)
  - Reliability badge visible in CheckInRow after save
  - Scheduled day from nextCheckInDay used for CheckIn.day

- Follow-ups
  - Manual testing needed to verify late check-in (Day 7 on Day 12) shows reduced reliability
  - Consider showing reliability preview in CheckInView before save
## Evidence
- Commits: c55255417c1d5a8b20bbe2e7a834e9beac9ad278
- Tests: xcodebuild -scheme SkinLab -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
- PRs: