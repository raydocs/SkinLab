# fn-16-7jn Camera accuracy & capture feedback improvements

## Overview
Improve live camera guidance accuracy and post-capture validation so users get more reliable “ready to capture” feedback and fewer misclassified shots.

## Scope
- CameraService + FaceDetector (Vision orientation, quality metrics, lighting/sharpness evaluation)
- Live guidance stability (multi-frame smoothing)
- Post-capture validation in CameraPreviewView
- Update PhotoStandardizationMetadata mapping as needed

## Approach
1) Orientation-aware Vision: derive correct CGImagePropertyOrientation from camera position + sample buffer, feed Vision requests accordingly, add VNDetectFaceCaptureQualityRequest to improve sharpness/quality accuracy, and replace lighting heuristic with downsampled CIAreaAverage.
2) Live smoothing: maintain a rolling window of PhotoCondition snapshots and compute a consensus/median result, only mark isReady after N stable frames.
3) Post-capture validation: run a full-quality pass on the captured image; if it fails, present retake guidance and mark metadata accordingly.

## Quick commands
<!-- Required: at least one smoke command for the repo -->
- `make test`

## Acceptance
- [ ] Vision requests use correct orientation and capture quality metrics
- [ ] Live guidance uses multi-frame smoothing to reduce jitter
- [ ] Post-capture validation prompts users on failed conditions
- [ ] Tests/linters pass

## References
- SkinLab/Core/Utils/CameraService.swift
- SkinLab/Features/Analysis/Views/CameraPreviewView.swift
