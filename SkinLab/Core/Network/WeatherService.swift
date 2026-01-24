//
//  WeatherService.swift
//  SkinLab
//
//  Weather data service using WeatherKit
//  Provides current weather and forecast with 1-hour caching
//

import Foundation
import CoreLocation

#if canImport(WeatherKit)
import WeatherKit
#endif

// MARK: - Weather Service Protocol

/// Protocol for weather data service (for dependency injection)
protocol WeatherServiceProtocol: Sendable {
    func getCurrentWeather() async throws -> WeatherSnapshot
    func getWeatherForecast(days: Int) async throws -> [WeatherSnapshot]
}

// MARK: - Weather Errors

enum WeatherError: LocalizedError, Equatable {
    case locationUnavailable
    case weatherUnavailable
    case notAuthorized
    case networkError(String)

    static func == (lhs: WeatherError, rhs: WeatherError) -> Bool {
        switch (lhs, rhs) {
        case (.locationUnavailable, .locationUnavailable),
             (.weatherUnavailable, .weatherUnavailable),
             (.notAuthorized, .notAuthorized):
            return true
        case (.networkError(let lhsMsg), .networkError(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "无法获取位置信息"
        case .weatherUnavailable:
            return "无法获取天气数据"
        case .notAuthorized:
            return "天气服务未授权"
        case .networkError(let message):
            return "网络错误: \(message)"
        }
    }
}

// MARK: - Weather Service

/// Actor-based weather service with caching
/// Uses WeatherKit when available, falls back to mock data for development
actor WeatherService: WeatherServiceProtocol {

    // MARK: - Singleton

    static let shared = WeatherService()

    // MARK: - Cache Configuration

    private struct CachedWeather {
        let data: WeatherSnapshot
        let expiry: Date

        var isValid: Bool {
            Date() < expiry
        }
    }

    private var cache: CachedWeather?
    private var forecastCache: (data: [WeatherSnapshot], expiry: Date)?
    private let cacheInterval: TimeInterval = 3600  // 1 hour

    // MARK: - Dependencies

    #if canImport(WeatherKit)
    @available(iOS 16.0, *)
    private var weatherKitService: WeatherKit.WeatherService {
        WeatherKit.WeatherService.shared
    }
    #endif

    // MARK: - Initialization

    init() {
        // Default initialization
    }

    // MARK: - Public Methods

    /// Get current weather for user's location
    /// Returns cached data if available and valid, or fetches new data
    /// Falls back to cached data on network failure
    func getCurrentWeather() async throws -> WeatherSnapshot {
        // Return valid cached data
        if let cached = cache, cached.isValid {
            return cached.data
        }

        do {
            // Get location
            let location = try await getLocation()

            // Fetch weather
            let weather = try await fetchCurrentWeather(for: location)

            // Cache the result
            cache = CachedWeather(
                data: weather,
                expiry: Date().addingTimeInterval(cacheInterval)
            )

            return weather

        } catch {
            // On failure, return stale cache if available
            if let cached = cache {
                return cached.data
            }
            throw error
        }
    }

    /// Get weather forecast for specified number of days
    func getWeatherForecast(days: Int) async throws -> [WeatherSnapshot] {
        // Clamp days to reasonable range
        let requestedDays = max(1, min(days, 7))

        // Return valid cached data
        if let cached = forecastCache, Date() < cached.expiry {
            return Array(cached.data.prefix(requestedDays))
        }

        do {
            // Get location
            let location = try await getLocation()

            // Fetch forecast
            let forecast = try await fetchForecast(for: location, days: requestedDays)

            // Cache the result
            forecastCache = (
                data: forecast,
                expiry: Date().addingTimeInterval(cacheInterval)
            )

            return forecast

        } catch {
            // On failure, return stale cache if available
            if let cached = forecastCache {
                return Array(cached.data.prefix(requestedDays))
            }
            throw error
        }
    }

    /// Invalidate cache (e.g., when location changes significantly)
    func invalidateCache() {
        cache = nil
        forecastCache = nil
    }

    // MARK: - Private Methods

    private func getLocation() async throws -> CLLocation {
        do {
            return try await requestLocationOnMainActor()
        } catch {
            throw WeatherError.locationUnavailable
        }
    }

    @MainActor
    private func requestLocationOnMainActor() async throws -> CLLocation {
        let manager = LocationManager()
        return try await manager.requestLocation()
    }

    private func fetchCurrentWeather(for location: CLLocation) async throws -> WeatherSnapshot {
        #if canImport(WeatherKit) && !targetEnvironment(simulator)
        if #available(iOS 16.0, *) {
            return try await fetchWeatherKitData(for: location)
        }
        #endif

        // Fallback to mock data for development/simulator
        return generateMockWeather(for: location)
    }

    private func fetchForecast(for location: CLLocation, days: Int) async throws -> [WeatherSnapshot] {
        #if canImport(WeatherKit) && !targetEnvironment(simulator)
        if #available(iOS 16.0, *) {
            return try await fetchWeatherKitForecast(for: location, days: days)
        }
        #endif

        // Fallback to mock data for development/simulator
        return generateMockForecast(for: location, days: days)
    }

    // MARK: - WeatherKit Integration

    #if canImport(WeatherKit)
    @available(iOS 16.0, *)
    private func fetchWeatherKitData(for location: CLLocation) async throws -> WeatherSnapshot {
        do {
            let weather = try await weatherKitService.weather(for: location)
            let current = weather.currentWeather

            return WeatherSnapshot(
                temperature: current.temperature.value,
                humidity: current.humidity * 100,
                uvIndex: current.uvIndex.value,
                airQuality: .good,  // WeatherKit doesn't provide AQI directly
                condition: mapWeatherKitCondition(current.condition),
                recordedAt: current.date,
                location: await getLocationName(for: location)
            )
        } catch {
            throw WeatherError.weatherUnavailable
        }
    }

    @available(iOS 16.0, *)
    private func fetchWeatherKitForecast(for location: CLLocation, days: Int) async throws -> [WeatherSnapshot] {
        do {
            let weather = try await weatherKitService.weather(for: location)
            let dailyForecast = weather.dailyForecast

            let locationName = await getLocationName(for: location)

            return dailyForecast.prefix(days).map { day in
                WeatherSnapshot(
                    temperature: day.highTemperature.value,
                    humidity: 50,  // Daily forecast doesn't include hourly humidity
                    uvIndex: day.uvIndex.value,
                    airQuality: .good,
                    condition: mapWeatherKitCondition(day.condition),
                    recordedAt: day.date,
                    location: locationName
                )
            }
        } catch {
            throw WeatherError.weatherUnavailable
        }
    }

    @available(iOS 16.0, *)
    private func mapWeatherKitCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .mostlyClear, .hot, .frigid:
            return .sunny
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return .cloudy
        case .rain, .heavyRain, .drizzle, .thunderstorms, .tropicalStorm, .hurricane,
             .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .sunShowers, .hail:
            return .rainy
        case .windy, .breezy, .blowingDust:
            return .windy
        case .snow, .heavySnow, .flurries, .sleet, .freezingRain, .freezingDrizzle,
             .blizzard, .blowingSnow, .wintryMix, .sunFlurries:
            return .snowy
        case .foggy, .haze, .smoky:
            return .foggy
        @unknown default:
            return .cloudy
        }
    }
    #endif

    // MARK: - Location Name

    private func getLocationName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality ?? placemarks.first?.administrativeArea
        } catch {
            return nil
        }
    }

    // MARK: - Mock Data (Development Fallback)

    private func generateMockWeather(for location: CLLocation) -> WeatherSnapshot {
        // Generate realistic mock data based on current date/time
        let hour = Calendar.current.component(.hour, from: Date())
        let month = Calendar.current.component(.month, from: Date())

        // Temperature based on season and time
        let baseTemp: Double
        switch month {
        case 12, 1, 2:  // Winter
            baseTemp = 5
        case 3, 4, 5:   // Spring
            baseTemp = 18
        case 6, 7, 8:   // Summer
            baseTemp = 28
        default:        // Fall
            baseTemp = 15
        }

        // Adjust for time of day
        let timeAdjustment = hour >= 10 && hour <= 16 ? 5.0 : -3.0
        let temperature = baseTemp + timeAdjustment + Double.random(in: -3...3)

        // UV based on time
        let uvIndex: Int
        if hour >= 10 && hour <= 16 {
            uvIndex = Int.random(in: 4...8)
        } else if hour >= 7 && hour <= 19 {
            uvIndex = Int.random(in: 1...4)
        } else {
            uvIndex = 0
        }

        // Random humidity
        let humidity = Double.random(in: 40...70)

        // Random condition weighted towards sunny
        let conditions: [WeatherCondition] = [
            .sunny, .sunny, .sunny,
            .cloudy, .cloudy,
            .rainy
        ]
        let condition = conditions.randomElement() ?? .sunny

        return WeatherSnapshot(
            temperature: temperature,
            humidity: humidity,
            uvIndex: uvIndex,
            airQuality: .good,
            condition: condition,
            recordedAt: Date(),
            location: "模拟位置"
        )
    }

    private func generateMockForecast(for location: CLLocation, days: Int) -> [WeatherSnapshot] {
        var forecasts: [WeatherSnapshot] = []
        let today = Date()

        for dayOffset in 0..<days {
            let forecastDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let month = Calendar.current.component(.month, from: forecastDate)

            // Base temperature by season
            let baseTemp: Double
            switch month {
            case 12, 1, 2:
                baseTemp = 5
            case 3, 4, 5:
                baseTemp = 18
            case 6, 7, 8:
                baseTemp = 28
            default:
                baseTemp = 15
            }

            let temperature = baseTemp + Double.random(in: -5...5)
            let uvIndex = Int.random(in: 3...7)
            let humidity = Double.random(in: 35...75)

            let conditions: [WeatherCondition] = [.sunny, .sunny, .cloudy, .cloudy, .rainy]
            let condition = conditions.randomElement() ?? .sunny

            forecasts.append(WeatherSnapshot(
                temperature: temperature,
                humidity: humidity,
                uvIndex: uvIndex,
                airQuality: .good,
                condition: condition,
                recordedAt: forecastDate,
                location: "模拟位置"
            ))
        }

        return forecasts
    }
}
