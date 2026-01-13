# SkinLab Improvement Roadmap
## Architecture Review & Priority Action Plan

**Generated**: 2026-01-13
**Based on**: RepoPrompt context builder analysis (25 files, 74k tokens)
**Focus**: Photo standardization + lifestyle correlation integration completeness

---

## Executive Summary

The SkinLab app has a solid architectural foundation with photo standardization and lifestyle correlation infrastructure in place, but **3 critical gaps** make these features feel incomplete to users:

1. **Lifestyle correlation is non-functional** (delta placeholder = 0)
2. **Day 0 baseline flow is broken** (can't start tracking from analysis)
3. **Photo standardization value is invisible** (captured but not surfaced)

This roadmap prioritizes **maximum user value with minimal implementation time**.

---

## Critical Gaps (User-Facing)

### Gap A: Photo Standardization Exists But Users Can't Feel It

**What users experience:**
- 在 `CameraPreviewView` 里能看到"状态良好/建议"，但拍完之后这套信息就"断了"
- 在分析结果页看到的是 `analysis.imageQuality`，而不是"标准化拍照"的明确反馈闭环

**Root cause:**
- 标准化元数据只在追踪打卡存进 `CheckIn.photoStandardization`
- **分析流捕获了 metadata，但没有持久化，也没有进入任何后续比较/可靠性机制**

**Concrete symptoms:**
- `AnalysisView.swift` 有 `@State capturedStandardization`，但 `.result(let analysis)` 时只传了 `analysis` 到 `AnalysisResultView`，metadata 没带过去、也没存下来
- 报告里虽然有可靠性/标准化，但它只在报告页出现，**没能在拍摄/保存当下给用户反馈**

---

### Gap B: Lifestyle Correlation Feature Is "Dead"

**What users experience:**
- 报告页可能有"生活方式关联"入口，但大概率显示"暂无足够数据"，即使用户每次都填了生活方式

**Root cause:**
- `LifestyleCorrelationAnalyzer.swift` 的 `buildConsecutivePairs(...)` 里 `delta = 0.0 // Placeholder`

**Impact:**
- `deltas` 序列几乎全是 0
- Spearman 相关性基本为 0
- `abs(correlation) >= 0.3` 的阈值过滤会把洞察全部过滤掉
=> **用户会认为这个功能是"摆设/噱头"**

---

### Gap C: Lifestyle "Optional" Is Misleading

**What users experience:**
- UI 标题写"生活因素（可选）"，但因为默认值存在（例如 `sleepHours = 7.0`），用户哪怕不动，也会被保存进模型；报告显示"覆盖率很高"，但并不代表真实记录

**Root cause:**
- `sleepHours` 默认 `7.0`，`stressLevel` 默认 `3`，等于"自动填表"
- `saveCheckIn()` 中 `if sleepHours > 0 ...` 永远成立 → `LifestyleFactors` 基本总是非 nil

**Why it feels untrustworthy:**
- 覆盖率 (`lifestyleDataCoverage`) 被"刷高"，但 correlation 又是 0（因为 delta placeholder）
- **"你说我有很多数据，但你啥也分析不出来？"**

---

## Priority 1: Fix Lifestyle Correlation (Minimal Fix, Maximum Impact)

### Goal
Make lifestyle correlation functional with existing timeline data. No new models, no architecture changes.

### Changes Required

**File:** `SkinLab/Features/Tracking/Services/LifestyleCorrelationAnalyzer.swift`

#### Change 1: Build score lookup from timeline
```swift
// In analyze(...), add:
let scoreByCheckInId: [UUID: ScorePoint] = Dictionary(
    uniqueKeysWithValues: timeline.map { ($0.checkInId, $0) }
)
```

#### Change 2: Fix buildConsecutivePairs to compute real deltas
```swift
private func buildConsecutivePairs(
    checkIns: [CheckIn],
    scoreByCheckInId: [UUID: ScorePoint]
) -> [(checkIn: CheckIn, nextCheckIn: CheckIn, delta: Double)] {
    let sorted = checkIns.sorted { $0.day < $1.day }
    var pairs: [(CheckIn, CheckIn, Double)] = []

    for i in 0..<(sorted.count - 1) {
        let current = sorted[i]
        let next = sorted[i + 1]

        guard
            let currentPoint = scoreByCheckInId[current.id],
            let nextPoint = scoreByCheckInId[next.id]
        else { continue }

        let delta = Double(nextPoint.overallScore - currentPoint.overallScore)
        pairs.append((current, next, delta))
    }
    return pairs
}
```

#### Change 3: Add missing alcohol factor
```swift
let factors: [LifestyleCorrelationInsight.LifestyleFactorKey] = [
    .sleepHours, .stressLevel, .waterIntakeLevel, .alcohol, .exerciseMinutes, .sunExposureLevel
]
```

#### Change 4: Make target metric meaningful
```swift
let targetMetric = "综合评分"
```

#### Optional: Reliability filtering (big trust payoff)
```swift
if let rel = reliability[pair.checkIn.id], rel.score < 0.5 { continue }
```

### Impact
- **立即**把"生活方式关联"从"空功能"变成"能产出结果"
- 对用户来说这是最直观的"你们真的在分析我的数据"的证明
- 改动范围小（几乎只动一个文件）

---

## Priority 2: Implement Real "Day 0 Baseline" Flow

### Goal
When user taps "立即开始追踪" from analysis result, create actual TrackingSession + Day 0 CheckIn with persisted analysis.

### Architecture Decision
**Analysis completion → persist immediately** (recommended for time-to-ship)

### Implementation Steps

#### Step 1: Persist Analysis Results
**File:** `SkinLab/Features/Analysis/Views/AnalysisView.swift`

Add persistence after successful analysis:
```swift
// Save photo to documents
let photoPath = savePhotoToDocuments(capturedImage)

// Create analysis record
let analysisRecord = SkinAnalysisRecord(
    from: analysis,
    photoPath: photoPath
)
modelContext.insert(analysisRecord)
```

#### Step 2: Create Data Structure for Passing Results
```swift
struct AnalysisRunResult: Sendable {
    let analysis: SkinAnalysis
    let analysisId: UUID
    let photoPath: String?
    let standardization: PhotoStandardizationMetadata?
}
```

#### Step 3: Update AnalysisResultView
**File:** `SkinLab/Features/Analysis/Views/AnalysisResultView.swift`

Accept `AnalysisRunResult` instead of just `SkinAnalysis`:
```swift
struct AnalysisResultView: View {
    let result: AnalysisRunResult
    // ... rest of view
}
```

#### Step 4: Implement "Start Tracking" Action
**File:** `SkinLab/Features/Analysis/ViewModels/AnalysisResultViewModel.swift`

```swift
@MainActor
func startTrackingBaseline(
    analysisRecordId: UUID,
    photoPath: String?,
    standardization: PhotoStandardizationMetadata?,
    defaultTargetProducts: [String] = [],
    notes: String? = nil
) throws -> TrackingSession {
    // Check for active session
    let activeSessions = try modelContext.fetch(
        FetchDescriptor<TrackingSession>(
            predicate: #Predicate { $0.isActive }
        )
    )

    let session: TrackingSession
    if let existing = activeSessions.first {
        // TODO: Prompt user to choose: continue vs new
        session = existing
    } else {
        session = TrackingSession(
            targetProducts: defaultTargetProducts,
            notes: notes
        )
        modelContext.insert(session)
    }

    let checkIn = CheckIn(
        day: 0,
        captureDate: Date(),
        analysisId: analysisRecordId,
        photoPath: photoPath,
        photoStandardization: standardization,
        lifestyle: nil,  // Day 0 has no lifestyle data
        reliability: nil  // Will be computed at report time
    )

    session.addCheckIn(checkIn)
    try modelContext.save()

    return session
}
```

#### Step 5: Wire Navigation
**File:** `SkinLab/Features/Analysis/Views/AnalysisResultView.swift`

```swift
Button {
    Task {
        do {
            let session = try await viewModel.startTrackingBaseline(
                analysisRecordId: result.analysisId,
                photoPath: result.photoPath,
                standardization: result.standardization
            )
            selectedSession = session
            showTrackingDetail = true
        } catch {
            // Handle error
        }
    }
} label: {
    // ... button label
}
```

### Impact
- 修复最明显的 UX 承诺缺口（UI 写了"作为第0天基准"，但没实现）
- 分析 → 追踪转化会显著提升
- 顺带把 photo standardization 拉进追踪体系

---

## Priority 3: Make Photo Standardization Value Visible

### Goal
Surface reliability and standardization feedback at capture time, not just in reports.

### Implementation Steps

#### Step 1: Compute Reliability at Check-In Time
**File:** `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (CheckInView)

```swift
private func saveCheckIn() {
    // ... existing code ...

    // Compute reliability
    let scorer = ReliabilityScorer()
    let expectedDay = session.nextCheckInDay
    let reliability = scorer.score(
        checkIn: checkIn,
        analysis: analysis,
        session: session,
        expectedDay: expectedDay,
        cameraPositionConsistency: true
    )

    // Rebuild checkIn with reliability
    let finalCheckIn = CheckIn(
        // ... existing fields ...
        reliability: reliability
    )

    session.addCheckIn(finalCheckIn)
}
```

#### Step 2: Fix Reliability Reason Mapping Bug
**File:** `SkinLab/Features/Tracking/Services/ReliabilityScorer.swift`

```swift
// Fix: tooBright should map to .highLight, not .lowLight
case .tooBright:
    reasons.append(.highLight)
    score -= lightingPenalty
```

#### Step 3: Add Reliability Badge to Check-In UI
**File:** `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (CheckInView)

```swift
// After analysis completes, show reliability preview
if let analysis = currentAnalysis {
    let previewReliability = computePreviewReliability(analysis, standardization)

    ReliabilityBadgeView(
        reliability: previewReliability,
        size: .medium
    )
}
```

### Impact
- 用户能立刻看到"这次打卡数据质量如何"
- 建立对"标准化拍照"功能的信任
- 修复代码 bug（tooBright mapping）

---

## Additional Improvements (Lower Priority)

### Fix Lifestyle Optionality
**Problem:** "Optional" lifestyle has defaults that auto-fill.

**Solution:**
```swift
struct LifestyleDraft {
    var sleepHours: Double?
    var stressLevel: Int?
    // ... all optionals
}

// In CheckInView:
@State private var includeLifestyle = false
@State private var lifestyleDraft = LifestyleDraft()

// Only save if user opts in:
let lifestyle = includeLifestyle ? LifestyleFactors(from: lifestyleDraft) : nil
```

### Fix Report Export Architecture
**Problem:** CSV/JSON export can't access check-in lifestyle data.

**Solution:** Pass session to report view:
```swift
struct TrackingReportView: View {
    let report: EnhancedTrackingReport
    let session: TrackingSession  // Add this
}
```

### Fix UI Inconsistencies
- Remove duplicate "Start Tracking" entry points in `AnalysisResultView`
- Respect accessibility reduce motion/transparency settings
- Consistent language (English vs Chinese strings)

---

## Tech Debt to Address While Touching Code

### AnalysisResultViewModel Inefficiency
```swift
// Current: N fetches in loop
for checkIn in checkIns {
    let analysis = try modelContext.fetch(...)

// Better: Fetch once with contains
let analysisIds = checkIns.compactMap { $0.analysisId }
let analyses = try modelContext.fetch(
    FetchDescriptor<SkinAnalysisRecord>(
        predicate: #Predicate { analysisIds.contains($0.id) }
    )
)
```

### TrackingReportView Bug
```swift
// Current: Always uses timeline regardless of reliable check
let sortedCheckInIds = report.timelineReliable.isEmpty
    ? report.timeline.map { $0.checkInId }
    : report.timeline.map { $0.checkInId }  // BUG

// Fix:
let sortedCheckInIds = report.timeline.map { $0.checkInId }
```

---

## Feature Gaps vs Modern Skincare Apps

If you want to feel "real" and trustworthy:

1. **Baseline integrity** - Day 0 must be automatic and include same metadata as follow-ups
2. **Data quality transparency** - Reliability badges on each check-in, not hidden in reports
3. **Correlation disclaimers** - Let users choose which metric to correlate against
4. **Privacy control** - Lifestyle notes opt-in, export privacy-aware

---

## Recommended Implementation Sequence

1. **Fix lifestyle delta computation** (1-2 hours, unblocks new feature)
2. **Implement Day 0 baseline** (3-5 hours, fixes main UX gap)
3. **Compute reliability at capture time** (2-3 hours, makes standardization visible)
4. **Fix lifestyle optionality** (1-2 hours, improves data quality)
5. **Export architecture refactor** (2-3 hours, completes feature set)

**Total estimated time:** 9-15 hours for critical improvements

---

## Success Metrics

### Before
- Lifestyle insights: "暂无足够数据" (even with data)
- Start tracking: Opens blank TrackingView
- Photo standardization: Captured but invisible
- Report exports: Malformed CSV, missing lifestyle data

### After
- Lifestyle insights: Shows correlations (sleep → score, etc.)
- Start tracking: Creates session + Day 0 check-in immediately
- Photo standardization: Reliability badges visible at save time
- Report exports: Complete CSV/JSON with all metadata

---

## Next Action

Pick Priority 1 (lifestyle delta fix) for immediate implementation - it's the smallest change that makes the biggest visible impact on user trust.

Would you like me to generate the exact code changes for Priority 1?
