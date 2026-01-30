# fn-16-7jn.1 Add orientation-aware Vision analysis and capture quality scoring

## Description
Update CameraService/FaceDetector to use correct Vision orientation, add VNDetectFaceCaptureQualityRequest, and replace lighting estimation with downsampled CIAreaAverage so live quality signals are more accurate.
## Acceptance
- [ ] Vision handlers receive correct orientation for front/back camera frames
- [ ] Capture quality score is used for sharpness/quality evaluation
- [ ] Lighting estimation uses downsampled CIAreaAverage
- [ ] make test passes
## Done summary
- Added Vision orientation mapping for live frames and captured images.
- Integrated VNDetectFaceCaptureQualityRequest and used it to derive sharpness.
- Replaced lighting analysis with CIAreaAverage-based brightness.
## Evidence
- Commits:
- Tests: make format-check, make lint, xcodebuild test -project SkinLab.xcodeproj -scheme SkinLab -destination "platform=iOS Simulator,name=iPhone 16e,OS=26.2" -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
- PRs:
