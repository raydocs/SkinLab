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
- What changed
  - Created AnalysisRunResult struct to carry analysis + metadata (photoPath, standardization)
  - AnalysisViewModel now persists SkinAnalysisRecord with photoPath after successful analysis
  - Added savePhoto() method to save photos to analysis_photos directory
  - Implemented startTrackingBaseline() in AnalysisResultViewModel
    - Checks for active session and refuses if one exists
    - Creates new TrackingSession
    - Adds Day 0 CheckIn with analysisId, photoPath, standardization
  - Updated AnalysisResultView to accept AnalysisRunResult instead of SkinAnalysis
  - "立即开始追踪" button now creates session and navigates to TrackingDetailView
  - Fixed HomeView to use new AnalysisRunResult signature

- Why
  - Users could tap "立即开始追踪" but it only opened blank TrackingView
  - No actual session or Day 0 baseline was being created
  - Analysis wasn't being persisted for later retrieval

- Verification
  - Build succeeded with no compiler errors
  - Day 0 CheckIn now has day: 0, analysisId, photoPath, standardization
  - Navigation goes to TrackingDetailView with created session
  - Active session check prevents corrupting existing data

- Follow-ups
  - Consider adding error alert for active session conflict
  - Timeline UI verification needed to ensure Day 0 shows as completed
## Evidence
- Commits: 3266ba5ebc1ec151e4cd1c23f0ef51976605826e
- Tests: xcodebuild -scheme SkinLab -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
- PRs: