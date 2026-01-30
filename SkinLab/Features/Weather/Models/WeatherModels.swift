import Foundation
import SwiftUI

// MARK: - Weather Snapshot

/// 天气快照数据
/// 记录某一时刻的天气环境信息
struct WeatherSnapshot: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let temperature: Double // 摄氏度
    let humidity: Double // 百分比 0-100
    let uvIndex: Int // 0-11+
    let airQuality: AQILevel
    let condition: WeatherCondition
    let recordedAt: Date
    let location: String? // 城市名

    init(
        id: UUID = UUID(),
        temperature: Double,
        humidity: Double,
        uvIndex: Int,
        airQuality: AQILevel,
        condition: WeatherCondition,
        recordedAt: Date = Date(),
        location: String? = nil
    ) {
        self.id = id
        self.temperature = temperature
        self.humidity = humidity
        self.uvIndex = uvIndex
        self.airQuality = airQuality
        self.condition = condition
        self.recordedAt = recordedAt
        self.location = location
    }

    // MARK: - Computed Properties

    /// UV等级（基于UV指数计算）
    var uvLevel: UVLevel {
        switch uvIndex {
        case 0 ... 2: .low
        case 3 ... 5: .moderate
        case 6 ... 7: .high
        case 8 ... 10: .veryHigh
        default: .extreme
        }
    }

    /// 格式化的温度显示
    var temperatureDisplay: String {
        String(format: "%.0f°C", temperature)
    }

    /// 格式化的湿度显示
    var humidityDisplay: String {
        String(format: "%.0f%%", humidity)
    }

    /// 湿度等级描述
    var humidityLevel: String {
        switch humidity {
        case 0 ..< 30: "干燥"
        case 30 ..< 50: "舒适"
        case 50 ..< 70: "适中"
        case 70 ..< 85: "潮湿"
        default: "非常潮湿"
        }
    }

    /// 温度舒适度描述
    var temperatureLevel: String {
        switch temperature {
        case ..<10: "寒冷"
        case 10 ..< 18: "凉爽"
        case 18 ..< 26: "舒适"
        case 26 ..< 32: "温暖"
        default: "炎热"
        }
    }
}

// MARK: - AQI Level

/// 空气质量指数等级
/// 采用中国标准AQI分级
enum AQILevel: String, Codable, Sendable, CaseIterable, Identifiable {
    case good = "优"
    case moderate = "良"
    case unhealthySensitive = "轻度污染"
    case unhealthy = "中度污染"
    case veryUnhealthy = "重度污染"
    case hazardous = "严重污染"

    var id: String {
        rawValue
    }

    // MARK: - Display Properties

    /// 图标名称 (SF Symbols)
    var icon: String {
        switch self {
        case .good: "leaf.fill"
        case .moderate: "leaf"
        case .unhealthySensitive: "aqi.low"
        case .unhealthy: "aqi.medium"
        case .veryUnhealthy: "aqi.high"
        case .hazardous: "exclamationmark.triangle.fill"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .good: .green
        case .moderate: .yellow
        case .unhealthySensitive: .orange
        case .unhealthy: .red
        case .veryUnhealthy: .purple
        case .hazardous: .brown
        }
    }

    /// 详细描述
    var description: String {
        switch self {
        case .good:
            "空气质量令人满意，基本无空气污染"
        case .moderate:
            "空气质量可接受，少数敏感人群可能有不适"
        case .unhealthySensitive:
            "敏感人群可能出现健康影响"
        case .unhealthy:
            "可能对人体健康产生影响"
        case .veryUnhealthy:
            "健康风险增加，应减少户外活动"
        case .hazardous:
            "健康警告，避免户外活动"
        }
    }

    /// 护肤建议
    var skincareTip: String {
        switch self {
        case .good:
            "空气清新，正常护肤即可"
        case .moderate:
            "可正常护肤，注意基础清洁"
        case .unhealthySensitive:
            "加强清洁，使用抗氧化产品"
        case .unhealthy:
            "深层清洁，加强屏障修复"
        case .veryUnhealthy:
            "减少外出，回家后彻底清洁"
        case .hazardous:
            "避免外出，使用物理防护"
        }
    }

    /// AQI数值范围参考
    var aqiRange: String {
        switch self {
        case .good: "0-50"
        case .moderate: "51-100"
        case .unhealthySensitive: "101-150"
        case .unhealthy: "151-200"
        case .veryUnhealthy: "201-300"
        case .hazardous: ">300"
        }
    }
}

// MARK: - Weather Condition

/// 天气状况
enum WeatherCondition: String, Codable, Sendable, CaseIterable, Identifiable {
    case sunny
    case cloudy
    case rainy
    case windy
    case snowy
    case foggy

    var id: String {
        rawValue
    }

    // MARK: - Display Properties

    /// 中文显示名称
    var displayName: String {
        switch self {
        case .sunny: "晴天"
        case .cloudy: "多云"
        case .rainy: "雨天"
        case .windy: "大风"
        case .snowy: "下雪"
        case .foggy: "雾天"
        }
    }

    /// 图标名称 (SF Symbols)
    var icon: String {
        switch self {
        case .sunny: "sun.max.fill"
        case .cloudy: "cloud.fill"
        case .rainy: "cloud.rain.fill"
        case .windy: "wind"
        case .snowy: "cloud.snow.fill"
        case .foggy: "cloud.fog.fill"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .sunny: .orange
        case .cloudy: .gray
        case .rainy: .blue
        case .windy: .teal
        case .snowy: .cyan
        case .foggy: .secondary
        }
    }

    /// 护肤建议
    var skincareTip: String {
        switch self {
        case .sunny:
            "紫外线较强，注意防晒保护"
        case .cloudy:
            "仍需防晒，紫外线可穿透云层"
        case .rainy:
            "湿度较高，注意控油和清洁"
        case .windy:
            "皮肤易干燥，加强保湿"
        case .snowy:
            "雪地反射紫外线，注意防晒"
        case .foggy:
            "空气污染物易滞留，加强清洁"
        }
    }
}

// MARK: - UV Level

/// 紫外线等级
/// 基于UV指数划分的风险等级
enum UVLevel: String, Codable, Sendable, CaseIterable, Identifiable {
    case low = "低"
    case moderate = "中等"
    case high = "高"
    case veryHigh = "很高"
    case extreme = "极高"

    var id: String {
        rawValue
    }

    // MARK: - Display Properties

    /// 图标名称 (SF Symbols)
    var icon: String {
        switch self {
        case .low: "sun.min"
        case .moderate: "sun.max"
        case .high: "sun.max.fill"
        case .veryHigh: "sun.max.trianglebadge.exclamationmark"
        case .extreme: "exclamationmark.triangle.fill"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .low: .green
        case .moderate: .yellow
        case .high: .orange
        case .veryHigh: .red
        case .extreme: .purple
        }
    }

    /// UV指数范围
    var indexRange: String {
        switch self {
        case .low: "0-2"
        case .moderate: "3-5"
        case .high: "6-7"
        case .veryHigh: "8-10"
        case .extreme: "11+"
        }
    }

    /// 详细描述
    var description: String {
        switch self {
        case .low:
            "紫外线较弱，可正常外出"
        case .moderate:
            "紫外线适中，建议使用防晒"
        case .high:
            "紫外线较强，需做好防晒"
        case .veryHigh:
            "紫外线很强，避免长时间暴晒"
        case .extreme:
            "紫外线极强，尽量避免外出"
        }
    }

    /// 防晒建议
    var sunscreenAdvice: String {
        switch self {
        case .low:
            "日常防晒即可，SPF15+"
        case .moderate:
            "建议SPF30+，每3小时补涂"
        case .high:
            "必须SPF30+，每2小时补涂"
        case .veryHigh:
            "SPF50+，配合物理防晒"
        case .extreme:
            "SPF50+ PA++++，全面物理遮挡"
        }
    }

    /// 护肤建议
    var skincareTip: String {
        switch self {
        case .low:
            "正常护肤即可"
        case .moderate:
            "注意防晒，可使用抗氧化精华"
        case .high:
            "加强防晒和抗氧化，晒后修复"
        case .veryHigh:
            "高倍防晒，晚间使用修复产品"
        case .extreme:
            "避免外出，使用高强度修复产品"
        }
    }
}

// MARK: - Weather Impact Assessment

/// 天气对皮肤的影响评估
extension WeatherSnapshot {
    /// 综合环境评分 (0-100)
    /// 越高表示对皮肤越友好
    var skinFriendlinessScore: Int {
        var score = 100

        // UV影响 (-30 max)
        switch uvLevel {
        case .low: break
        case .moderate: score -= 10
        case .high: score -= 20
        case .veryHigh: score -= 25
        case .extreme: score -= 30
        }

        // 空气质量影响 (-25 max)
        switch airQuality {
        case .good: break
        case .moderate: score -= 5
        case .unhealthySensitive: score -= 10
        case .unhealthy: score -= 15
        case .veryUnhealthy: score -= 20
        case .hazardous: score -= 25
        }

        // 湿度影响 (-15 max)
        if humidity < 30 {
            score -= 15 // 太干燥
        } else if humidity < 40 {
            score -= 10
        } else if humidity > 80 {
            score -= 10 // 太潮湿
        } else if humidity > 70 {
            score -= 5
        }

        // 温度影响 (-15 max)
        if temperature < 5 {
            score -= 15 // 太冷
        } else if temperature < 10 {
            score -= 10
        } else if temperature > 35 {
            score -= 15 // 太热
        } else if temperature > 30 {
            score -= 10
        }

        // 天气状况影响 (-15 max)
        switch condition {
        case .sunny: break
        case .cloudy: break
        case .rainy: score -= 5
        case .windy: score -= 10
        case .snowy: score -= 10
        case .foggy: score -= 15
        }

        return max(0, score)
    }

    /// 综合建议
    var overallSkincareTip: String {
        var tips: [String] = []

        // 根据UV等级添加建议
        if uvIndex >= 3 {
            tips.append(uvLevel.sunscreenAdvice)
        }

        // 根据湿度添加建议
        if humidity < 40 {
            tips.append("空气干燥，加强保湿")
        } else if humidity > 75 {
            tips.append("湿度较高，注意控油")
        }

        // 根据空气质量添加建议
        if airQuality != .good, airQuality != .moderate {
            tips.append(airQuality.skincareTip)
        }

        // 根据温度添加建议
        if temperature > 30 {
            tips.append("高温天气，使用清爽型产品")
        } else if temperature < 10 {
            tips.append("低温天气，加强屏障修复")
        }

        if tips.isEmpty {
            return "天气条件良好，正常护肤即可"
        }

        return tips.joined(separator: "；")
    }
}
