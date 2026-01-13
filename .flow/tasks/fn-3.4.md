# fn-3.4 Make lifestyle inputs truly optional

## Description
Fix the misleading "optional" lifestyle inputs by removing default values (sleepHours=7.0, stressLevel=3) that cause lifestyle data to always be saved, artificially inflating coverage percentage and potentially introducing spurious correlations.

## Changes Required

### 1. Create LifestyleDraft Struct

**File**: New struct in `TrackingDetailView.swift` or separate model file

```swift
struct LifestyleDraft {
    var sleepHours: Double?
    var stressLevel: Int?
    var waterIntakeLevel: Int?
    var alcoholConsumed: Bool?
    var exerciseMinutes: Int?
    var sunExposureLevel: Int?
    var dietNotes: String?
    var cyclePhase: LifestyleFactors.CyclePhase?

    var hasAnyData: Bool {
        sleepHours != nil ||
        stressLevel != nil ||
        waterIntakeLevel != nil ||
        alcoholConsumed != nil ||
        exerciseMinutes != nil ||
        sunExposureLevel != nil ||
        (dietNotes != nil && !dietNotes!.isEmpty) ||
        cyclePhase != nil
    }
}
```

### 2. Add Toggle and Update State

**File**: `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (CheckInView)

```swift
@State private var includeLifestyle = false
@State private var lifestyleDraft = LifestyleDraft()
```

### 3. Update UI to Show Toggle

Add disclosure group with toggle:

```swift
DisclosureGroup(isExpanded: $includeLifestyle) {
    if includeLifestyle {
        lifestyleInputsContent  // Existing input fields
    }
} label: {
    HStack {
        Text("生活因素（可选）")
            .font(.skinLabSubheadline)
            .foregroundColor(.skinLabText)

        Spacer()

        if !includeLifestyle || !lifestyleDraft.hasAnyData {
            Text("未记录")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        } else {
            Text(lifestyleSummary)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
    }
}
```

### 4. Update Input Fields to Use Optionals

Change all lifestyle input bindings:
- `sleepHours` from `7.0` to `lifestyleDraft.sleepHours`
- `stressLevel` from `3` to `lifestyleDraft.stressLevel`
- etc.

Update sliders/steppers to handle nil:
```swift
Picker("", selection: Binding(
    get: { $0.stressLevel ?? 3 },
    set: { $0.stressLevel = $0 }
)) {
    // ... options
}
```

### 5. Update saveCheckIn() Logic

```swift
let lifestyle: LifestyleFactors?
if includeLifestyle && lifestyleDraft.hasAnyData {
    lifestyle = LifestyleFactors(from: lifestyleDraft)
} else {
    lifestyle = nil
}
```

### 6. Update Coverage Computation

**File**: `SkinLab/Features/Tracking/Models/TrackingReportExtensions.swift`

In `generateReport()`:

```swift
let checkInsWithLifestyle = sortedCheckIns.filter { $0.lifestyle != nil }
let lifestyleCoverage = Double(checkInsWithLifestyle.count) /
                       Double(max(sortedCheckIns.count, 1))
```

This now reflects true opt-in rate instead of artificial 100%.

## Key Context

- **Current issue**: `sleepHours` defaults to 7.0, making lifestyle always save
- **Location**: `TrackingDetailView.swift` CheckInView, around line ~400
- **Impact**: Coverage percentage is misleading, correlations may use default values
- **User-facing**: "可选" label is false advertising when defaults always apply

## Acceptance
- [ ] LifestyleDraft struct created with all optional fields
- [ ] includeLifestyle toggle added and functional
- [ ] Lifestyle inputs hidden by default
- [ ] CheckIn.lifestyle is nil when user didn't opt in
- [ ] Coverage percentage reflects true opt-in rate
- [ ] Correlation analysis only uses real user-provided data
- [ ] UI shows "未记录" when lifestyle not included

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
