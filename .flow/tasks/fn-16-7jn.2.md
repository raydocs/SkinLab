# fn-16-7jn.2 Stabilize live guidance with multi-frame smoothing

## Description
Add multi-frame smoothing for PhotoCondition (rolling window consensus/median) and require stable readiness across N frames to reduce jittery guidance.
## Acceptance
- [ ] Live guidance uses smoothed PhotoCondition derived from multiple frames
- [ ] Ready state requires N consecutive acceptable frames
- [ ] make test passes
## Done summary
- Added rolling window smoothing for PhotoCondition to stabilize guidance.
- Added stableReady gating and stability suggestion when conditions are otherwise good.
## Evidence
- Commits:
- Tests: make format-check, make lint, xcodebuild test -project SkinLab.xcodeproj -scheme SkinLab -destination "platform=iOS Simulator,name=iPhone 16e,OS=26.2" -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
- PRs:
