# fn-2.3 Streak Feature Integration

## Description
# Task fn-2.3: Streak Feature Integration

**Epic**: fn-2 - Engagement Features
**Task**: fn-2.3 - Streak Feature Integration
**Estimated Effort**: 2 days
**Dependencies**: fn-2.1

---

## Overview

Integrate streak tracking into existing views (HomeView, TrackingReportView) with visual streak indicators, check-in triggers, and streak freeze functionality.

---

## Acceptance Criteria

- [ ] **AC-1**: StreakBadgeView component displaying current streak and longest streak
- [ ] **AC-2**: StreakBadgeView added to HomeView header (prominent placement)
- [ ] **AC-3**: Streak indicator added to TrackingReportView progress section
- [ ] **AC-4**: Check-in triggers on TrackingSession completion
- [ ] **AC-5**: Same-day multiple check-ins do not increment streak
- [ ] **AC-6**: Streak resets when user misses a calendar day (gap > 1 day), per calendar-day logic
- [ ] **AC-7**: Streak freeze button appears when streak >= 3 days
- [ ] **AC-8**: Streak freeze maintains streak for 1 missed day
- [ ] **AC-9**: Local notification triggers when streak at-risk (Day 5, 7, 14 warnings)
- [ ] **AC-10**: Streak data persists and displays correctly after app restart

---

## Implementation Notes

### UI Components

File: `SkinLab/Features/Streak/Views/StreakBadgeView.swift`
- Circular badge with fire icon (SF Symbol: flame.fill)
- Large streak count in center
- "Longest: X" subtitle
- Freeze button (snowflake icon) when available
- Animated counter when streak increments

### Integration Points

File: `SkinLab/Features/Home/Views/HomeView.swift`
- Add StreakBadgeView below greeting, above action cards
- Use HStack for horizontal layout with streak and freeze button

File: `SkinLab/Features/Tracking/Views/TrackingReportView.swift`
- Add streak indicator in progress section
- Show "X day streak" with calendar icon

File: `SkinLab/Features/Tracking/Models/TrackingSession.swift`
- Call StreakTrackingService.checkIn() on session completion
- Handle timezone edge cases

### Notifications

File: `SkinLab/Services/StreakNotificationService.swift`
- Schedule notification at 8 PM local time on Day 5, 7, 14
- Notification body: "Your streak is at risk! Check in today to keep it going."
- Action button: "Open SkinLab"

---

## Testing

- Integration tests for check-in → streak increment flow
- UI tests for streak display in all views
- Notification tests (schedule, trigger, tap action)
- Timezone edge case tests

---

## References

- `TrackingReportView.swift:1-594`: Add streak indicator here
- `TrackingSession.swift:75-130`: Check-in trigger point
- Epic spec: `.flow/specs/fn-2.md`
- Task fn-2.1: StreakTrackingService
## Acceptance
- [ ] TBD

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
