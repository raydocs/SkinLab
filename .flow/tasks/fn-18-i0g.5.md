# fn-18-i0g.5 低质量照片拦截策略 FeatureFlag

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Implemented a low-quality photo blocking feature flag and enforced it in the analysis flow by rejecting unacceptable photo quality before AI analysis. Added the new flag in app configuration.

Tests: xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
## Evidence
- Commits:
- Tests: {'name': 'xcodebuild test', 'command': "xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test", 'result': 'passed'}
- PRs:
