# fn-3.1 Fix lifestyle correlation delta computation

## Description
Fix the lifestyle correlation feature by replacing the placeholder delta (0) with real computed values from timeline data. Currently, `LifestyleCorrelationAnalyzer.buildConsecutivePairs()` uses `delta = 0.0 // Placeholder`, which makes all Spearman correlations trend toward 0, resulting in no insights ever appearing for users.

## Changes Required

### File: `SkinLab/Features/Tracking/Services/LifestyleCorrelationAnalyzer.swift`

1. **Build score lookup** in `analyze()` method:
   ```swift
   let scoreByCheckInId: [UUID: ScorePoint] = Dictionary(
       uniqueKeysWithValues: timeline.map { ($0.checkInId, $0) }
   )
   ```

2. **Update `buildConsecutivePairs()` signature**:
   - Change from accepting `analyses: [UUID: SkinAnalysis]`
   - To accepting `scoreByCheckInId: [UUID: ScorePoint]`

3. **Compute real delta**:
   ```swift
   let delta = Double(nextPoint.overallScore - currentPoint.overallScore)
   ```

4. **Add missing alcohol factor**:
   ```swift
   let factors: [LifestyleCorrelationInsight.LifestyleFactorKey] = [
       .sleepHours, .stressLevel, .waterIntakeLevel, .alcohol,
       .exerciseMinutes, .sunExposureLevel
   ]
   ```

5. **Optional reliability filtering**:
   ```swift
   if let rel = reliability[pair.checkIn.id], rel.score < 0.5 {
       continue  // Skip low-reliability pairs
   }
   ```

## Key Context

- **Current issue**: Line with `delta = 0.0 // Placeholder` makes correlation non-functional
- **Location**: `LifestyleCorrelationAnalyzer.swift`, `buildConsecutivePairs()` method
- **Impact**: Without this fix, lifestyle insights never appear regardless of data quality
- **User-facing symptom**: Reports show "暂无足够数据" even when user filled in lifestyle data

## Acceptance
- [ ] Delta computed from actual timeline score changes
- [ ] Lifestyle correlation insights appear in reports when data exists
- [ ] Alcohol factor included in correlation analysis
- [ ] Optional: Low-reliability pairs excluded from correlation
- [ ] Build succeeds with no compiler errors

## Done summary
- What changed
  - LifestyleCorrelationAnalyzer now computes real deltas from timeline score changes
  - scoreByCheckInId lookup built from timeline using checkInId (not day)
  - Alcohol factor added to correlation analysis
  - Low-reliability pairs (score < 0.5) filtered out from correlation

- Why
  - Placeholder delta (0) made all correlations trend to 0, breaking lifestyle insights
  - Alcohol factor was missing from factors list
  - Low-reliability data points reduce correlation quality

- Verification
  - Build succeeded with no compiler errors
  - Delta now computed as: nextScore.overallScore - currentScore.overallScore
  - All 6 lifestyle factors now included in analysis

- Follow-ups
  - Need integration test to verify insights appear in reports
  - Consider adding unit tests for edge cases (single data point, missing scores)
## Evidence
- Commits: 0c3026383610211738972f1ea418ee3ce4e250c7
- Tests: xcodebuild -scheme SkinLab -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
- PRs: