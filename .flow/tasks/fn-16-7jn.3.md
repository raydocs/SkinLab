# fn-16-7jn.3 Post-capture validation and retake UX

## Description
Run a full-quality validation pass after capture and prompt retake when conditions are not acceptable; ensure metadata reflects the validated conditions.
## Acceptance
- [ ] Captured photo is re-evaluated with high-precision validation
- [ ] Failed validation triggers retake guidance UI
- [ ] Stored PhotoStandardizationMetadata reflects validated results
- [ ] make test passes
## Done summary
- Added post-capture validation for full-quality checks before accepting a photo.
- Added retake prompt with optional user override and metadata capture.
## Evidence
- Commits:
- Tests: make format-check, make lint, xcodebuild test -project SkinLab.xcodeproj -scheme SkinLab -destination "platform=iOS Simulator,name=iPhone 16e,OS=26.2" -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
- PRs:
