# fn-2.6 Main View Integration

## Description
# Task fn-2.6: Main View Integration

**Epic**: fn-2 - Engagement Features
**Task**: fn-2.6 - Main View Integration
**Estimated Effort**: 1 day
**Dependencies**: fn-2.2, fn-2.3

---

## Overview

Integrate achievement dashboard and streak features into main navigation and views.

---

## Acceptance Criteria

- [ ] **AC-1**: Achievement dashboard entry point in ProfileView
- [ ] **AC-2**: Quick achievement preview in HomeView (top 3 in-progress badges)
- [ ] **AC-3**: Achievement notification badge on dashboard entry point
- [ ] **AC-4**: Navigation to achievement dashboard via NavigationLink
- [ ] **AC-5**: Back navigation returns to previous view correctly
- [ ] **AC-6**: Accessibility labels for all navigation elements
- [ ] **AC-7**: Achievement dashboard in tab navigation (optional)
- [ ] **AC-8**: Deep link support for achievement dashboard (skinlab://achievements)

---

## Implementation Notes

### ProfileView Integration

File: `SkinLab/Features/Profile/Views/ProfileView.swift`
- Add "Achievements" row in settings list
- Trophy icon (SF Symbol: trophy.fill)
- Show badge count: "Achievements (12)"
- Red notification badge if new achievements unlocked

### HomeView Integration

File: `SkinLab/Features/Home/Views/HomeView.swift`
- Add "Your Progress" section below streak badge
- Show 3 in-progress badges with circular progress
- Tap → navigate to achievement dashboard

### Navigation

File: `SkinLab/App/Navigation/SkinLabApp.swift`
- Add achievement dashboard to navigation path
- Handle deep links: skinlab://achievements, skinlab://achievements?id=xxx

---

## Testing

- Navigation tests: Profile → Achievements → Back
- Deep link tests from external sources
- Accessibility tests for all navigation elements

---

## References

- Epic spec: `.flow/specs/fn-2.md`
- Task fn-2.2: Achievement dashboard
- Task fn-2.3: Streak badge
## Acceptance
- [ ] TBD

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
