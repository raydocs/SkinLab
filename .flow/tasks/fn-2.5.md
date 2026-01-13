# fn-2.5 Celebration & Sharing

## Description
# Task fn-2.5: Celebration & Sharing

**Epic**: fn-2 - Engagement Features
**Task**: fn-2.5 - Celebration & Sharing
**Estimated Effort**: 2 days
**Dependencies**: fn-2.2, fn-2.3

---

## Overview

Implement celebration animations for milestone achievements and share-to-WeChat functionality for viral loop.

---

## Acceptance Criteria

- [ ] **AC-1**: StreakCelebrationView with confetti animation
- [ ] **AC-2**: Celebration triggers on milestone streaks (7, 14, 28 days)
- [ ] **AC-3**: Celebration triggers on badge unlocks
- [ ] **AC-4**: Confetti animation respects reduceMotion accessibility setting
- [ ] **AC-5**: Sharing uses iOS Share Sheet (WeChat appears if installed)
- [ ] **AC-6**: Share preview image generation with badge, streak, and branding
- [ ] **AC-7**: Share button shows in AchievementDetailView when badge is unlocked
- [ ] **AC-8**: Analytics events: celebration_shown, achievement_shared
- [ ] **AC-9**: Share Sheet still works even if WeChat not installed
- [ ] **AC-10**: Celebration dismissible with tap or swipe

---

## Implementation Notes

### Celebration UI

File: `SkinLab/Features/Celebration/Views/StreakCelebrationView.swift`
- Full-screen overlay with blur background
- Large milestone number with animated count-up
- Confetti particle system (500+ particles)
- "Keep it going!" message
- Dismiss button

File: `SkinLab/Features/Celebration/Views/ConfettiParticleSystem.swift`
- SwiftUI particle emitter
- Colors: SkinLab brand palette
- Physics: gravity, velocity, fade
- Respects UIAccessibility.isReduceMotionEnabled

### iOS Share Sheet Sharing (WeChat-compatible)

File: `SkinLab/Features/Sharing/Services/AchievementShareService.swift`
- Uses UIActivityViewController (Share Sheet) as the primary mechanism
- If WeChat is installed, WeChat appears as an option automatically
- No WeChat SDK integration required for P0
- Capability detection = can present share sheet + can generate preview image

File: `SkinLab/Core/Utils/ShareCardRenderer.swift` (reuse existing if available)
- Render badge and streak to UIImage
- Add branding and CTA ("Download SkinLab")
- 1080x1080 for social media sharing
- Image contains only: badge/streak/branding (no user photos by default)

### Analytics

File: `SkinLab/Services/AnalyticsEvents+Engagement.swift`
- celebration_shown: {milestone, type}
- achievement_shared: {achievement_id, platform}

---

## Testing

- UI tests for celebration display and dismissal
- Animation tests with reduceMotion
- Share tests with WeChat installed/not installed
- Analytics validation

---

## References

- Epic spec: `.flow/specs/fn-2.md`
- Task fn-2.2: Achievement system
- Task fn-2.3: Streak feature integration
## Acceptance
- [ ] TBD

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
