# fn-4-osk.5 Add GeminiService unit tests with mocks

## Description
为 GeminiService 添加单元测试，使用 URLProtocol mock 测试 API 调用逻辑。

**Size:** M
**Files:**
- `SkinLabTests/Core/GeminiServiceTests.swift` (new)
- `SkinLabTests/Mocks/MockURLProtocol.swift` (new)

## Approach

1. 创建 `MockURLProtocol` 继承 `URLProtocol` 拦截网络请求
2. 配置 `URLSessionConfiguration.protocolClasses` 使用 mock
3. 传入配置好的 `URLSession` 到 `GeminiService(session:)`
4. 测试成功 API 响应解析
5. 测试错误处理
6. 测试请求构建逻辑 (endpoint, headers, body)

## Key Context

- GeminiService 接受 `URLSession` 参数，不是协议化的 transport
- Mock 方式：使用 `URLProtocol` 子类 + `URLSessionConfiguration.protocolClasses`
- 需要测试 skin analysis 和 ingredient analysis 两个主要功能
- 不需要真实 API 调用 - 使用 mock responses

## API Key Test Strategy (唯一权威方案 - 命令行/CI 可复现)

GeminiService 入口有 `guard !GeminiConfig.apiKey.isEmpty` 检查。为确保测试可执行：

**方案：命令行注入环境变量**
```bash
OPENROUTER_API_KEY=dummy xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15'
```

Evidence 中记录实际运行命令。

## Test Cases

1. `testAnalyzeSkinWithValidResponse` - 有效响应正确解析
2. `testAnalyzeSkinWithNetworkError` - 网络错误正确处理
3. `testAnalyzeSkinWithInvalidJSON` - 无效 JSON 错误处理
4. `testRequestConstruction` - 验证请求构建：
   - 通过调用 `GeminiService(session:).analyzeSkin(...)` 触发真实构建请求
   - 在 `MockURLProtocol.startLoading()` 内捕获 `request` 对象
   - 对 `request.url`/`request.allHTTPHeaderFields`/`request.httpBody` 结构化校验
   - **不改** `buildAnalysisRequest` 的访问级别
   - 断言内容：
     - `request.url` 包含 `/chat/completions`
     - `Authorization` header 包含 `Bearer ` 前缀
     - `Content-Type == application/json`
     - body JSON 中包含 `data:image/jpeg;base64,` 前缀 + 非空 base64 字符串
5. `testAnalyzeIngredientsWithValidResponse` - 成分分析有效响应

## Image Encoding Test Strategy (避免脆弱断言)

断言策略：
- **不要**断言 base64 精确值（JPEG 编码/压缩/元数据会导致不稳定）
- **应该**在 `MockURLProtocol` 中捕获 request，验证结构而非精确内容

## References

- `SkinLab/Core/Network/GeminiService.swift`
- URLProtocol mocking pattern: https://developer.apple.com/documentation/foundation/urlprotocol

## Acceptance
- [ ] 创建 `GeminiServiceTests.swift`
- [ ] 创建 `MockURLProtocol.swift`
- [ ] 新文件已添加到 SkinLabTests target
- [ ] 使用 URLProtocol mock 而非真实 API 调用
- [ ] `xcodebuild test` 运行时注入 `OPENROUTER_API_KEY=dummy`（命令行或 CI）
- [ ] 测试验证 endpoint URL 使用正确插值
- [ ] 测试验证 Authorization header 包含 `Bearer ` 前缀
- [ ] 测试验证 Content-Type header
- [ ] 测试成功路径和错误处理
- [ ] 至少 5 个测试用例
- [ ] 所有测试通过

## Done summary
Added GeminiService unit tests with URLProtocol mocks. Created MockURLProtocol for intercepting network requests and GeminiServiceTests with 10 test cases covering valid response parsing, error handling, and request construction validation. All tests pass.
## Evidence
- Commits: 4db3de7fce53bbf0b1d407b4c7e5bad2b3eb4f79
- Tests: OPENROUTER_API_KEY=dummy xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SkinLabTests/GeminiServiceTests
- PRs: