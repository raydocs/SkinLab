# fn-15-rz5.4 Fix failing unit tests

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
- Added API key override support in GeminiService and injected a test key in GeminiServiceTests.
- Re-ran unit tests successfully on iPhone 16e simulator.
## Evidence
- Commits:
- Tests: xcodebuild test -project SkinLab.xcodeproj -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 16e' -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
- PRs:
