# fn-18-i0g.4 ConfidenceScoreCardView UI + retake flow

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Added ConfidenceScoreCardView and integrated it into the analysis result UI, including photo quality issue display and retake action wiring. Updated analysis flow to pass photo quality report data and added theme color support.

Tests: xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
## Evidence
- Commits:
- Tests: {'name': 'xcodebuild test', 'command': "xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test", 'result': 'passed'}
- PRs:
