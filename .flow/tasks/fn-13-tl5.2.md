# fn-13-tl5.2 SkinMatcher批处理优化

## Description
优化SkinMatcher服务，支持批量处理减少AI调用次数。

**当前问题**: 逐条处理皮肤数据，每次分析都单独调用AI。

**目标**:
1. 支持批量分析
2. 合并AI请求
3. 减少50%以上的API调用

## Key Files
- `/SkinLab/Core/Network/SkinMatcher.swift` - 皮肤匹配服务
- `/SkinLab/Core/Network/GeminiService.swift` - AI服务

## Implementation Notes
```swift
// 现有：单条处理
func findSkinTwins(for analysis: SkinAnalysis) async throws -> [SkinTwin]

// 优化：批量处理
func findSkinTwinsBatch(for analyses: [SkinAnalysis]) async throws -> [[SkinTwin]] {
    // 将多个分析合并到一个prompt
    let batchPrompt = buildBatchPrompt(analyses)

    // 单次AI调用
    let response = try await geminiService.analyze(prompt: batchPrompt)

    // 解析批量结果
    return parseBatchResponse(response, count: analyses.count)
}

// 调用端适配
func processAnalyses(_ analyses: [SkinAnalysis]) async throws {
    // 分批处理，每批最多5个
    for batch in analyses.chunked(into: 5) {
        let results = try await findSkinTwinsBatch(for: batch)
        // 处理结果
    }
}
```

## Acceptance
- [ ] SkinMatcher支持批量处理
- [ ] 单次可处理多个分析
- [ ] API调用减少50%以上
- [ ] 批处理失败时可回退到单条
- [ ] 单元测试覆盖批处理逻辑

## Quick Commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/NetworkTests
```

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
