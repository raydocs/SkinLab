# Fix Photo Standardization and Lifestyle Correlation Integration

## Overview

Fix three critical integration gaps that make recently implemented features feel incomplete to users:

1. **Lifestyle correlation is non-functional** - Delta placeholder (0) makes correlation always return 0, so users never see insights
2. **Day 0 baseline flow is broken** - "立即开始追踪" doesn't create actual session or baseline check-in
3. **Photo standardization value is invisible** - Metadata captured but not surfaced to users

## Scope

### In Scope
- Fix lifestyle delta computation to enable real correlation insights
- Implement true Day 0 baseline creation from analysis results
- Compute and display reliability at capture time
- Fix reliability scoring bugs (tooBright mapping)
- Make lifestyle inputs truly optional (remove auto-filled defaults)

### Out of Scope
- UI redesign or visual enhancements
- New correlation metrics beyond overallScore delta
- Advanced session management (session merging, etc.)
- Data migrations for existing check-ins

## Approach

### Critical Implementation Rules (ALL tasks must follow)

1. **Always use checkInId for joins, never day**
   - Delta computation: use `ScorePoint.checkInId` to lookup scores
   - Reliability filtering: use `point.checkInId` not `point.day`
   - Days are not unique; check-in UUIDs are stable identifiers

2. **CheckIn.day semantics + timing penalty source**
   - `CheckIn.day` represents the **scheduled checkpoint day** (0/7/14/21/28) for UI + report alignment
   - Timing penalties must be computed from **`captureDate`** vs expected date, NOT from `day` vs `expectedDay`
   - Expected date = `session.startDate + scheduledDay days`
   - Late check-ins penalized based on actual date difference: `abs(captureDate - expectedDate).day`
   - This ensures a "Day 7" check-in taken on Day 12 still gets timing penalty

3. **Use scheduled day when creating check-ins**
   - Capture `scheduledDay` once when opening CheckInView (from `session.nextCheckInDay`)
   - Use this `scheduledDay` as `CheckIn.day` (NOT `session.duration`)
   - Pass this `scheduledDay` as `expectedDay` to `ReliabilityScorer.score()`
   - Guard unwrap `nextCheckInDay`; if nil, show error and don't proceed

4. **nextCheckInDay must enable late check-ins**
   - `TrackingSession.nextCheckInDay` must return the next **due** uncompleted checkpoint (where `scheduledDay <= duration`)
   - This ensures late check-ins (e.g., Day 7 on Day 12) are recordable and penalizable
   - If no checkpoints are due, UI should show "下次打卡 Day X" as non-actionable
   - DO NOT skip past missed checkpoints (they must be recordable for data completeness)

5. **SwiftData writes on MainActor only**
   - All `modelContext.insert/save` and `session.addCheckIn` must be on `@MainActor`
   - Mark `CheckInView.saveCheckIn()` as `@MainActor`

6. **Reliability badge in persistent location**
   - Badge must appear in `CheckInRow`/timeline list (visible after save)
   - NOT just in dismissible CheckInView (users won't see it)

7. **Active session conflict: refuse, don't mutate**
   - If active session exists when creating Day 0: show error, don't auto-modify
   - Prevents corrupting user's existing tracking data

8. **Optional lifestyle: opt-in + explicit set**
   - "Real user-provided data" = user toggled on AND at least one field explicitly set
   - UI defaults are fine for controls, but never persist defaults to model

### Task 1: Fix Lifestyle Correlation Delta (fn-3.1)
**File**: `LifestyleCorrelationAnalyzer.swift`

Current state: `buildConsecutivePairs()` uses `delta = 0.0 // Placeholder`

Changes:
1. Build `scoreByCheckInId` lookup from timeline
2. Compute real delta: `nextPoint.overallScore - currentPoint.overallScore`
3. Update method signature to accept `scoreByCheckInId` instead of `analyses`
4. Add missing `.alcohol` factor to factors list
5. Optional: Filter out low-reliability pairs

**CRITICAL**: Use `checkInId` for all lookups, never join by `day`

**Impact**: Immediately makes lifestyle insights functional

### Task 2: Implement Day 0 Baseline Flow (fn-3.2)
**Files**: `AnalysisView.swift`, `AnalysisResultView.swift`, `AnalysisResultViewModel.swift`

Current state: "立即开始追踪" only opens blank TrackingView

Changes:
1. Create `AnalysisRunResult` struct to carry analysis + metadata
2. Persist analysis with photoPath in `AnalysisView`
3. Implement `startTrackingBaseline()` in ViewModel:
   - Check for active session
   - Create TrackingSession if needed
   - Add Day 0 CheckIn with analysisId, photoPath, standardization
4. Update navigation to go to TrackingDetailView with created session

**Impact**: Completes the analysis→tracking funnel

### Task 3: Compute Reliability at Capture Time (fn-3.3)
**Files**: `TrackingDetailView.swift` (CheckInView), `ReliabilityScorer.swift`

Current state: Reliability only computed at report time, tooBright mapped incorrectly

Changes:
1. In `CheckInView.saveCheckIn()`: compute reliability after analysis
2. Pass reliability to CheckIn constructor
3. Fix `ReliabilityScorer.score()`: map tooBright to `.highLight` not `.lowLight`
4. Display reliability badge in CheckInView after analysis completes

**Impact**: Users see data quality feedback immediately

### Task 4: Make Lifestyle Truly Optional (fn-3.4)
**Files**: `TrackingDetailView.swift` (CheckInView)

Current state: sleepHours defaults to 7.0, making lifestyle always save

Changes:
1. Create `LifestyleDraft` struct with all optional fields
2. Add `@State private var includeLifestyle = false` toggle
3. Only show lifestyle inputs when toggle is on
4. Only save LifestyleFactors if user opted in AND provided data

**Impact**: "Optional" becomes meaningful, improves correlation data quality

## Risks / Dependencies

### Risks
1. **SwiftData migration** - Adding new fields to existing models may require migration
   - Mitigation: Use optional fields for additive changes

2. **Analysis persistence timing** - Deciding when to persist affects UX
   - Mitigation: Persist immediately after successful AI analysis

3. **Active session conflicts** - User may have multiple active sessions
   - Mitigation: **Refuse with clear error message if active session exists** (safe default for MVP)

4. **ID-vs-day join bugs** - Current code incorrectly joins by day in several places
   - Mitigation: Enforce `checkInId` joins everywhere (see Critical Implementation Rules)

5. **MainActor violations** - SwiftData writes not properly guarded
   - Mitigation: Mark `CheckInView.saveCheckIn()` as `@MainActor`, ensure all SwiftData writes on main thread

### Edge Cases (Must Handle)
1. **No lifestyle data exists** → 3.1 returns `[]`, report UI handles empty insights
2. **Analysis persistence fails** → Fail fast with user-visible error, don't create partial session/check-in
3. **Active session already exists** → Show error, refuse to auto-modify existing session
4. **Timeline has only 1 data point** → Correlation analyzer returns `[]` (need min 2 points)
5. **Multiple check-ins same day** → Use scheduled day, not duration (prevents drift)
6. **Library photo reliability** → Current scoring double-penalizes (missing live conditions + no face detected); this is acceptable for data quality focus
7. **Late check-in (Day 7 on Day 12)** → Timing penalty computed from `captureDate` difference, NOT from `day` integer (see Critical Implementation Rule #2)

### Dependencies
- fn-3.1 should be completed first (unlocks lifestyle feature)
- fn-3.2 depends on having persistent analysis IDs
- fn-3.3 and fn-3.4 can proceed in parallel after fn-3.1

## Acceptance

### Task 1 (fn-3.1) - Fix Lifestyle Delta
- [ ] LifestyleCorrelationAnalyzer computes real deltas from timeline
- [ ] Correlation insights appear in reports when lifestyle data exists
- [ ] Alcohol factor included in correlation analysis
- [ ] Optional: Low-reliability pairs filtered out

### Task 2 (fn-3.2) - Day 0 Baseline
- [ ] Tapping "立即开始追踪" creates TrackingSession
- [ ] Day 0 CheckIn created with analysisId, photoPath, standardization
- [ ] Navigation goes to TrackingDetailView with created session
- [ ] Timeline shows Day 0 as completed

### Task 3 (fn-3.3) - Reliability at Capture
- [ ] CheckIn stores reliability (not nil) computed at save time
- [ ] tooBright mapped to .highLight not .lowLight
- [ ] Reliability badge visible in CheckInRow/timeline list after save (persistent location)
- [ ] Report generation uses stored reliability when available, computes only as fallback
- [ ] All SwiftData writes (modelContext.insert/save, session.addCheckIn) on @MainActor
- [ ] Check-in uses scheduled day (nextCheckInDay) not session.duration
- [ ] Timing penalty computed from `captureDate` difference, not from `day` integer
- [ ] Late check-in (Day 7 on Day 12) is recordable via UI and shows reduced reliability for `.longInterval`
- [ ] nextCheckInDay returns due checkpoints (doesn't skip past missed ones)

### Task 4 (fn-3.4) - Optional Lifestyle
- [ ] Lifestyle inputs hidden by default
- [ ] Toggle to show lifestyle inputs
- [ ] CheckIn.lifestyle is nil when user didn't opt in
- [ ] CheckIn.lifestyle only saved when user opted in AND at least one field explicitly set
- [ ] Coverage percentage reflects true opt-in rate (not artificial 100% from defaults)
- [ ] UI controls may show defaults but never persist defaults to model

## Test Notes

### Unit Tests Needed
```swift
// LifestyleCorrelationAnalyzerTests.swift
func testDeltaComputation_withRealTimeline_returnsNonZero()
func testDeltaComputation_usesCheckInIdNotDay()
func testCorrelation_withPositiveDelta_detectsCorrelation()
func testCorrelation_withLowReliability_filtersOut()
func testTimelineReliable_filtersByCheckInIdNotDay()

// ReliabilityScorerTests.swift
func testTooBright_mappedToHighLightNotLowLight()
func testReliability_usesScheduledDayNotDuration()

// CheckInLifecycleTests.swift
func testOptionalLifestyle_notOptIn_returnsNil()
func testOptionalLifestyle_optInWithDefaults_stillNil()
func testOptionalLifestyle_optInWithExplicitSet_saves()
```

### Integration Tests
1. Create analysis → start tracking → verify Day 0 exists
2. Add lifestyle data to multiple check-ins → verify insights appear
3. Check-in with poor lighting → verify reliability badge shows low

### Manual Test Flow
1. Open app → take photo analysis
2. Tap "立即开始追踪" → should go to tracking detail with Day 0
3. Add check-in with lifestyle data → should see reliability badge
4. Generate report → should see lifestyle insights

## Quick Commands

### Build and Run
```bash
xcodebuild -scheme SkinLab -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Run Specific Tests
```bash
xcodebuild test -scheme SkinLab \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SkinLabTests/LifestyleCorrelationAnalyzerTests
```

### Verify Changes
```bash
# Check lifestyle delta computation
grep -n "delta = 0.0" SkinLab/Features/Tracking/Services/LifestyleCorrelationAnalyzer.swift
# Should be removed or changed to real computation

# Check reliability computation in CheckInView
grep -n "ReliabilityScorer()" SkinLab/Features/Tracking/Views/TrackingDetailView.swift
# Should exist in saveCheckIn()
```

## References

### Files Modified
- `IMPROVEMENT_ROADMAP.md` - Full technical analysis
- `改进路线图-摘要.md` - Chinese executive summary
- `/tmp/claude/-Users-ruirui-Code/Ai-Code-SkinLab/tasks/b460aac.output` - Original RepoPrompt discovery

### Key Code Locations
- `LifestyleCorrelationAnalyzer.swift:~120` - buildConsecutivePairs with delta placeholder
- `AnalysisResultView.swift:~650` - "立即开始追踪" button
- `TrackingDetailView.swift:~450` - CheckInView saveCheckIn()
- `ReliabilityScorer.swift:~85` - tooBright case (wrong mapping)

### Similar Patterns
- Session creation: `TrackingView.swift` createSession() method
- Check-in persistence: `TrackingDetailView.swift` existing save pattern
- Analysis persistence: Look for `SkinAnalysisRecord` usage in HomeView

### External Docs
- SwiftData: https://developer.apple.com/documentation/swiftdata
- SwiftUI Navigation: https://developer.apple.com/documentation/swiftui/navigation
- Spearman Correlation: Statistical method for rank-based correlation
