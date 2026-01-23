# SkinLab iOS App - AI Agent Instructions

## Project Overview
SkinLab is an AI-powered skin analysis and skincare recommendation iOS app.
- **Core Philosophy**: Data-driven insights that users want to share
- **Target Users**: 18-35 year olds focused on skincare
- **Differentiation**: Effect verification engine + skin twin matching + anti-ad commitment

## Tech Stack
- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Clean Architecture
- **Storage**: SwiftData
- **AI**: Gemini 3.0 Flash Vision API
- **Image Processing**: Vision Framework

## Completed Features

### fn-2: Engagement Features (Daily Streaks & Achievement Badges)
- **UserEngagementMetrics** (SwiftData model): Tracks streakCount, longestStreak, lastCheckInDate, streakFreezesAvailable, lastFreezeRefillDate, totalCheckIns, unlockedAchievementIDs
- **AchievementProgress** (SwiftData model): Tracks progress for each achievement (achievementID, isUnlocked, unlockedAt, progress)
- **AchievementDefinition** (code struct): Badge definitions with title, description, category, requirementType, requirementValue, iconName
- **StreakTrackingService**: checkIn(), getStreakStatus(), useStreakFreeze(), backfillStreaks(), checkAndRefillFreezes()
- **AchievementService**: checkAchievements(), getProgress(), unlockAchievement(), shareAchievement()
- **Celebrations**: Streak milestones + achievement unlock celebration UI; respects Reduce Motion
- **Sharing**: Achievements shared via iOS Share Sheet (WeChat appears if installed); share images contain badge/streak/branding only
- **Freeze mechanism**: 1 freeze per 30 days, tracked via lastFreezeRefillDate

### fn-3: Photo Standardization & Lifestyle Fixes
- **Lifestyle delta**: Uses `checkInId` for joins (not `day`) to compute real score deltas
- **Day 0 baseline**: Created from analysis results via "立即开始追踪" button (refuse if active session exists)
- **Reliability at capture**: Computed when saving check-in, stored on CheckIn model (fix tooBright -> highLight)
- **nextCheckInDay semantics**: Returns next due uncompleted checkpoint (supports late check-ins)
- **Lifestyle inputs**: Truly optional - only saved when user opts in AND sets at least one field

## Key Implementation Rules

1. **Always use checkInId for joins, never day** - Days are not unique; check-in UUIDs are stable identifiers
2. **SwiftData writes on @MainActor only** - All `modelContext.insert/save` and `session.addCheckIn` must be on `@MainActor`
3. **Check-in uses scheduled day** - Use `nextCheckInDay` not `session.duration` when creating check-ins
4. **Timing penalty from captureDate** - Computed from actual date difference, not from `day` integer

<!-- BEGIN FLOW-NEXT -->
## Flow-Next

This project uses Flow-Next for task tracking. Use `.flow/bin/flowctl` instead of markdown TODOs or TodoWrite.

**Quick commands:**
```bash
.flow/bin/flowctl list                # List all epics + tasks
.flow/bin/flowctl epics               # List all epics
.flow/bin/flowctl tasks --epic fn-N   # List tasks for epic
.flow/bin/flowctl ready --epic fn-N   # What's ready
.flow/bin/flowctl show fn-N.M         # View task
.flow/bin/flowctl start fn-N.M        # Claim task
.flow/bin/flowctl done fn-N.M --summary-file s.md --evidence-json e.json
```

**Rules:**
- Use `.flow/bin/flowctl` for ALL task tracking
- Do NOT create markdown TODOs or use TodoWrite
- Re-anchor (re-read spec + status) before every task

**More info:** `.flow/bin/flowctl --help` or read `.flow/usage.md`
<!-- END FLOW-NEXT -->
