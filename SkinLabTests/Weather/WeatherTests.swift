// SkinLabTests/Weather/WeatherTests.swift
@testable import SkinLab
import XCTest

// MARK: - WeatherSnapshot Tests

final class WeatherSnapshotTests: XCTestCase {
    // MARK: - UV Level Computed Property Tests

    func testUVLevel_low_forIndex0() {
        let snapshot = makeSnapshot(uvIndex: 0)
        XCTAssertEqual(snapshot.uvLevel, .low)
    }

    func testUVLevel_low_forIndex2() {
        let snapshot = makeSnapshot(uvIndex: 2)
        XCTAssertEqual(snapshot.uvLevel, .low)
    }

    func testUVLevel_moderate_forIndex3() {
        let snapshot = makeSnapshot(uvIndex: 3)
        XCTAssertEqual(snapshot.uvLevel, .moderate)
    }

    func testUVLevel_moderate_forIndex5() {
        let snapshot = makeSnapshot(uvIndex: 5)
        XCTAssertEqual(snapshot.uvLevel, .moderate)
    }

    func testUVLevel_high_forIndex6() {
        let snapshot = makeSnapshot(uvIndex: 6)
        XCTAssertEqual(snapshot.uvLevel, .high)
    }

    func testUVLevel_high_forIndex7() {
        let snapshot = makeSnapshot(uvIndex: 7)
        XCTAssertEqual(snapshot.uvLevel, .high)
    }

    func testUVLevel_veryHigh_forIndex8() {
        let snapshot = makeSnapshot(uvIndex: 8)
        XCTAssertEqual(snapshot.uvLevel, .veryHigh)
    }

    func testUVLevel_veryHigh_forIndex10() {
        let snapshot = makeSnapshot(uvIndex: 10)
        XCTAssertEqual(snapshot.uvLevel, .veryHigh)
    }

    func testUVLevel_extreme_forIndex11() {
        let snapshot = makeSnapshot(uvIndex: 11)
        XCTAssertEqual(snapshot.uvLevel, .extreme)
    }

    func testUVLevel_extreme_forIndex15() {
        let snapshot = makeSnapshot(uvIndex: 15)
        XCTAssertEqual(snapshot.uvLevel, .extreme)
    }

    // MARK: - Skin Friendliness Score Tests

    func testSkinFriendlinessScore_perfectConditions() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 100)
    }

    func testSkinFriendlinessScore_moderateUV() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 4, // moderate UV
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 90) // -10 for moderate UV
    }

    func testSkinFriendlinessScore_highUV() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 7, // high UV
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 80) // -20 for high UV
    }

    func testSkinFriendlinessScore_veryHighUV() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 9, // very high UV
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 75) // -25 for very high UV
    }

    func testSkinFriendlinessScore_extremeUV() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 12, // extreme UV
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 70) // -30 for extreme UV
    }

    func testSkinFriendlinessScore_poorAirQuality() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 1,
            airQuality: .unhealthy,
            condition: .cloudy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 85) // -15 for unhealthy AQI
    }

    func testSkinFriendlinessScore_hazardousAirQuality() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 1,
            airQuality: .hazardous,
            condition: .cloudy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 75) // -25 for hazardous AQI
    }

    func testSkinFriendlinessScore_veryDryHumidity() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 20, // < 30, very dry
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 85) // -15 for very dry
    }

    func testSkinFriendlinessScore_dryHumidity() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 35, // 30-40, dry
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 90) // -10 for dry
    }

    func testSkinFriendlinessScore_veryHighHumidity() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 85, // > 80
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 90) // -10 for very humid
    }

    func testSkinFriendlinessScore_highHumidity() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 75, // 70-80
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 95) // -5 for humid
    }

    func testSkinFriendlinessScore_veryColdTemperature() {
        let snapshot = WeatherSnapshot(
            temperature: 0, // < 5
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .snowy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 75) // -15 for very cold, -10 for snowy
    }

    func testSkinFriendlinessScore_coldTemperature() {
        let snapshot = WeatherSnapshot(
            temperature: 8, // 5-10
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .cloudy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 90) // -10 for cold
    }

    func testSkinFriendlinessScore_veryHotTemperature() {
        let snapshot = WeatherSnapshot(
            temperature: 38, // > 35
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 85) // -15 for very hot
    }

    func testSkinFriendlinessScore_hotTemperature() {
        let snapshot = WeatherSnapshot(
            temperature: 32, // 30-35
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .sunny
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 90) // -10 for hot
    }

    func testSkinFriendlinessScore_windyCondition() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .windy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 90) // -10 for windy
    }

    func testSkinFriendlinessScore_foggyCondition() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .foggy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 85) // -15 for foggy
    }

    func testSkinFriendlinessScore_rainyCondition() {
        let snapshot = WeatherSnapshot(
            temperature: 22,
            humidity: 55,
            uvIndex: 1,
            airQuality: .good,
            condition: .rainy
        )
        XCTAssertEqual(snapshot.skinFriendlinessScore, 95) // -5 for rainy
    }

    func testSkinFriendlinessScore_worstCase() {
        let snapshot = WeatherSnapshot(
            temperature: 0, // -15 for very cold
            humidity: 20, // -15 for very dry
            uvIndex: 12, // -30 for extreme UV
            airQuality: .hazardous, // -25 for hazardous
            condition: .foggy // -15 for foggy
        )
        // 100 - 15 - 15 - 30 - 25 - 15 = 0
        XCTAssertEqual(snapshot.skinFriendlinessScore, 0)
    }

    func testSkinFriendlinessScore_neverNegative() {
        let snapshot = WeatherSnapshot(
            temperature: -10,
            humidity: 5,
            uvIndex: 20,
            airQuality: .hazardous,
            condition: .foggy
        )
        XCTAssertGreaterThanOrEqual(snapshot.skinFriendlinessScore, 0)
    }

    // MARK: - Display Properties Tests

    func testTemperatureDisplay() {
        let snapshot = makeSnapshot(temperature: 25.6)
        XCTAssertEqual(snapshot.temperatureDisplay, "26°C")
    }

    func testHumidityDisplay() {
        let snapshot = makeSnapshot(humidity: 55.4)
        XCTAssertEqual(snapshot.humidityDisplay, "55%")
    }

    func testHumidityLevel_veryDry() {
        let snapshot = makeSnapshot(humidity: 20)
        XCTAssertEqual(snapshot.humidityLevel, "干燥")
    }

    func testHumidityLevel_comfortable() {
        let snapshot = makeSnapshot(humidity: 40)
        XCTAssertEqual(snapshot.humidityLevel, "舒适")
    }

    func testHumidityLevel_moderate() {
        let snapshot = makeSnapshot(humidity: 60)
        XCTAssertEqual(snapshot.humidityLevel, "适中")
    }

    func testHumidityLevel_humid() {
        let snapshot = makeSnapshot(humidity: 80)
        XCTAssertEqual(snapshot.humidityLevel, "潮湿")
    }

    func testHumidityLevel_veryHumid() {
        let snapshot = makeSnapshot(humidity: 90)
        XCTAssertEqual(snapshot.humidityLevel, "非常潮湿")
    }

    func testTemperatureLevel_cold() {
        let snapshot = makeSnapshot(temperature: 5)
        XCTAssertEqual(snapshot.temperatureLevel, "寒冷")
    }

    func testTemperatureLevel_cool() {
        let snapshot = makeSnapshot(temperature: 15)
        XCTAssertEqual(snapshot.temperatureLevel, "凉爽")
    }

    func testTemperatureLevel_comfortable() {
        let snapshot = makeSnapshot(temperature: 22)
        XCTAssertEqual(snapshot.temperatureLevel, "舒适")
    }

    func testTemperatureLevel_warm() {
        let snapshot = makeSnapshot(temperature: 28)
        XCTAssertEqual(snapshot.temperatureLevel, "温暖")
    }

    func testTemperatureLevel_hot() {
        let snapshot = makeSnapshot(temperature: 35)
        XCTAssertEqual(snapshot.temperatureLevel, "炎热")
    }

    // MARK: - Helper

    private func makeSnapshot(
        temperature: Double = 22,
        humidity: Double = 55,
        uvIndex: Int = 5,
        airQuality: AQILevel = .good,
        condition: WeatherCondition = .sunny
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperature: temperature,
            humidity: humidity,
            uvIndex: uvIndex,
            airQuality: airQuality,
            condition: condition
        )
    }
}

// MARK: - AQILevel Tests

final class AQILevelTests: XCTestCase {
    func testAQILevel_rawValues() {
        XCTAssertEqual(AQILevel.good.rawValue, "优")
        XCTAssertEqual(AQILevel.moderate.rawValue, "良")
        XCTAssertEqual(AQILevel.unhealthySensitive.rawValue, "轻度污染")
        XCTAssertEqual(AQILevel.unhealthy.rawValue, "中度污染")
        XCTAssertEqual(AQILevel.veryUnhealthy.rawValue, "重度污染")
        XCTAssertEqual(AQILevel.hazardous.rawValue, "严重污染")
    }

    func testAQILevel_icons() {
        XCTAssertEqual(AQILevel.good.icon, "leaf.fill")
        XCTAssertEqual(AQILevel.moderate.icon, "leaf")
        XCTAssertEqual(AQILevel.unhealthySensitive.icon, "aqi.low")
        XCTAssertEqual(AQILevel.unhealthy.icon, "aqi.medium")
        XCTAssertEqual(AQILevel.veryUnhealthy.icon, "aqi.high")
        XCTAssertEqual(AQILevel.hazardous.icon, "exclamationmark.triangle.fill")
    }

    func testAQILevel_descriptions() {
        XCTAssertFalse(AQILevel.good.description.isEmpty)
        XCTAssertFalse(AQILevel.moderate.description.isEmpty)
        XCTAssertFalse(AQILevel.unhealthySensitive.description.isEmpty)
        XCTAssertFalse(AQILevel.unhealthy.description.isEmpty)
        XCTAssertFalse(AQILevel.veryUnhealthy.description.isEmpty)
        XCTAssertFalse(AQILevel.hazardous.description.isEmpty)
    }

    func testAQILevel_skincareTips() {
        XCTAssertFalse(AQILevel.good.skincareTip.isEmpty)
        XCTAssertFalse(AQILevel.moderate.skincareTip.isEmpty)
        XCTAssertFalse(AQILevel.unhealthySensitive.skincareTip.isEmpty)
        XCTAssertFalse(AQILevel.unhealthy.skincareTip.isEmpty)
        XCTAssertFalse(AQILevel.veryUnhealthy.skincareTip.isEmpty)
        XCTAssertFalse(AQILevel.hazardous.skincareTip.isEmpty)
    }

    func testAQILevel_aqiRanges() {
        XCTAssertEqual(AQILevel.good.aqiRange, "0-50")
        XCTAssertEqual(AQILevel.moderate.aqiRange, "51-100")
        XCTAssertEqual(AQILevel.unhealthySensitive.aqiRange, "101-150")
        XCTAssertEqual(AQILevel.unhealthy.aqiRange, "151-200")
        XCTAssertEqual(AQILevel.veryUnhealthy.aqiRange, "201-300")
        XCTAssertEqual(AQILevel.hazardous.aqiRange, ">300")
    }

    func testAQILevel_caseIterable() {
        XCTAssertEqual(AQILevel.allCases.count, 6)
    }
}

// MARK: - UVLevel Tests

final class UVLevelTests: XCTestCase {
    func testUVLevel_rawValues() {
        XCTAssertEqual(UVLevel.low.rawValue, "低")
        XCTAssertEqual(UVLevel.moderate.rawValue, "中等")
        XCTAssertEqual(UVLevel.high.rawValue, "高")
        XCTAssertEqual(UVLevel.veryHigh.rawValue, "很高")
        XCTAssertEqual(UVLevel.extreme.rawValue, "极高")
    }

    func testUVLevel_icons() {
        XCTAssertEqual(UVLevel.low.icon, "sun.min")
        XCTAssertEqual(UVLevel.moderate.icon, "sun.max")
        XCTAssertEqual(UVLevel.high.icon, "sun.max.fill")
        XCTAssertEqual(UVLevel.veryHigh.icon, "sun.max.trianglebadge.exclamationmark")
        XCTAssertEqual(UVLevel.extreme.icon, "exclamationmark.triangle.fill")
    }

    func testUVLevel_indexRanges() {
        XCTAssertEqual(UVLevel.low.indexRange, "0-2")
        XCTAssertEqual(UVLevel.moderate.indexRange, "3-5")
        XCTAssertEqual(UVLevel.high.indexRange, "6-7")
        XCTAssertEqual(UVLevel.veryHigh.indexRange, "8-10")
        XCTAssertEqual(UVLevel.extreme.indexRange, "11+")
    }

    func testUVLevel_descriptions() {
        XCTAssertFalse(UVLevel.low.description.isEmpty)
        XCTAssertFalse(UVLevel.moderate.description.isEmpty)
        XCTAssertFalse(UVLevel.high.description.isEmpty)
        XCTAssertFalse(UVLevel.veryHigh.description.isEmpty)
        XCTAssertFalse(UVLevel.extreme.description.isEmpty)
    }

    func testUVLevel_sunscreenAdvice() {
        XCTAssertTrue(UVLevel.low.sunscreenAdvice.contains("SPF15"))
        XCTAssertTrue(UVLevel.moderate.sunscreenAdvice.contains("SPF30"))
        XCTAssertTrue(UVLevel.high.sunscreenAdvice.contains("SPF30"))
        XCTAssertTrue(UVLevel.veryHigh.sunscreenAdvice.contains("SPF50"))
        XCTAssertTrue(UVLevel.extreme.sunscreenAdvice.contains("SPF50"))
    }

    func testUVLevel_skincareTips() {
        XCTAssertFalse(UVLevel.low.skincareTip.isEmpty)
        XCTAssertFalse(UVLevel.moderate.skincareTip.isEmpty)
        XCTAssertFalse(UVLevel.high.skincareTip.isEmpty)
        XCTAssertFalse(UVLevel.veryHigh.skincareTip.isEmpty)
        XCTAssertFalse(UVLevel.extreme.skincareTip.isEmpty)
    }

    func testUVLevel_caseIterable() {
        XCTAssertEqual(UVLevel.allCases.count, 5)
    }
}

// MARK: - WeatherCondition Tests

final class WeatherConditionTests: XCTestCase {
    func testWeatherCondition_rawValues() {
        XCTAssertEqual(WeatherCondition.sunny.rawValue, "sunny")
        XCTAssertEqual(WeatherCondition.cloudy.rawValue, "cloudy")
        XCTAssertEqual(WeatherCondition.rainy.rawValue, "rainy")
        XCTAssertEqual(WeatherCondition.windy.rawValue, "windy")
        XCTAssertEqual(WeatherCondition.snowy.rawValue, "snowy")
        XCTAssertEqual(WeatherCondition.foggy.rawValue, "foggy")
    }

    func testWeatherCondition_displayNames() {
        XCTAssertEqual(WeatherCondition.sunny.displayName, "晴天")
        XCTAssertEqual(WeatherCondition.cloudy.displayName, "多云")
        XCTAssertEqual(WeatherCondition.rainy.displayName, "雨天")
        XCTAssertEqual(WeatherCondition.windy.displayName, "大风")
        XCTAssertEqual(WeatherCondition.snowy.displayName, "下雪")
        XCTAssertEqual(WeatherCondition.foggy.displayName, "雾天")
    }

    func testWeatherCondition_icons() {
        XCTAssertEqual(WeatherCondition.sunny.icon, "sun.max.fill")
        XCTAssertEqual(WeatherCondition.cloudy.icon, "cloud.fill")
        XCTAssertEqual(WeatherCondition.rainy.icon, "cloud.rain.fill")
        XCTAssertEqual(WeatherCondition.windy.icon, "wind")
        XCTAssertEqual(WeatherCondition.snowy.icon, "cloud.snow.fill")
        XCTAssertEqual(WeatherCondition.foggy.icon, "cloud.fog.fill")
    }

    func testWeatherCondition_skincareTips() {
        // Sunny should mention UV
        XCTAssertTrue(WeatherCondition.sunny.skincareTip.contains("紫外线"))
        // Cloudy should still mention UV
        XCTAssertTrue(WeatherCondition.cloudy.skincareTip.contains("紫外线"))
        // Rainy should mention humidity or oil
        XCTAssertTrue(WeatherCondition.rainy.skincareTip.contains("湿度") || WeatherCondition.rainy.skincareTip
            .contains("控油"))
        // Windy should mention dryness or moisturizing
        XCTAssertTrue(WeatherCondition.windy.skincareTip.contains("干燥") || WeatherCondition.windy.skincareTip
            .contains("保湿"))
        // Snowy should mention UV
        XCTAssertTrue(WeatherCondition.snowy.skincareTip.contains("紫外线"))
        // Foggy should mention pollution or cleansing
        XCTAssertTrue(WeatherCondition.foggy.skincareTip.contains("污染") || WeatherCondition.foggy.skincareTip
            .contains("清洁"))
    }

    func testWeatherCondition_caseIterable() {
        XCTAssertEqual(WeatherCondition.allCases.count, 6)
    }
}

// MARK: - LifestyleFactorKey Weather Cases Tests

final class LifestyleFactorKeyWeatherTests: XCTestCase {
    func testLifestyleFactorKey_humidityLabel() {
        let factor = LifestyleCorrelationInsight.LifestyleFactorKey.humidity
        XCTAssertEqual(factor.label, "湿度")
    }

    func testLifestyleFactorKey_humidityIcon() {
        let factor = LifestyleCorrelationInsight.LifestyleFactorKey.humidity
        XCTAssertEqual(factor.icon, "humidity.fill")
    }

    func testLifestyleFactorKey_uvIndexLabel() {
        let factor = LifestyleCorrelationInsight.LifestyleFactorKey.uvIndex
        XCTAssertEqual(factor.label, "紫外线")
    }

    func testLifestyleFactorKey_uvIndexIcon() {
        let factor = LifestyleCorrelationInsight.LifestyleFactorKey.uvIndex
        XCTAssertEqual(factor.icon, "sun.max.trianglebadge.exclamationmark")
    }

    func testLifestyleFactorKey_airQualityLabel() {
        let factor = LifestyleCorrelationInsight.LifestyleFactorKey.airQuality
        XCTAssertEqual(factor.label, "空气质量")
    }

    func testLifestyleFactorKey_airQualityIcon() {
        let factor = LifestyleCorrelationInsight.LifestyleFactorKey.airQuality
        XCTAssertEqual(factor.icon, "aqi.medium")
    }

    func testLifestyleFactorKey_allWeatherCases() {
        // Verify weather-related cases exist
        let weatherCases: [LifestyleCorrelationInsight.LifestyleFactorKey] = [
            .humidity,
            .uvIndex,
            .airQuality
        ]

        for weatherCase in weatherCases {
            XCTAssertFalse(weatherCase.label.isEmpty)
            XCTAssertFalse(weatherCase.icon.isEmpty)
        }
    }
}
