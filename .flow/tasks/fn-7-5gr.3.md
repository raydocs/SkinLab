# fn-7-5gr.3 创建 PredictiveAlertNotificationService

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created PredictiveAlertNotificationService following StreakNotificationService pattern. Only high severity alerts trigger push notifications; others are in-app only. Includes scheduleAlertNotification and cancelAllPredictiveAlerts methods.
## Evidence
- Commits: 952196ebe47eedf5e6c4075a3fc7e0f0f1c3604f
- Tests: xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
- PRs: