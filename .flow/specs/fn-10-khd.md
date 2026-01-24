# fn-10-khd: 关键功能修复 - Critical Feature Fixes

## Problem Statement
代码审查发现多个关键功能未完成或存在问题：
1. **产品选择器**: TrackingView.swift:479-495 的产品选择功能返回空视图
2. **Photo标准化**: 照片分析结果未正确传递到下游组件
3. **Freeze功能**: HomeView.swift:133 有TODO但未实现连续打卡冻结
4. **实时反馈**: 拍照时缺少质量反馈（光线、角度、清晰度）

**用户痛点**: "选产品没反应"、"昨天忘记打卡连续记录断了"

## Scope
- 实现产品选择器UI和逻辑
- 修复Photo分析数据流
- 完成Freeze冻结功能
- 添加拍照质量实时反馈

## Approach

### Task 1: 产品选择器实现
```swift
// TrackingView.swift:479-495 现状
private func productPicker(for day: Date) -> some View {
    EmptyView() // TODO: Implement product picker
}

// 实现目标
// 1. 显示用户产品库（从SwiftData查询）
// 2. 支持多选
// 3. 搜索/筛选功能
// 4. 快速添加新产品入口
```

### Task 2: Photo数据流修复
- 检查 `AnalysisView` → `SkinAnalysis` → `CheckIn` 数据传递
- 确保standardized photo正确存储
- 验证downstream组件能访问分析结果

### Task 3: Freeze功能完成
```swift
// HomeView.swift:133 现状
// TODO: Implement freeze usage

// StreakTrackingService.swift:153-176 已有
func useStreakFreeze(now: Date = Date()) -> Bool

// 需要:
// 1. UI展示freeze可用数量
// 2. 使用freeze的触发逻辑
// 3. 自动检测断签并提示使用
```

### Task 4: 拍照质量反馈
- 实时光线检测（亮度阈值）
- 人脸检测与居中提示
- 模糊度检测
- 视觉提示overlay

## Quick commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/TrackingTests
```

## Acceptance
- [ ] 产品选择器可以选择/取消选择产品
- [ ] 产品选择器有搜索功能
- [ ] Photo分析结果正确传递到CheckIn
- [ ] Freeze功能UI显示可用数量
- [ ] 用户可手动使用Freeze
- [ ] 断签时自动提示使用Freeze
- [ ] 拍照时有光线/居中/清晰度提示
- [ ] 单元测试覆盖核心逻辑

## Key Files
- `/SkinLab/Features/Tracking/Views/TrackingView.swift:479-495` - 产品选择器
- `/SkinLab/Features/Analysis/Views/HomeView.swift:133` - Freeze TODO
- `/SkinLab/Features/Engagement/Services/StreakTrackingService.swift:153-176` - useStreakFreeze
- `/SkinLab/Features/Analysis/Views/AnalysisView.swift` - Photo分析
- `/SkinLab/Features/Analysis/Views/CameraView.swift` - 相机视图

## Technical Details

### 产品选择器数据模型
```swift
// 复用现有 Product 模型
@Query private var products: [Product]

// 选择状态
@State private var selectedProductIds: Set<UUID> = []
```

### Freeze自动检测
```swift
// 在StreakTrackingService中添加
func shouldSuggestFreeze() -> Bool {
    let metrics = getOrCreateMetrics()
    let lastCheckIn = // 获取最后打卡日期
    return Calendar.current.isDateInYesterday(lastCheckIn) == false
        && metrics.streakFreezesAvailable > 0
        && metrics.currentStreak > 0
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 产品库为空 | 显示空状态引导添加产品 |
| Freeze用尽 | 明确提示剩余数量 |
| 光线检测不准 | 提供手动覆盖选项 |

## Dependencies
- Vision framework (人脸检测)
- SwiftData (产品查询)
- 现有 StreakTrackingService

## References
- `StreakTrackingService.swift:153-176` - useStreakFreeze 实现
- `TrackingView.swift` - 现有打卡UI模式
- `CameraView.swift` - 相机捕获逻辑
