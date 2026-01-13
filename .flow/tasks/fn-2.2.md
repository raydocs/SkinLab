# fn-2.2 Achievement System

## Description
# Task fn-2.2: Achievement System

**Epic**: fn-2 - Engagement Features
**Task**: fn-2.2 - Achievement System
**Estimated Effort**: 3 days
**Dependencies**: fn-2.1

---

## Overview

Implement the achievement badge system with 12 initial badges across 4 categories, achievement dashboard UI, and badge unlock animations.

---

## Acceptance Criteria

- [ ] **AC-1**: 12 badges implemented (3 per category):
  - **Streaks**: 3-Day Streak, 7-Day Streak, 28-Day Streak
  - **Completeness**: First Analysis, 10 Check-ins, Complete 28-Day Cycle
  - **Social**: First Skin Twin, 5 Twin Matches
  - **Knowledge**: 5 Products Analyzed, 10 Ingredients Learned
- [ ] **AC-2**: AchievementBadgeView component renders locked and unlocked states
- [ ] **AC-3**: Locked badges show progress indicator (circular or linear)
- [ ] **AC-4**: Unlocked badges show unlock date and full color
- [ ] **AC-5**: AchievementDashboardView with tab filter by category
- [ ] **AC-6**: Badge icons using SF Symbols
- [ ] **AC-7**: Achievement unlock animation (scale + fade + particle effect)
- [ ] **AC-8**: Badge progress updates in real-time after relevant actions
- [ ] **AC-9**: Achievement data persists via SwiftData
- [ ] **AC-10**: VoiceOver support for all badge elements

---

## Implementation Notes

### Badge Definitions

File: `SkinLab/Models/AchievementDefinitions.swift`
- Define all 12 badges with metadata
- Icon names, titles (Chinese), descriptions
- Requirement thresholds

### UI Components

File: `SkinLab/Features/Achievements/Views/AchievementBadgeView.swift`
- Circular badge icon with lock overlay when locked
- Progress ring showing percentage
- Tap for detail modal

File: `SkinLab/Features/Achievements/Views/AchievementDashboardView.swift`
- Grid layout (2 columns on phone, 3 on tablet)
- Tab filter: All, Streaks, Completeness, Social, Knowledge
- Search bar for badge titles
- Sort by: Unlocked first, then by progress

File: `SkinLab/Features/Achievements/Views/AchievementDetailView.swift`
- Large badge preview
- Full description
- Progress bar with current/max
- Share button (if unlocked)
- "How to unlock" hint (if locked)

### Animations

File: `SkinLab/Features/Achievements/Views/AchievementUnlockAnimationView.swift`
- Confetti particle effect using SwiftUI
- Scale animation: 0.8 → 1.1 → 1.0 with spring
- Fade in with glow effect
- Haptic feedback (.success)

---

## Testing

- UI tests for badge rendering in all states
- Animation tests with reduceMotion enabled
- Accessibility tests with VoiceOver
- Performance tests for badge grid rendering

---

## References

- `AnalyticsVisualizationViews.swift:327-353`: Badge UI patterns
- Epic spec: `.flow/specs/fn-2.md`
- Task fn-2.1: Data models and services
## Acceptance
- [ ] TBD

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
