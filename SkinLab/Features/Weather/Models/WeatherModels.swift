//
//  WeatherModels.swift
//  SkinLab
//
//  天气数据模型
//  定义天气快照、空气质量、UV等级等类型
//

import Foundation
import SwiftUI

// MARK: - Weather Snapshot

/// 天气快照数据
/// 记录某一时刻的天气环境信息
struct WeatherSnapshot: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let temperature: Double          // 摄氏度
    let humidity: Double             // 百分比 0-100
    let uvIndex: Int                 // 0-11+
    let airQuality: AQILevel
    let condition: WeatherCondition
    let recordedAt: Date
    let location: String?            // 城市名

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
        case 0...2: return .low
        case 3...5: return .moderate
        case 6...7: return .high
        case 8...10: return .veryHigh
        default: return .extreme
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
        case 0..<30: return "干燥"
        case 30..<50: return "舒适"
        case 50..<70: return "适中"
        case 70..<85: return "潮湿"
        default: return "非常潮湿"
        }
    }

    /// 温度舒适度描述
    var temperatureLevel: String {
        switch temperature {
        case ..<10: return "寒冷"
        case 10..<18: return "凉爽"
        case 18..<26: return "舒适"
        case 26..<32: return "温暖"
        default: return "炎热"
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

    var id: String { rawValue }

    // MARK: - Display Properties

    /// 图标名称 (SF Symbols)
    var icon: String {
        switch self {
        case .good: return "leaf.fill"
        case .moderate: return "leaf"
        case .unhealthySensitive: return "aqi.low"
        case .unhealthy: return "aqi.medium"
        case .veryUnhealthy: return "aqi.high"
        case .hazardous: return "exclamationmark.triangle.fill"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .good: return .green
        case .moderate: return .yellow
        case .unhealthySensitive: return .orange
        case .unhealthy: return .red
        case .veryUnhealthy: return .purple
        case .hazardous: return .brown
        }
    }

    /// 详细描述
    var description: String {
        switch self {
        case .good:
            return "空气质量令人满意，基本无空气污染"
        case .moderate:
            return "空气质量可接受，少数敏感人群可能有不适"
        case .unhealthySensitive:
            return "敏感人群可能出现健康影响"
        case .unhealthy:
            return "可能对人体健康产生影响"
        case .veryUnhealthy:
            return "健康风险增加，应减少户外活动"
        case .hazardous:
            return "健康警告，避免户外活动"
        }
    }

    /// 护肤建议
    var skincareTip: String {
        switch self {
        case .good:
            return "空气清新，正常护肤即可"
        case .moderate:
            return "可正常护肤，注意基础清洁"
        case .unhealthySensitive:
            return "加强清洁，使用抗氧化产品"
        case .unhealthy:
            return "深层清洁，加强屏障修复"
        case .veryUnhealthy:
            return "减少外出，回家后彻底清洁"
        case .hazardous:
            return "避免外出，使用物理防护"
        }
    }

    /// AQI数值范围参考
    var aqiRange: String {
        switch self {
        case .good: return "0-50"
        case .moderate: return "51-100"
        case .unhealthySensitive: return "101-150"
        case .unhealthy: return "151-200"
        case .veryUnhealthy: return "201-300"
        case .hazardous: return ">300"
        }
    }
}

// MARK: - Weather Condition

/// 天气状况
enum WeatherCondition: String, Codable, Sendable, CaseIterable, Identifiable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case windy = "windy"
    case snowy = "snowy"
    case foggy = "foggy"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// 中文显示名称
    var displayName: String {
        switch self {
        case .sunny: return "晴天"
        case .cloudy: return "多云"
        case .rainy: return "雨天"
        case .windy: return "大风"
        case .snowy: return "下雪"
        case .foggy: return "雾天"
        }
    }

    /// 图标名称 (SF Symbols)
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .windy: return "wind"
        case .snowy: return "cloud.snow.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .sunny: return .orange
        case .cloudy: return .gray
        case .rainy: return .blue
        case .windy: return .teal
        case .snowy: return .cyan
        case .foggy: return .secondary
        }
    }

    /// 护肤建议
    var skincareTip: String {
        switch self {
        case .sunny:
            return "紫外线较强，注意防晒保护"
        case .cloudy:
            return "仍需防晒，紫外线可穿透云层"
        case .rainy:
            return "湿度较高，注意控油和清洁"
        case .windy:
            return "皮肤易干燥，加强保湿"
        case .snowy:
            return "雪地反射紫外线，注意防晒"
        case .foggy:
            return "空气污染物易滞留，加强清洁"
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

    var id: String { rawValue }

    // MARK: - Display Properties

    /// 图标名称 (SF Symbols)
    var icon: String {
        switch self {
        case .low: return "sun.min"
        case .moderate: return "sun.max"
        case .high: return "sun.max.fill"
        case .veryHigh: return "sun.max.trianglebadge.exclamationmark"
        case .extreme: return "exclamationmark.triangle.fill"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        case .extreme: return .purple
        }
    }

    /// UV指数范围
    var indexRange: String {
        switch self {
        case .low: return "0-2"
        case .moderate: return "3-5"
        case .high: return "6-7"
        case .veryHigh: return "8-10"
        case .extreme: return "11+"
        }
    }

    /// 详细描述
    var description: String {
        switch self {
        case .low:
            return "紫外线较弱，可正常外出"
        case .moderate:
            return "紫外线适中，建议使用防晒"
        case .high:
            return "紫外线较强，需做好防晒"
        case .veryHigh:
            return "紫外线很强，避免长时间暴晒"
        case .extreme:
            return "紫外线极强，尽量避免外出"
        }
    }

    /// 防晒建议
    var sunscreenAdvice: String {
        switch self {
        case .low:
            return "日常防晒即可，SPF15+"
        case .moderate:
            return "建议SPF30+，每3小时补涂"
        case .high:
            return "必须SPF30+，每2小时补涂"
        case .veryHigh:
            return "SPF50+，配合物理防晒"
        case .extreme:
            return "SPF50+ PA++++，全面物理遮挡"
        }
    }

    /// 护肤建议
    var skincareTip: String {
        switch self {
        case .low:
            return "正常护肤即可"
        case .moderate:
            return "注意防晒，可使用抗氧化精华"
        case .high:
            return "加强防晒和抗氧化，晒后修复"
        case .veryHigh:
            return "高倍防晒，晚间使用修复产品"
        case .extreme:
            return "避免外出，使用高强度修复产品"
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
            score -= 15  // 太干燥
        } else if humidity < 40 {
            score -= 10
        } else if humidity > 80 {
            score -= 10  // 太潮湿
        } else if humidity > 70 {
            score -= 5
        }

        // 温度影响 (-15 max)
        if temperature < 5 {
            score -= 15  // 太冷
        } else if temperature < 10 {
            score -= 10
        } else if temperature > 35 {
            score -= 15  // 太热
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
        if airQuality != .good && airQuality != .moderate {
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
