# fn-3.2 Implement Day 0 baseline from analysis

## Description
Implement the missing "Day 0 baseline" flow where users can start tracking directly from an analysis result. Currently, tapping "立即开始追踪" only opens a blank TrackingView without creating a session or baseline check-in.

## Changes Required

### 1. Create AnalysisRunResult Structure

**File**: New struct in `AnalysisResultViewModel.swift` or shared location

```swift
struct AnalysisRunResult: Sendable {
    let analysis: SkinAnalysis
    let analysisId: UUID
    let photoPath: String?
    let standardization: PhotoStandardizationMetadata?
}
```

### 2. Persist Analysis in AnalysisView

**File**: `SkinLab/Features/Analysis/Views/AnalysisView.swift`

- Save photo to documents directory after successful analysis
- Create and insert `SkinAnalysisRecord` with photoPath
- Return `AnalysisRunResult` instead of just `SkinAnalysis`

### 3. Implement startTrackingBaseline() Method

**File**: `SkinLab/Features/Analysis/ViewModels/AnalysisResultViewModel.swift`

```swift
@MainActor
func startTrackingBaseline(
    analysisRecordId: UUID,
    photoPath: String?,
    standardization: PhotoStandardizationMetadata?,
    defaultTargetProducts: [String] = [],
    notes: String? = nil
) throws -> TrackingSession
```

Logic:
- Check for existing active session
- Create new `TrackingSession` if none exists
- Add Day 0 `CheckIn` with:
  - `day: 0`
  - `analysisId: analysisRecordId`
  - `photoPath: photoPath`
  - `photoStandardization: standardization`
  - `lifestyle: nil` (Day 0 has no lifestyle data)
  - `reliability: nil` (will be computed later)
- Save to SwiftData

### 4. Update Navigation in AnalysisResultView

**File**: `SkinLab/Features/Analysis/Views/AnalysisResultView.swift`

- Accept `AnalysisRunResult` instead of `SkinAnalysis`
- In "立即开始追踪" button action:
  - Call `viewModel.startTrackingBaseline()`
  - On success, navigate to `TrackingDetailView(session:)`

## Key Context

- **Current issue**: `AnalysisResultView.swift` line ~650 has button that opens blank TrackingView
- **Analysis persistence**: Similar pattern exists in tracking flow - look for `SkinAnalysisRecord` usage
- **Session creation pattern**: `TrackingView.swift` has `createSession()` method to reference
- **User expectation**: UI says "将本次分析作为第0天基准" but doesn't deliver

## Acceptance
- [ ] AnalysisRunResult struct created and used
- [ ] Analysis persisted with photoPath after AI analysis
- [ ] startTrackingBaseline() creates session and Day 0 check-in
- [ ] Navigation goes to TrackingDetailView with created session
- [ ] Timeline shows Day 0 as completed node
- [ ] Standardization metadata included in Day 0 check-in

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
