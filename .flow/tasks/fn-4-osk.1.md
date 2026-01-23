# fn-4-osk.1 Fix GeminiService string interpolation bugs

## Description
修复 GeminiService.swift 中 `buildAnalysisRequest` 方法的字符串插值错误。当前代码使用 `(` 而非 `\(` 进行 Swift 字符串插值，导致 API URL 构建失败。

**Size:** S
**Files:**
- `SkinLab/Core/Network/GeminiService.swift`

## Approach

1. 打开 GeminiService.swift
2. 定位 `buildAnalysisRequest` 方法
3. 修复三处字符串插值：
   - `endpoint` URL 构建
   - `Authorization` header
   - `base64Image` URL
4. 参考同文件中 `buildIngredientAnalysisRequest` 的正确实现模式

## Key Context

当前错误代码 (in buildAnalysisRequest):
```swift
let endpoint = "(GeminiConfig.baseURL)/chat/completions"
request.setValue("Bearer (GeminiConfig.apiKey)", forHTTPHeaderField: "Authorization")
"url": "data:image/jpeg;base64,(base64Image)"
```

应该是:
```swift
let endpoint = "\(GeminiConfig.baseURL)/chat/completions"
request.setValue("Bearer \(GeminiConfig.apiKey)", forHTTPHeaderField: "Authorization")
"url": "data:image/jpeg;base64,\(base64Image)"
```

## References

- Correct pattern in `buildIngredientAnalysisRequest` method (same file)

## Acceptance
- [ ] `buildAnalysisRequest` 中 endpoint 使用 `\(GeminiConfig.baseURL)`
- [ ] `buildAnalysisRequest` 中 Authorization header 使用 `\(GeminiConfig.apiKey)`
- [ ] `buildAnalysisRequest` 中 base64 image URL 使用 `\(base64Image)`
- [ ] 项目可以成功编译
- [ ] 手动测试 AI 皮肤分析功能正常工作

## Done summary
Fixed all string interpolation bugs in GeminiService.swift - both in buildAnalysisRequest (endpoint URL, Authorization header, base64 image URL) and buildPrompt historyContext (7 interpolation fixes for historical analysis data). API calls and historical context prompts will now work correctly.
## Evidence
- Commits: 5a3e1e283e5ebb36a1e10f68ad3e7fe6e89f8d2f, 5cd82173cea032d0f7dda782d56fa82694e47653
- Tests: xcodebuild -scheme SkinLab build
- PRs: