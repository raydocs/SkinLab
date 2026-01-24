import Foundation
import CoreLocation

// MARK: - Location Errors
enum LocationError: LocalizedError, Equatable {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case timeout
    case unknown(String)

    static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.permissionRestricted, .permissionRestricted),
             (.locationUnavailable, .locationUnavailable),
             (.timeout, .timeout):
            return true
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置权限被拒绝，请在设置中开启"
        case .permissionRestricted:
            return "位置服务受限制"
        case .locationUnavailable:
            return "无法获取位置信息"
        case .timeout:
            return "获取位置超时"
        case .unknown(let message):
            return "位置错误: \(message)"
        }
    }
}

// MARK: - Location Manager
@MainActor
final class LocationManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isLoading = false

    // MARK: - Private Properties
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var permissionContinuation: CheckedContinuation<Bool, Never>?

    // MARK: - Computed Properties
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var canRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - Initialization
    override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // City-level for weather
        locationManager.distanceFilter = 5000 // 5km - no need for frequent updates
    }

    // MARK: - Public Methods

    /// Request location permission from user
    /// - Returns: true if permission was granted, false otherwise
    func requestPermission() async -> Bool {
        // If already determined, return current state
        guard authorizationStatus == .notDetermined else {
            return isAuthorized
        }

        return await withCheckedContinuation { continuation in
            self.permissionContinuation = continuation
            self.locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Request current location
    /// - Returns: The user's current location
    /// - Throws: LocationError if location cannot be obtained
    func requestLocation() async throws -> CLLocation {
        // Check authorization first
        if !isAuthorized {
            switch authorizationStatus {
            case .denied:
                throw LocationError.permissionDenied
            case .restricted:
                throw LocationError.permissionRestricted
            case .notDetermined:
                // Try to request permission first
                let granted = await requestPermission()
                if !granted {
                    throw LocationError.permissionDenied
                }
                // Permission granted, continue to location request
            default:
                throw LocationError.locationUnavailable
            }
        }

        // If we have a recent location (within 10 minutes), return it
        if let cachedLocation = location,
           Date().timeIntervalSince(cachedLocation.timestamp) < 600 {
            return cachedLocation
        }

        isLoading = true
        defer { isLoading = false }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.location = location
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            let locationError: LocationError

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .permissionDenied
                case .locationUnknown:
                    locationError = .locationUnavailable
                case .network:
                    locationError = .locationUnavailable
                default:
                    locationError = .unknown(clError.localizedDescription)
                }
            } else {
                locationError = .unknown(error.localizedDescription)
            }

            self.locationContinuation?.resume(throwing: locationError)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let newStatus = manager.authorizationStatus
            self.authorizationStatus = newStatus

            // Resume permission continuation if waiting
            if let continuation = self.permissionContinuation {
                let granted = newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways
                continuation.resume(returning: granted)
                self.permissionContinuation = nil
            }
        }
    }
}
