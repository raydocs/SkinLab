# Engagement Features: Daily Streaks & Achievement Badges

**Epic**: fn-2 - Engagement Features: Daily Streaks & Achievement Badges
**As of**: 2026-01-12
**Author**: Claude Code (Autonomous Planning)
**Priority**: P0 (Immediate - 1-2 weeks)
**Estimated Effort**: 12 days

---

## Executive Summary

This epic implements the **P0 engagement gaps** identified in fn-1 gap analysis: **Daily Streaks & Consistency Tracking** and **Achievement Badges & Milestones**. These features drive daily habit formation and retention by visualizing consistency and celebrating progress milestones, directly supporting SkinLab's "让护肤效果看得见" (make skincare effects visible) positioning.

**Why P0**: All major competitors (美丽修行, 安稻护肤, Skin Bliss) have these features. Low technical complexity (2/5) with high retention/viral impact. Strong strategic fit with effect verification.

**User Impact**: High - Daily tracking is core to 28-day effect verification. Badges create psychological rewards and social sharing incentives.

**Business Value**: High - Directly impacts DAU/MAU, retention, and viral sharing.

---

## Overview & Scope

### Problem Statement

SkinLab lacks engagement mechanics present in all major competitors:
- No visual streak counter to celebrate consecutive check-ins
- No achievement badges for milestones (7-day streak, 28-day complete, etc.)
- Missing gamified progression system that drives daily habits

### Solution Overview

Implement two interconnected engagement features:

1. **Daily Streaks & Consistency Tracking**
   - Visual streak counter showing consecutive days of tracking
   - Calendar day-based streak window (midnight reset)
   - Streak freeze mechanic (1 per 30 days, with cycle tracking)
   - Integration with existing TrackingSession model

2. **Achievement Badges & Milestones**
   - Badge system for progression milestones
   - Badge categories: Streaks, Completeness, Social, Knowledge
   - Achievement dashboard with unlocked/locked badges
   - Share-to-WeChat integration (with fallback to iOS Share Sheet)

### What's In Scope

- Streak counter in HomeView and TrackingReportView
- Streak history tracking with backfill for existing users
- Achievement badge system with 12 initial badges
- Achievement dashboard (new view)
- Badge celebration animations
- Share-to-WeChat for badge achievements (with Share Sheet fallback)
- SwiftData persistence for engagement metrics
- Local notifications for streak at-risk warnings

### What's Out of Scope

- WeChat login (P1 gap, separate epic)
- Expert content (P2 gap)
- Enhanced community features (P2 gap)
- Product review system (P2 gap)

---

## Approach

### Technical Architecture

#### Data Models (SwiftData-Compatible)

```swift
// NEW: UserEngagementMetrics (SwiftData)
@Model
final class UserEngagementMetrics {
    var streakCount: Int = 0
    var longestStreak: Int = 0
    var lastCheckInDate: Date?
    var streakFreezesAvailable: Int = 1
    var lastFreezeRefillDate: Date?  // Tracks 30-day cycle for freeze replenishment
    var totalCheckIns: Int = 0
    
    // Store unlocked achievement IDs (SwiftData-compatible string array)
    @Attribute(.externalStorage) var unlockedAchievementIDs: [String] = []
}

// NEW: AchievementProgress (SwiftData)
// Tracks progress for each achievement, persisted separately from badge definitions
@Model
final class AchievementProgress {
    var achievementID: String
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Double = 0.0
    var lastUpdated: Date = Date()
}

// Badge definitions live in CODE, not SwiftData
// This avoids migration complexity and keeps definitions DRY
struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: BadgeCategory
    let requirementType: AchievementRequirementType
    let requirementValue: Int
    let iconName: String
}

enum BadgeCategory: String, CaseIterable, Codable {
    case streaks = "连续打卡"
    case completeness = "完整性"
    case social = "社交互动"
    case knowledge = "产品知识"
}

enum AchievementRequirementType: String, Codable {
    case streakDays = "streakDays"
    case totalCheckIns = "totalCheckIns"
    case skinTwinMatches = "skinTwinMatches"
    case productAnalysisCompleted = "productAnalysisCompleted"
}
```

#### Services

