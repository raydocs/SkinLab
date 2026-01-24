//
//  RetryPolicy.swift
//  SkinLab
//
//  Intelligent network retry strategy with exponential backoff.
//  Provides consistent retry behavior across all network services.
//

import Foundation

// MARK: - Retry Policy

/// Configuration for network request retry behavior.
/// Uses exponential backoff with jitter to prevent thundering herd.
struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts (not including initial request)
    let maxAttempts: Int

    /// Base delay before first retry (in seconds)
    let baseDelay: TimeInterval

    /// Maximum delay cap (in seconds)
    let maxDelay: TimeInterval

    /// Jitter factor (0.0-1.0) to add randomness to delays
    let jitterFactor: Double

    /// Default retry policy for most network requests
    static let `default` = RetryPolicy(
        maxAttempts: AppConfiguration.API.maxRetryAttempts,
        baseDelay: 1.0,
        maxDelay: 30.0,
        jitterFactor: 0.2
    )

    /// Aggressive retry policy for critical operations
    static let aggressive = RetryPolicy(
        maxAttempts: 5,
        baseDelay: 0.5,
        maxDelay: 60.0,
        jitterFactor: 0.25
    )

    /// Conservative retry policy for non-critical operations
    static let conservative = RetryPolicy(
        maxAttempts: 2,
        baseDelay: 2.0,
        maxDelay: 10.0,
        jitterFactor: 0.1
    )

    /// No retry policy
    static let none = RetryPolicy(
        maxAttempts: 0,
        baseDelay: 0,
        maxDelay: 0,
        jitterFactor: 0
    )

    /// Calculate delay for a given attempt (0-indexed)
    /// Uses exponential backoff: baseDelay * 2^attempt, capped at maxDelay
    /// Adds jitter to prevent synchronized retries
    func delay(for attempt: Int) -> TimeInterval {
        guard attempt >= 0 else { return 0 }

        // Exponential backoff: baseDelay * 2^attempt
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))

        // Cap at maxDelay
        let cappedDelay = min(exponentialDelay, maxDelay)

        // Add jitter: random value between -jitter% and +jitter%
        let jitterRange = cappedDelay * jitterFactor
        let jitter = Double.random(in: -jitterRange...jitterRange)

        // Ensure delay is never negative
        return max(0, cappedDelay + jitter)
    }

    /// Check if another retry attempt is allowed
    func shouldRetry(attempt: Int) -> Bool {
        return attempt < maxAttempts
    }
}

// MARK: - Retryable Error Detection

extension Error {
    /// Determines if this error is retryable.
    /// Retryable errors are typically transient network or server issues.
    var isRetryable: Bool {
        // Check URLError types (most common network errors)
        if let urlError = self as? URLError {
            return urlError.isRetryable
        }

        // Check for HTTP errors with retryable status codes
        if let httpError = self as? HTTPError {
            return httpError.isRetryable
        }

        // Check for GeminiError types
        if let geminiError = self as? GeminiError {
            return geminiError.isRetryable
        }

        // Check for WeatherError types
        if let weatherError = self as? WeatherError {
            return weatherError.isRetryable
        }

        // Default: don't retry unknown errors
        return false
    }
}

extension URLError {
    /// Determines if this URLError is retryable
    var isRetryable: Bool {
        switch code {
        // Network connectivity issues - retryable
        case .timedOut,
             .networkConnectionLost,
             .notConnectedToInternet,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .internationalRoamingOff,
             .callIsActive,
             .dataNotAllowed:
            return true

        // Server-side issues - retryable
        case .badServerResponse,
             .zeroByteResource,
             .cannotParseResponse:
            return true

        // SSL/TLS issues - might be temporary
        case .secureConnectionFailed,
             .serverCertificateHasBadDate,
             .serverCertificateNotYetValid:
            return true

        // Client errors or permanent failures - not retryable
        case .cancelled,
             .badURL,
             .unsupportedURL,
             .resourceUnavailable,
             .fileDoesNotExist,
             .noPermissionsToReadFile,
             .userCancelledAuthentication,
             .userAuthenticationRequired,
             .appTransportSecurityRequiresSecureConnection:
            return false

        // Unknown errors - don't retry by default
        default:
            return false
        }
    }
}

// MARK: - HTTP Error

/// Represents an HTTP error with status code
struct HTTPError: Error, Sendable {
    let statusCode: Int
    let data: Data?
    let response: HTTPURLResponse?

    init(statusCode: Int, data: Data? = nil, response: HTTPURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.response = response
    }

    /// Determines if this HTTP error is retryable
    var isRetryable: Bool {
        switch statusCode {
        // 5xx Server errors - usually retryable
        case 500...599:
            return true

        // 429 Too Many Requests - retryable with backoff
        case 429:
            return true

        // 408 Request Timeout - retryable
        case 408:
            return true

        // 4xx Client errors (except 408, 429) - not retryable
        case 400...499:
            return false

        // 3xx Redirects - not retryable (should follow redirect)
        case 300...399:
            return false

        // 2xx Success - not an error, shouldn't retry
        case 200...299:
            return false

        // Unknown status - don't retry
        default:
            return false
        }
    }

    /// Get Retry-After header value if present
    var retryAfter: TimeInterval? {
        guard let retryAfterString = response?.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }

        // Try parsing as seconds
        if let seconds = TimeInterval(retryAfterString) {
            return seconds
        }

        // Try parsing as HTTP date
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: retryAfterString) {
            let delay = date.timeIntervalSinceNow
            return delay > 0 ? delay : nil
        }

        return nil
    }
}

// MARK: - GeminiError Retryable Extension

extension GeminiError {
    /// Determines if this GeminiError is retryable
    var isRetryable: Bool {
        switch self {
        case .networkError:
            return true
        case .rateLimited:
            return true
        case .apiError:
            // API errors might be server-side, allow retry
            return true
        case .invalidImage,
             .invalidAPIKey,
             .parseError,
             .unauthorized:
            // Client-side errors - not retryable
            return false
        }
    }
}

// MARK: - WeatherError Retryable Extension

extension WeatherError {
    /// Determines if this WeatherError is retryable
    var isRetryable: Bool {
        switch self {
        case .networkError:
            return true
        case .weatherUnavailable:
            // Service might be temporarily unavailable
            return true
        case .locationUnavailable,
             .notAuthorized:
            // Permission/location issues won't fix with retry
            return false
        }
    }
}

// MARK: - Global Retry Limiter

/// Actor to prevent retry storms across multiple concurrent requests.
/// Limits total concurrent retries to prevent overwhelming the server.
actor GlobalRetryLimiter {
    static let shared = GlobalRetryLimiter()

    private var activeRetries: Int = 0
    private let maxConcurrentRetries = 10

    /// Check if a retry is allowed based on global limits
    func canRetry() -> Bool {
        return activeRetries < maxConcurrentRetries
    }

    /// Begin a retry attempt
    func beginRetry() -> Bool {
        guard activeRetries < maxConcurrentRetries else {
            return false
        }
        activeRetries += 1
        return true
    }

    /// End a retry attempt
    func endRetry() {
        activeRetries = max(0, activeRetries - 1)
    }

    /// Get current retry count (for monitoring)
    func currentRetryCount() -> Int {
        return activeRetries
    }
}

// MARK: - Retry Helper

/// Helper function to execute an async operation with retry support.
/// Uses the specified retry policy and respects global retry limits.
func withRetry<T>(
    policy: RetryPolicy = .default,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 0...policy.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Check if error is retryable
            guard error.isRetryable else {
                throw error
            }

            // Check if we have attempts left
            guard policy.shouldRetry(attempt: attempt) else {
                throw error
            }

            // Check global retry limit
            guard await GlobalRetryLimiter.shared.canRetry() else {
                throw error
            }

            // Register retry with global limiter
            let allowed = await GlobalRetryLimiter.shared.beginRetry()
            guard allowed else {
                throw error
            }

            defer {
                Task {
                    await GlobalRetryLimiter.shared.endRetry()
                }
            }

            // Calculate delay (check for Retry-After header if HTTPError)
            var delay = policy.delay(for: attempt)
            if let httpError = error as? HTTPError,
               let retryAfter = httpError.retryAfter {
                delay = max(delay, retryAfter)
            }

            // Wait before retry
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    throw lastError ?? URLError(.unknown)
}
