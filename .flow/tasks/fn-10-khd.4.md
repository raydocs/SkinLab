# fn-10-khd.4 拍照质量实时反馈

## Description
在用户拍摄皮肤照片时提供实时质量反馈，确保照片满足分析要求。

**检测项目**:
1. 光线检测: 亮度是否充足
2. 人脸检测: 是否检测到人脸
3. 居中检测: 人脸是否在画面中央
4. 清晰度检测: 图像是否模糊

## Key Files
- `/SkinLab/Features/Analysis/Views/CameraView.swift` - 相机视图
- 新建 `/SkinLab/Core/Utils/PhotoQualityChecker.swift` - 质量检测器

## Implementation Notes
```swift
struct PhotoQualityChecker {
    func checkBrightness(_ image: CVPixelBuffer) -> QualityResult
    func checkFaceDetection(_ image: CVPixelBuffer) async -> QualityResult
    func checkFaceCentering(_ faceRect: CGRect) -> QualityResult
    func checkSharpness(_ image: CVPixelBuffer) -> QualityResult
}

enum QualityResult {
    case ok
    case warning(String)
    case error(String)
}
```

使用Vision框架进行人脸检测，Laplacian方差计算清晰度。

## Acceptance
- [ ] 光线不足时显示提示
- [ ] 检测不到人脸时显示提示
- [ ] 人脸偏离中心时显示提示
- [ ] 图像模糊时显示提示
- [ ] 所有条件满足时显示绿色√
- [ ] 单元测试覆盖各检测逻辑

## Quick Commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/AnalysisTests
```

## Done summary
Implemented real-time photo quality feedback with sharpness detection using Laplacian variance and face centering detection. Added comprehensive unit tests covering all quality checking logic.
## Evidence
- Commits: 55aea204266fb19c444c0f01527908a5bf0f9ec9
- Tests: xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
- PRs: