# fn-14-ofm.5 配置管理中心化

## Description
将散落在多个文件中的硬编码 URL 和配置值集中到统一的配置管理类中。

**当前问题**:
```swift
// GeminiService.swift:7
static let baseURL = "https://openrouter.ai/api/v1"

// GeminiService.swift:194
request.setValue("https://skinlab.app", forHTTPHeaderField: "HTTP-Referer")

// RoutineService.swift:294,303
static let baseURL = "https://openrouter.ai/api/v1"
```

**目标**:
1. 创建 AppConfiguration 配置管理类
2. 支持环境切换 (dev/staging/prod)
3. 替换所有硬编码值
4. 添加 API key 安全管理

## Key Files
- 新建 `/SkinLab/Core/Config/AppConfiguration.swift`
- `/SkinLab/Core/Network/GeminiService.swift:7,194,567`
- `/SkinLab/Core/Network/RoutineService.swift:294,303`

## Implementation Notes
```swift
// AppConfiguration.swift
enum AppConfiguration {
    enum Environment {
        case development
        case staging
        case production

        var apiBaseURL: String {
            switch self {
            case .development: return "https://openrouter.ai/api/v1"
            case .staging: return "https://staging-api.skinlab.app/v1"
            case .production: return "https://openrouter.ai/api/v1"
            }
        }
    }

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    // API配置
    enum API {
        static var baseURL: String { current.apiBaseURL }
        static let referer = "https://skinlab.app"
        static let timeout: TimeInterval = 30
    }

    // 功能开关
    enum Features {
        static var weatherEnabled: Bool { true }
        static var analyticsEnabled: Bool { !DEBUG }
    }

    // 限制
    enum Limits {
        static let maxPhotosPerDay = 5
        static let maxProductsPerCheckIn = 10
        static let cacheExpirationHours = 24
    }
}

// 使用
let url = URL(string: AppConfiguration.API.baseURL + "/chat/completions")!
request.setValue(AppConfiguration.API.referer, forHTTPHeaderField: "HTTP-Referer")
```

## Acceptance
- [ ] AppConfiguration 类创建
- [ ] 支持 dev/staging/prod 环境
- [ ] GeminiService URL 替换
- [ ] RoutineService URL 替换
- [ ] 所有魔法数字集中管理
- [ ] Build 成功

## Quick Commands
```bash
grep -rn "openrouter.ai" --include="*.swift" SkinLab/
grep -rn "skinlab.app" --include="*.swift" SkinLab/
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
## Summary
Created AppConfiguration for centralized configuration management with environment support (dev/staging/prod).

## Key Changes
- Created `/SkinLab/Core/Config/AppConfiguration.swift` with Environment enum and API/Limits/Features namespaces
- Updated `GeminiService.swift` to use `AppConfiguration.API.baseURL` and `.referer`
- Updated `RoutineService.swift` to use centralized configuration
- Added `SKINLAB_ENV` to Info.plist for runtime environment detection

## Commits
- e7d6f47: feat(config): Centralize configuration management with AppConfiguration
- 20083b4: fix(config): Address review feedback for centralized configuration
- 092ad0b: fix(config): Add SKINLAB_ENV to Info.plist and API key guard
## Evidence
- Commits:
- Tests:
- PRs: