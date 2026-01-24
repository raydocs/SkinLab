# fn-9-gf8: 天气环境整合 - Weather & Environment Integration

## Problem Statement
护肤建议未考虑实时环境因素。当前仅有静态的 `ClimateType`（用户设置）和季节概念，缺乏：
- 实时天气数据（温度、湿度、UV指数）
- 空气质量/污染指数
- 天气与皮肤状态的相关性分析

**市场痛点**: "今天紫外线很强，但 app 还是给我通用建议" —— 护肤建议脱离实际环境。

## Scope
- 集成天气 API（WeatherKit 或 OpenWeatherMap）
- 获取用户位置
- 实时天气数据展示
- 天气与皮肤相关性分析
- 基于天气的护肤建议

## Approach

### 1. 数据模型
```swift
// 新建 WeatherModels.swift
struct WeatherSnapshot: Codable, Sendable {
    let temperature: Double      // 摄氏度
    let humidity: Double         // 百分比 0-100
    let uvIndex: Int             // 0-11+
    let airQuality: AQILevel
    let condition: WeatherCondition
    let recordedAt: Date
    let location: String?        // 城市名

    var uvLevel: UVLevel {
        switch uvIndex {
        case 0...2: return .low
        case 3...5: return .moderate
        case 6...7: return .high
        case 8...10: return .veryHigh
        default: return .extreme
        }
    }
}

enum AQILevel: String, Codable {
    case good = "优"
    case moderate = "良"
    case unhealthySensitive = "轻度污染"
    case unhealthy = "中度污染"
    case veryUnhealthy = "重度污染"
    case hazardous = "严重污染"
}

enum WeatherCondition: String, Codable {
    case sunny, cloudy, rainy, windy, snowy, foggy
}

enum UVLevel: String, Codable {
    case low = "低"
    case moderate = "中等"
    case high = "高"
    case veryHigh = "很高"
    case extreme = "极高"
}
```

### 2. 服务架构
```swift
// 新建 WeatherService.swift
actor WeatherService: WeatherServiceProtocol {
    static let shared = WeatherService()

    private var cache: (data: WeatherSnapshot, expiry: Date)?
    private let cacheInterval: TimeInterval = 3600 // 1小时

    func getCurrentWeather() async throws -> WeatherSnapshot
    func getWeatherForecast(days: Int) async throws -> [WeatherSnapshot]
}

// 新建 LocationManager.swift
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    func requestLocation() async throws -> CLLocation
    func requestPermission() async -> Bool
}
```

### 3. API 选择
| API | 优点 | 缺点 |
|-----|------|------|
| **WeatherKit** | 原生、免费500k/月 | 仅 iOS 16+ |
| **OpenWeatherMap** | 免费1M/月、包含AQI | 需 API key |

建议: 优先使用 WeatherKit，降级到 OpenWeatherMap

### 4. 整合点

**CheckIn 扩展**:
```swift
// TrackingSession.swift
struct CheckIn {
    // 现有字段...
    let weather: WeatherSnapshot?  // 新增
}
```

**LifestyleCorrelation 扩展**:
```swift
// LifestyleCorrelationAnalyzer.swift
enum LifestyleFactorKey {
    // 现有...
    case humidity
    case uvIndex
    case airQuality
}
```

**季节调整替换**:
```swift
// ForecastEngine.swift
// 将 getSeasonalAdjustment() 替换为基于实时天气的调整
func getWeatherAdjustment(weather: WeatherSnapshot) -> Double
```

### 5. UI 展示
- 首页天气卡片（温度、UV、湿度、AQI）
- 天气相关护肤提醒
- 报告中显示天气相关性分析

## Quick commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SkinLabTests/Tracking
```

## Acceptance
- [ ] 成功获取用户位置权限
- [ ] 获取并展示实时天气数据
- [ ] CheckIn 记录关联天气信息
- [ ] 天气因素纳入相关性分析
- [ ] 基于天气的护肤建议
- [ ] 天气数据缓存（减少 API 调用）
- [ ] 无网络时优雅降级

## Key Files
- 新建 `/SkinLab/Core/Network/WeatherService.swift`
- 新建 `/SkinLab/Core/Utils/LocationManager.swift`
- 新建 `/SkinLab/Features/Weather/Models/WeatherModels.swift`
- 新建 `/SkinLab/Features/Weather/Views/WeatherCardView.swift`
- `/SkinLab/Features/Tracking/Models/TrackingSession.swift` - CheckIn 扩展
- `/SkinLab/Features/Tracking/Services/LifestyleCorrelationAnalyzer.swift` - 相关性分析扩展
- `/SkinLab/Features/Tracking/Services/ForecastEngine.swift` - 预测调整

## Technical Details

### WeatherKit 集成
```swift
import WeatherKit

actor WeatherService {
    private let weatherService = WeatherService.shared

    func getCurrentWeather(location: CLLocation) async throws -> WeatherSnapshot {
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        return WeatherSnapshot(
            temperature: current.temperature.value,
            humidity: current.humidity * 100,
            uvIndex: current.uvIndex.value,
            airQuality: .good, // WeatherKit 不提供 AQI
            condition: mapCondition(current.condition),
            recordedAt: current.date,
            location: nil
        )
    }
}
```

### 权限配置
Info.plist 需添加:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>获取位置以提供本地天气和护肤建议</string>
```

### 天气-皮肤相关性规则
| 环境因素 | 皮肤影响 | 建议 |
|----------|----------|------|
| 高UV (6+) | 光老化、色斑 | 加强防晒、抗氧化 |
| 低湿度 (<40%) | 干燥、脱皮 | 加强保湿、使用精华 |
| 高污染 | 毛孔堵塞、暗沉 | 深层清洁、抗氧化 |
| 高温 (>30°C) | 出油、毛孔 | 控油、清爽质地 |
| 低温 (<10°C) | 屏障受损、敏感 | 滋润、修复 |

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 位置权限被拒 | 提供手动输入城市选项 |
| API 配额用尽 | 智能缓存 + 减少刷新频率 |
| WeatherKit 不可用 | 降级到 OpenWeatherMap |
| 无网络 | 显示上次缓存数据 + 提示 |

## Dependencies
- CoreLocation framework
- WeatherKit framework (iOS 16+)
- 可选: OpenWeatherMap API key

## References
- `GeminiService.swift` - Actor 服务模式参考
- `ForecastEngine.swift:277-285` - getSeasonalAdjustment
- `UserProfile.swift:88-116` - ClimateType/UVExposureLevel 现有定义
