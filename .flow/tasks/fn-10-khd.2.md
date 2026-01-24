# fn-10-khd.2 Photo数据流修复

## Description
确保照片分析结果正确传递到CheckIn和下游组件，修复数据流断点。

**审查路径**: AnalysisView → SkinAnalysis → CheckIn

**目标**:
1. 审计数据流，确认断点位置
2. SkinAnalysis正确保存到SwiftData
3. CheckIn正确关联analysisId
4. 标准化照片正确存储

## Key Files
- `/SkinLab/Features/Analysis/Views/AnalysisView.swift` - 分析入口
- `/SkinLab/Features/Analysis/Services/SkinAnalysisService.swift` - 分析服务
- `/SkinLab/Features/Tracking/Models/TrackingSession.swift` - CheckIn模型
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift` - 报告展示

## Investigation Points
1. AnalysisView完成分析后的SkinAnalysis保存逻辑
2. CheckIn创建时的analysis关联
3. Photo标准化数据(standardized image)的存储路径
4. 下游组件的数据访问方式

## Acceptance
- [ ] 审计完成，数据流清晰
- [ ] 断点修复（如有）
- [ ] SkinAnalysis正确保存到SwiftData
- [ ] CheckIn正确关联analysisId
- [ ] 报告页能访问完整分析数据
- [ ] 添加数据流单元测试

## Quick Commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/AnalysisTests
```

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
