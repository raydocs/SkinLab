# fn-2.1 Data Layer & Services

## Description
# Task fn-2.1: Data Layer & Services

**Epic**: fn-2 - Engagement Features
**Task**: fn-2.1 - Data Layer & Services
**Estimated Effort**: 2 days
**Dependencies**: None

---

## Overview

Create the foundational data models and services for streak tracking and achievement system. This task establishes SwiftData models with SwiftData-compatible design, business logic services, and migration infrastructure.

**Key Design Changes After Review**:
- SwiftData models use simple types (no enum associated values, no custom type arrays)
- Badge definitions live in CODE, not database (AchievementDefinition structs)
- AchievementProgress tracks user state (unlocked, progress, dates) separately
- Streak freeze policy is now representable with lastFreezeRefillDate field

---

## Acceptance Criteria

- [ ] **AC-1**: UserEngagementMetrics SwiftData model created with fields: streakCount, longestStreak, lastCheckInDate, streakFreezesAvailable, lastFreezeRefillDate, totalCheckIns, unlockedAchievementIDs
- [ ] **AC-2**: AchievementProgress SwiftData model created with fields: achievementID, isUnlocked, unlockedAt, progress, lastUpdated
- [ ] **AC-3**: AchievementDefinition struct (CODE, not SwiftData) with fields: id, title, description, category, requirementType, requirementValue, iconName
- [ ] **AC-4**: BadgeCategory enum (Codable, String backing) with 4 cases: streaks, completeness, social, knowledge
- [ ] **AC-5**: AchievementRequirementType enum (Codable, String backing) with cases: streakDays, totalCheckIns, skinTwinMatches, productAnalysisCompleted
- [ ] **AC-6**: AchievementDefinitions code defines all 12 badges (not persisted in SwiftData)
- [ ] **AC-7**: StreakTrackingService implements: checkIn(), getStreakStatus(), useStreakFreeze(), checkAndRefillFreezes(), backfillStreaks()
- [ ] **AC-8**: AchievementService implements: checkAchievements(), getProgress(), unlockAchievement(), shareAchievement()
- [ ] **AC-9**: Calendar-day streak calculation logic (midnight reset in user's timezone at check-in time)
- [ ] **AC-10**: Streak freeze replenishment logic (refill after 30 days from lastFreezeRefillDate)
- [ ] **AC-11**: Backfill logic calculates streaks from existing TrackingSession data (90-day cap)
- [ ] **AC-12**: Unit tests for streak calculation (increment, reset, freeze, refill, backfill, timezone, DST)
- [ ] **AC-13**: Unit tests for achievement progress calculation

---

## Implementation Notes

### SwiftData Models

File: `SkinLab/Models/UserEngagementMetrics.swift`
```swift
import SwiftData

@Model
final class UserEngagementMetrics {
    var streakCount: Int = 0
    var longestStreak: Int = 0
    var lastCheckInDate: Date?
    var streakFreezesAvailable: Int = 1
    var lastFreezeRefillDate: Date?  // Tracks 30-day cycle for freeze replenishment
    var totalCheckIns: Int = 0
    
    // Store unlocked achievement IDs as string array (SwiftData-compatible)
    @Attribute(.externalStorage) var unlockedAchievementIDs: [String] = []
}
```

File: `SkinLab/Models/AchievementProgress.swift`
```swift
import SwiftData

@Model
final class AchievementProgress {
    var achievementID: String
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Double = 0.0
    var lastUpdated: Date = Date()
    
    init(achievementID: String) {
        self.achievementID = achievementID
    }
}
```

### Badge Definitions (CODE, not SwiftData)

File: `SkinLab/Features/Achievements/Models/AchievementDefinitions.swift`
```swift
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

enum AchievementDefinitions {
    static let allBadges: [AchievementDefinition] = [
        // Streaks (3 badges)
        AchievementDefinition(
            id: "streak_3",
            title: "三日坚持",
            description: "连续打卡3天",
            category: .streaks,
            requirementType: .streakDays,
            requirementValue: 3,
            iconName: "flame.fill"
        ),
        // ... 11 more badges
    ]
}
```

### Services

File: `SkinLab/Services/StreakTrackingService.swift`
- Use Calendar.current to determine user's timezone at check-in time
- Check-in = completed TrackingSession (use completedAt timestamp)
- Streak increments if lastCheckIn was yesterday (calendar day comparison)
- Streak resets to 0 if gap > 1 day
- Freeze maintains streak for 1 missed day
- checkAndRefillFreezes() called on app launch: if (now - lastFreezeRefillDate) >= 30 days, set streakFreezesAvailable = 1, update lastFreezeRefillDate
- Timezone change rule: Use current timezone at time of check-in for day calculation

File: `SkinLab/Services/AchievementService.swift`
- Check achievements after each check-in
- Calculate progress as (current / requirementValue) * 100
- Unlock when progress >= 100%
- Recalculate progress on specific events (check-in, twin match, product analysis), not on app launch

### Migration

File: `SkinLab/Services/EngagementMigrationService.swift`
- One-time migration on app update
- Query all historical TrackingSessions (capped at 90 days for performance)
- Group sessions by calendar day
- Calculate streaks from consecutive days with sessions
- Fallback: Set streak to 0 if migration fails, log analytics event

---

## Testing

### Unit Tests

File: `SkinLab/Tests/EngagementTests/StreakTrackingServiceTests.swift`
- testCheckInIncrementsStreak
- testSameDayCheckInDoesNotIncrement
- testMissedDayResetsStreak
- testStreakFreezeMaintainsStreak
- testFreezeReplenishesAfter30Days
- testBackfillFromHistoricalData
- testTimezoneChangeBehavior
- testDSTBoundaryBehavior (23/25 hour days)

File: `SkinLab/Tests/EngagementTests/AchievementServiceTests.swift`
- testBadgeProgressCalculation
- testBadgeUnlockOnThreshold
- testMultipleBadgeUnlocks
- testBadgeProgressPersistence

---

## References

- `TrackingSession.swift:75-130`: Check-in model reference
- `UserHistoryStore.swift`: Historical data source
- Epic spec: `.flow/specs/fn-2.md` (updated after review with SwiftData fixes)

---

## Acceptance
- [ ] TBD

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
