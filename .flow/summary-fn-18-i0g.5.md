Implemented a low-quality photo blocking feature flag and enforced it in the analysis flow by rejecting unacceptable photo quality before AI analysis. Added the new flag in app configuration.

Tests: xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