```swift
// NEW: StreakTrackingService
final class StreakTrackingService {
    func checkIn() -> StreakResult
    func getStreakStatus() -> StreakStatus
    func useStreakFreeze() -> Bool
    func backfillStreaks() async
    func checkAndRefillFreezes()  // Called on app launch to check 30-day cycle
}

// NEW: AchievementService
final class AchievementService {
    func checkAchievements() -> [AchievementDefinition]
    func getProgress(for: AchievementDefinition) -> Double
    func unlockAchievement(_ id: String)
    func shareAchievement(_ id: String) async  // Returns Share Sheet fallback if WeChat unavailable
}

// NEW: AchievementDefinitions (code, not persisted)
enum AchievementDefinitions {
    static let allBadges: [AchievementDefinition] = [
        // 12 badges defined here
    ]
}
```

#### UI Components

```swift
// NEW: StreakBadgeView (SwiftUI)
struct StreakBadgeView: View {
    var streakCount: Int
    var longestStreak: Int
    var showFreezeButton: Bool
}

// NEW: AchievementBadgeView (SwiftUI)
struct AchievementBadgeView: View {
    var badge: AchievementDefinition
    var progress: AchievementProgress
    var size: BadgeSize
}

// NEW: AchievementDashboardView (SwiftUI)
struct AchievementDashboardView: View {
    @Query var achievementProgress: [AchievementProgress]
    var category: BadgeCategory?
}

// NEW: StreakCelebrationView (SwiftUI)
struct StreakCelebrationView: View {
    var milestone: Int
    var showConfetti: Bool  // Respects reduceMotion
}
```

### Implementation Strategy

#### Phase 1: Data Layer & Services (Task fn-2.1)
1. Create UserEngagementMetrics SwiftData model with SwiftData-compatible fields
2. Create AchievementProgress SwiftData model (NOT Achievement enum)
3. Create AchievementDefinition structs in code (badge definitions, not persisted)
4. Implement StreakTrackingService with calendar-day logic and freeze cycle tracking
5. Implement AchievementService with progress tracking
6. Add migration logic for backfilling existing users
7. Unit tests for streak calculation and achievement progress logic

#### Phase 2: Achievement System (Task fn-2.2)
1. Define 12 badges in AchievementDefinitions code (3 per category):
   - Streaks: 3-Day, 7-Day, 28-Day
   - Completeness: First Analysis, 10 Check-ins, Complete 28-Day Cycle
   - Social: First Skin Twin, 5 Twin Matches
   - Knowledge: 5 Products Analyzed, 10 Ingredients Learned
2. Create AchievementBadgeView component rendering locked and unlocked states
3. Create AchievementDashboardView with tab filter by category
4. Implement badge lock/unlock visual states with progress indicators
5. Create achievement unlock animation (scale + fade, respects reduceMotion)
6. UI tests for badge rendering and navigation

#### Phase 3: Streak Feature Integration (Task fn-2.3)
1. Add StreakBadgeView to HomeView header
2. Add streak indicator to TrackingReportView progress section
3. Implement check-in trigger on TrackingSession completion
4. Add streak freeze button and logic with cycle tracking
5. Implement local notification for streak at-risk (Day 5, 7, 14 warnings)
6. Add timezone change detection and handling
7. Integration tests for streak persistence and freeze cycle

#### Phase 4: Celebration & Sharing (Task fn-2.5)
1. Create StreakCelebrationView with confetti animation (respects reduceMotion)
2. Implement celebration trigger on milestone streaks (7, 14, 28 days)
3. Implement celebration trigger on badge unlocks
4. Implement iOS Share Sheet for achievements (primary, works with WeChat if installed)
5. Add share preview image generation (badge + streak + branding, no user photos)
6. Analytics tracking for celebration_shown and achievement_shared events
7. Graceful degradation tests (WeChat not installed, permission denied)

#### Phase 5: Main View Integration (Task fn-2.6)
1. Add achievement dashboard entry point to ProfileView
2. Add quick achievement preview in HomeView (top 3 in-progress badges)
3. Implement achievement notification badge on dashboard entry
4. Update navigation structure with deep link support (skinlab://achievements)
5. Accessibility labels and VoiceOver support for all navigation
6. Integration tests for navigation flow

#### Phase 6: Testing & Polish (Task fn-2.7)
1. Unit tests: Streak calculation, freeze cycle, achievement progress
2. UI tests: Badge rendering, navigation, celebration dismissal
3. Integration tests: End-to-end streak and badge flows
4. Performance tests: Badge calculation <100ms for 100 achievements
5. Performance tests: Backfill migration <5s for 1000 sessions (capped at 90 days)
6. Accessibility audit: VoiceOver, Dynamic Type, color contrast
7. Analytics validation: Event tracking for all engagement events
8. Edge case tests: Timezone changes, DST boundaries, data corruption fallback

### Key Design Decisions

#### Decision 1: Check-in Definition
**Choice**: A "check-in" = completed tracking session (TrackingSession.completedAt)
**Rationale**:
- Aligns with "让护肤效果看得见" - tracking is core value
- Existing TrackingSession model (L75-130) already captures this
- Prevents streak gaming by just opening app
- Matches competitor behavior (美丽修行, 安稻护肤)

#### Decision 2: Streak Window Logic
**Choice**: Calendar day with midnight reset (user's local timezone at check-in time)
**Rationale**:
- User-friendly and easy to understand
- Matches most competitors (Duolingo, habit trackers)
- Easier to implement than 24-hour rolling window
- Timezone change rule: Use current timezone at time of check-in for day calculation

#### Decision 3: Achievement Dashboard Location
**Choice**: New view accessible from ProfileView
**Rationale**:
- Keeps achievement discovery optional but accessible
- Profile is natural home for progression stats
- Doesn't clutter main navigation
- Matches competitor patterns (Skin Bliss has achievements in profile)

#### Decision 4: Existing User Data Backfill
**Choice**: Calculate streaks from historical TrackingSession data, capped at 90 days
**Rationale**:
- Fair to existing users who already tracked consistently
- TrackingSession history is reliable source of truth
- 90-day cap prevents performance issues on very large histories
- One-time migration on app update
- Fallback: Start from 0 if migration fails (log analytics event)

#### Decision 5: Streak Freeze Mechanic
**Choice**: 1 freeze per 30 days, manually activated, with lastFreezeRefillDate tracking
**Rationale**:
- Prevents frustration from missed days
- Manual activation requires user intentionality
- lastFreezeRefillDate enables correct 30-day cycle enforcement
- Matches Duolingo's successful pattern

#### Decision 6: SwiftData Persistence Strategy
**Choice**: Persist state (AchievementProgress), not definitions (AchievementDefinition)
**Rationale**:
- Badge definitions are code, not database entities (simpler migrations)
- AchievementProgress tracks user-specific state (unlocked, progress, dates)
- Avoids SwiftData complexity with enum associated values and custom type arrays
- Definitions in code enables easier badge additions without schema migrations

#### Decision 7: WeChat Sharing Strategy
**Choice**: iOS Share Sheet as primary (shows WeChat if installed), no SDK dependency
**Rationale**:
- Share Sheet works if WeChat is installed (no SDK integration needed)
- Eliminates schedule risk from SDK integration/approval
- Falls back gracefully to other sharing options if WeChat unavailable
- Can add SDK later if analytics shows high WeChat share rate

---

## Risks & Dependencies

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **SwiftData schema churn** | Medium | High | Persist minimal state, definitions in code |
| **Timezone edge cases** | Medium | Medium | Use Calendar.current.timezone, explicit DST handling |
| **Backfill performance** | Low | High | Cap at 90 days, O(n log n) algorithm with grouping |
| **Particle performance** | Medium | Medium | Reduce count on low power mode, respect reduceMotion |
| **Analytics consistency** | Medium | Low | Define event schema once, single analytics service |
| **Share card privacy** | Medium | Medium | No user photos by default, explicit consent only |

### Business Risks

| Risk | Mitigation |
|------|------------|
| **Streak anxiety** | Streak freeze mechanic, at-risk notifications, positive framing |
| **Over-gamification** | Meaningful badges tied to real progress, quality over quantity |
| **Social comparison pressure** | Focus on personal progress, optional sharing, no leaderboards |
| **Existing users feel disadvantaged** | Backfill streaks (90-day cap), welcome message acknowledging past progress |

### Dependencies

| Dependency | Required For | Status | Fallback |
|------------|--------------|--------|----------|
| TrackingSession model | Streak calculation | ✅ Existing | Use CheckIn model if needed |
| UserHistoryStore | Backfill data | ✅ Existing | Start from 0 |
| iOS Share Sheet | Achievement sharing | ✅ Built-in | No fallback needed |
| WeChat app | Share to WeChat | ⚠️ User-installed | Share Sheet shows other options |
| Notification permissions | Streak at-risk warnings | ⚠️ Not requested | In-app only, no push |

---

## Acceptance Criteria

### Epic-Level Acceptance

- [ ] **P0-1**: Users see visual streak counter in HomeView showing consecutive check-in days
- [ ] **P0-2**: Streak increments by 1 when user completes tracking session (same-day check-ins don't increment)
- [ ] **P0-3**: Streak resets to 0 when user misses a calendar day (no check-in)
- [ ] **P0-4**: Users can activate 1 streak freeze per 30 days to maintain streak (tracked via lastFreezeRefillDate)
- [ ] **P0-5**: Freeze replenishes after 30 days from lastFreezeRefillDate
- [ ] **P0-6**: Achievement dashboard displays 12 badges (3 per category: Streaks, Completeness, Social, Knowledge)
- [ ] **P0-7**: Badges show locked state with progress indicator, unlocked state with unlock date
- [ ] **P0-8**: Milestone achievements (7, 14, 28 days) trigger celebration animation
- [ ] **P0-9**: Badge unlocks trigger celebration animation
- [ ] **P0-10**: Users can share unlocked achievements via iOS Share Sheet (WeChat appears if installed)
- [ ] **P0-11**: Existing users receive backfilled streaks based on historical tracking data (90-day cap)
- [ ] **P0-12**: Confetti animation is disabled when UIAccessibility.isReduceMotionEnabled = true
- [ ] **P0-13**: Streak and achievement data persist across app launches via SwiftData
- [ ] **P0-14**: All views support VoiceOver and Dynamic Type
- [ ] **P0-15**: Analytics events track: streak_started, streak_lost, achievement_unlocked, achievement_shared, celebration_shown
- [ ] **P0-16**: Share preview images contain badge/streak/branding only (no user skin photos without consent)

### Task-Level Acceptance

See individual task specs (fn-2.1 through fn-2.7) for detailed acceptance criteria.

---

## Test Strategy

### Unit Tests

- `StreakTrackingServiceTests.swift`
  - testCheckInIncrementsStreak
  - testSameDayCheckInDoesNotIncrement
  - testMissedDayResetsStreak
  - testStreakFreezeMaintainsStreak
  - testFreezeReplenishesAfter30Days
  - testBackfillFromHistoricalData
  - testTimezoneChangeBehavior
  - testDSTBoundaryBehavior

- `AchievementServiceTests.swift`
  - testBadgeProgressCalculation
  - testBadgeUnlockOnThreshold
  - testMultipleBadgeUnlocks
  - testBadgeProgressPersistence

### Integration Tests

- `StreakIntegrationTests.swift`
  - testEndToEndStreakFlow (check-in → streak increment → persistence → display)
  - testStreakWithFreeze (activate freeze → miss day → streak maintained)

- `AchievementIntegrationTests.swift`
  - testAchievementUnlockFlow (complete action → check → unlock → celebrate)
  - testAchievementDashboard (display badges → filter category → unlock badge → refresh)

### UI Tests

- `StreakBadgeViewTests.swift`
  - testStreakCounterDisplaysCorrectly
  - testStreakFreezeButtonVisibility

- `AchievementDashboardViewTests.swift`
  - testBadgesRenderCorrectly
  - testLockedBadgeShowsProgress
  - testUnlockedBadgeShowsDate

### Performance Tests

- Badge calculation completes in <100ms for 100 achievements
- Backfill migration completes in <5s for 1000 historical sessions (90-day cap)
- Streak calculation completes in <50ms

### Accessibility Tests

- VoiceOver navigation: All streak and badge elements are accessible
- Dynamic Type: Layouts adapt to Larger Text sizes
- Color contrast: Badge icons meet WCAG AA standards
- Reduced Motion: Celebrations respect UIAccessibility.isReduceMotionEnabled

### Edge Cases to Test

- User changes timezone while streak active
- Leap second / DST boundary (day length 23/25 hours)
- App update with existing streak data (migration)
- Tracking session created at 23:59, completed at 00:01
- User has no historical data (new install)
- User has corrupted historical data (fallback to 0 streak + analytics)
- WeChat not installed (Share Sheet shows other options)
- Notification permission denied (in-app only warnings)

---

## References

### fn-1 Analysis Documents

- `.flow/specs/fn-1-feature-matrix.md` - Competitor feature matrix
- `.flow/specs/fn-1-gap-analysis.md` - Gap analysis with P0 prioritization
- `.flow/specs/fn-1-competitor-analysis.md` - Final recommendations

### Code Reuse Opportunities

- `TrackingReportView.swift:1-594` - Existing tracking UI, add streak indicator
- `TrackingSession.swift:75-130` - Check-in model for streak calculation
- `UserHistoryStore.swift` - Historical data for backfill
- `AnalyticsVisualizationViews.swift:327-353` - Badge UI patterns
- SwiftData models (9 existing) - Add UserEngagementMetrics, AchievementProgress

### Best Practices Research

- Duolingo streak system (30-day freeze window, manual activation)
- Habit tracking apps (Streaks, Productive) - calendar day vs 24-hour window
- iOS 17 SwiftUI animations - confetti, milestone celebrations
- SwiftData migration patterns - persist state, not definitions

### Documentation

- Apple SwiftData Documentation: https://developer.apple.com/documentation/swiftdata
- Apple SwiftUI Animation Documentation: https://developer.apple.com/documentation/swiftui/animation
- Apple ShareSheet Documentation: https://developer.apple.com/documentation/uikit/uiactivityviewcontroller

---

## Success Metrics

Track these metrics for 30 days post-launch:

| Metric | Target | Measurement |
|--------|--------|-------------|
| **DAU/MAU ratio** | +15% vs baseline | Daily active users / monthly active users |
| **7-day streak rate** | 20% of users | Users with 7+ day streak / total active users |
| **Badge completion rate** | 3 badges/user | Total badges unlocked / total users |
| **Achievement share rate** | 5% of unlocks | Achievement shares / achievement unlocks |
| **Streak retention lift** | +10% vs baseline | Retention of users with 3+ day streak vs all users |
| **Achievement dashboard visits** | 40% of users | Unique dashboard visitors / total active users |

---

## Open Questions

### Questions for Product Team

1. **Streak freeze policy**: Should we grant bonus freezes to users who complete 28-day cycles? (Proposed: 1 bonus freeze)
2. **Badge naming**: Do you have specific badge names in Chinese or should we use defaults? (Proposed: "新手入门" for first analysis, etc.)
3. **Celebration frequency**: Should we celebrate every milestone (3, 7, 14, 21, 28) or only major ones (7, 28)? (Proposed: 7 and 28 only to avoid fatigue)

### Questions for Engineering Team

1. **Notification permissions**: Should we request notification permissions on first launch for streak warnings, or wait until user has active streak? (Proposed: Request when streak reaches 5 days)

---

## Implementation Timeline

| Task | Duration | Dependencies |
|------|----------|--------------|
| fn-2.1: Data Layer & Services | 2 days | None |
| fn-2.2: Achievement System | 3 days | fn-2.1 |
| fn-2.3: Streak Feature Integration | 2 days | fn-2.1 |
| fn-2.4: Placeholder (duplicate) | 0 days | fn-2.1 (marked done immediately) |
| fn-2.5: Celebration & Sharing | 2 days | fn-2.2, fn-2.3 |
| fn-2.6: Main View Integration | 1 day | fn-2.2, fn-2.3 |
| fn-2.7: Testing & Polish | 2 days | fn-2.5, fn-2.6 |

**Total Estimated Effort**: 12 days (2.4 weeks) for 1 engineer

**Parallelization Opportunity**: fn-2.2 and fn-2.3 can run in parallel after fn-2.1 completes, reducing timeline to ~8 days with 2 engineers.

**Note**: fn-2.4 is a duplicate placeholder created during planning (no work required). fn-2.7 depends on fn-2.5 and fn-2.6, not fn-2.4.

---

*Epic generated as part of fn-2 planning*
*As of: 2026-01-12*
*Priority: P0 (Immediate implementation based on fn-1 gap analysis)*
*Updated after plan review: Fixed task mapping, SwiftData model design, and WeChat sharing strategy*
