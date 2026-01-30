@testable import SkinLab
import XCTest

final class RetryPolicyTests: XCTestCase {
    // MARK: - RetryPolicy Tests

    func testDefaultPolicyValues() {
        let policy = RetryPolicy.default

        XCTAssertEqual(policy.maxAttempts, AppConfiguration.API.maxRetryAttempts)
        XCTAssertEqual(policy.baseDelay, AppConfiguration.API.retryBaseDelay)
        XCTAssertEqual(policy.maxDelay, AppConfiguration.API.retryMaxDelay)
        XCTAssertEqual(policy.jitterFactor, 0.2)
    }

    func testInitClampsNegativeValues() {
        let policy = RetryPolicy(
            maxAttempts: -5,
            baseDelay: -1.0,
            maxDelay: -10.0,
            jitterFactor: -0.5
        )

        XCTAssertEqual(policy.maxAttempts, 0, "Negative maxAttempts should be clamped to 0")
        XCTAssertEqual(policy.baseDelay, 0, "Negative baseDelay should be clamped to 0")
        XCTAssertEqual(policy.maxDelay, 0, "Negative maxDelay should be clamped to 0")
        XCTAssertEqual(policy.jitterFactor, 0, "Negative jitterFactor should be clamped to 0")
    }

    func testInitClampsJitterFactorAboveOne() {
        let policy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            jitterFactor: 2.5
        )

        XCTAssertEqual(policy.jitterFactor, 1.0, "jitterFactor > 1 should be clamped to 1.0")
    }

    func testInitClampsExcessiveMaxAttempts() {
        let policy = RetryPolicy(
            maxAttempts: Int.max,
            baseDelay: 1.0,
            maxDelay: 10.0,
            jitterFactor: 0.2
        )

        XCTAssertLessThanOrEqual(policy.maxAttempts, 10, "Excessive maxAttempts should be capped")
    }

    func testInitHandlesNaNAndInfinity() {
        let policy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: .infinity,
            maxDelay: .nan,
            jitterFactor: .nan
        )

        XCTAssertEqual(policy.baseDelay, 0, "Infinity baseDelay should become 0")
        XCTAssertEqual(policy.maxDelay, 0, "NaN maxDelay should become 0")
        XCTAssertEqual(policy.jitterFactor, 0, "NaN jitterFactor should become 0")
    }

    func testExponentialBackoffDelay() {
        let policy = RetryPolicy(
            maxAttempts: 5,
            baseDelay: 1.0,
            maxDelay: 100.0,
            jitterFactor: 0.0 // No jitter for predictable testing
        )

        // Attempt 0: 1 * 2^0 = 1
        XCTAssertEqual(policy.delay(for: 0), 1.0)

        // Attempt 1: 1 * 2^1 = 2
        XCTAssertEqual(policy.delay(for: 1), 2.0)

        // Attempt 2: 1 * 2^2 = 4
        XCTAssertEqual(policy.delay(for: 2), 4.0)

        // Attempt 3: 1 * 2^3 = 8
        XCTAssertEqual(policy.delay(for: 3), 8.0)
    }

    func testDelayCapAtMaxDelay() {
        let policy = RetryPolicy(
            maxAttempts: 10,
            baseDelay: 1.0,
            maxDelay: 5.0,
            jitterFactor: 0.0
        )

        // Attempt 5: 1 * 2^5 = 32, but capped at 5
        XCTAssertEqual(policy.delay(for: 5), 5.0)

        // Attempt 10: should still be capped at 5
        XCTAssertEqual(policy.delay(for: 10), 5.0)
    }

    func testDelayWithJitter() {
        let policy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: 10.0,
            maxDelay: 100.0,
            jitterFactor: 0.5 // 50% jitter
        )

        // Run multiple times to verify jitter adds randomness
        var delays: Set<Double> = []
        for _ in 0 ..< 20 {
            let delay = policy.delay(for: 0)
            delays.insert(delay)

            // With 50% jitter on base 10, delay should be 5-15
            XCTAssertGreaterThanOrEqual(delay, 5.0)
            XCTAssertLessThanOrEqual(delay, 15.0)
        }

        // Should have multiple different values due to randomness
        XCTAssertGreaterThan(delays.count, 1, "Jitter should produce varied delays")
    }

    func testDelayNeverNegative() {
        let policy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            jitterFactor: 1.0 // 100% jitter could theoretically go negative
        )

        for attempt in 0 ..< 10 {
            for _ in 0 ..< 50 {
                let delay = policy.delay(for: attempt)
                XCTAssertGreaterThanOrEqual(delay, 0, "Delay should never be negative")
            }
        }
    }

    func testNegativeAttemptReturnsZero() {
        let policy = RetryPolicy.default
        XCTAssertEqual(policy.delay(for: -1), 0)
        XCTAssertEqual(policy.delay(for: -100), 0)
    }

    func testShouldRetry() {
        let policy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            jitterFactor: 0.0
        )

        XCTAssertTrue(policy.shouldRetry(attempt: 0))
        XCTAssertTrue(policy.shouldRetry(attempt: 1))
        XCTAssertTrue(policy.shouldRetry(attempt: 2))
        XCTAssertFalse(policy.shouldRetry(attempt: 3))
        XCTAssertFalse(policy.shouldRetry(attempt: 10))
    }

    func testNonePolicyDisablesRetry() {
        let policy = RetryPolicy.none

        XCTAssertEqual(policy.maxAttempts, 0)
        XCTAssertFalse(policy.shouldRetry(attempt: 0))
    }

    // MARK: - URLError Retryable Tests

    func testRetryableURLErrors() {
        let retryableErrors: [URLError.Code] = [
            .timedOut,
            .networkConnectionLost,
            .notConnectedToInternet,
            .cannotFindHost,
            .cannotConnectToHost,
            .dnsLookupFailed,
            .badServerResponse
        ]

        for code in retryableErrors {
            let error = URLError(code)
            XCTAssertTrue(error.isRetryable, "URLError.\(code) should be retryable")
        }
    }

    func testNonRetryableURLErrors() {
        let nonRetryableErrors: [URLError.Code] = [
            .cancelled,
            .badURL,
            .unsupportedURL,
            .userCancelledAuthentication,
            // SSL/TLS errors are not retryable (usually permanent)
            .secureConnectionFailed,
            .serverCertificateHasBadDate,
            .serverCertificateNotYetValid
        ]

        for code in nonRetryableErrors {
            let error = URLError(code)
            XCTAssertFalse(error.isRetryable, "URLError.\(code) should not be retryable")
        }
    }

    // MARK: - HTTPError Tests

    func testRetryableHTTPStatusCodes() {
        let retryableCodes = [429, 500, 502, 503, 504, 408]

        for code in retryableCodes {
            let error = HTTPError(statusCode: code)
            XCTAssertTrue(error.isRetryable, "HTTP \(code) should be retryable")
        }
    }

    func testNonRetryableHTTPStatusCodes() {
        let nonRetryableCodes = [400, 401, 403, 404, 405, 422]

        for code in nonRetryableCodes {
            let error = HTTPError(statusCode: code)
            XCTAssertFalse(error.isRetryable, "HTTP \(code) should not be retryable")
        }
    }

    func testHTTPErrorRetryAfterHeader() throws {
        // Create response with Retry-After header
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let response = HTTPURLResponse(
            url: url,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: ["Retry-After": "30"]
        )

        let error = HTTPError(statusCode: 429, response: response)

        XCTAssertEqual(error.retryAfter, 30.0)
    }

    func testHTTPErrorWithoutRetryAfterHeader() {
        let error = HTTPError(statusCode: 429)
        XCTAssertNil(error.retryAfter)
    }

    func testHTTPErrorRetryAfterDateHeader() throws {
        // Create a date 60 seconds in the future
        let futureDate = Date().addingTimeInterval(60)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        let dateString = formatter.string(from: futureDate)

        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let response = HTTPURLResponse(
            url: url,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: ["Retry-After": dateString]
        )

        let error = HTTPError(statusCode: 429, response: response)

        // Should parse to approximately 60 seconds (allow some tolerance)
        if let retryAfter = error.retryAfter {
            XCTAssertGreaterThan(retryAfter, 55, "Retry-After date should parse to ~60 seconds")
            XCTAssertLessThan(retryAfter, 65, "Retry-After date should parse to ~60 seconds")
        } else {
            XCTFail("Retry-After date header should be parsed")
        }
    }

    // MARK: - GeminiError Retryable Tests

    func testRetryableGeminiErrors() {
        // networkError delegates to underlying error
        XCTAssertTrue(GeminiError.networkError(URLError(.timedOut)).isRetryable)
        XCTAssertTrue(GeminiError.rateLimited.isRetryable)
    }

    func testNonRetryableGeminiErrors() {
        XCTAssertFalse(GeminiError.invalidImage.isRetryable)
        XCTAssertFalse(GeminiError.invalidAPIKey.isRetryable)
        XCTAssertFalse(GeminiError.parseError.isRetryable)
        XCTAssertFalse(GeminiError.unauthorized.isRetryable)
        // apiError is not retryable as it may contain 4xx client errors
        XCTAssertFalse(GeminiError.apiError("Server error").isRetryable)
        // networkError with non-retryable underlying error
        XCTAssertFalse(GeminiError.networkError(URLError(.badURL)).isRetryable)
    }

    // MARK: - WeatherError Retryable Tests

    func testRetryableWeatherErrors() {
        XCTAssertTrue(WeatherError.networkError("timeout").isRetryable)
        XCTAssertTrue(WeatherError.weatherUnavailable.isRetryable)
    }

    func testNonRetryableWeatherErrors() {
        XCTAssertFalse(WeatherError.locationUnavailable.isRetryable)
        XCTAssertFalse(WeatherError.notAuthorized.isRetryable)
    }

    // MARK: - Error Extension Tests

    func testGenericErrorIsRetryable() {
        // URLError should be checked
        let urlError: Error = URLError(.timedOut)
        XCTAssertTrue(urlError.isRetryable)

        // Unknown errors should not be retryable
        struct UnknownError: Error {}
        let unknown: Error = UnknownError()
        XCTAssertFalse(unknown.isRetryable)
    }

    // MARK: - withRetry Helper Tests

    func testWithRetrySucceedsOnFirstAttempt() async throws {
        var attemptCount = 0

        let result = try await withRetry(policy: .default) {
            attemptCount += 1
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount, 1)
    }

    func testWithRetryRetriesOnRetryableError() async throws {
        var attemptCount = 0

        let result: String = try await withRetry(
            policy: RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1, jitterFactor: 0)
        ) {
            attemptCount += 1
            if attemptCount < 3 {
                throw URLError(.timedOut)
            }
            return "success after retries"
        }

        XCTAssertEqual(result, "success after retries")
        XCTAssertEqual(attemptCount, 3)
    }

    func testWithRetryDoesNotRetryNonRetryableError() async {
        var attemptCount = 0

        do {
            _ = try await withRetry(
                policy: RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1, jitterFactor: 0)
            ) {
                attemptCount += 1
                throw URLError(.badURL) // Non-retryable error
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount, 1, "Should not retry non-retryable errors")
        }
    }

    func testWithRetryExhaustsAttempts() async {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1, jitterFactor: 0)

        do {
            _ = try await withRetry(policy: policy) { () -> String in
                attemptCount += 1
                throw URLError(.timedOut) // Always fail
            }
            XCTFail("Should have thrown error")
        } catch {
            // Initial attempt + 2 retries = 3 total
            XCTAssertEqual(attemptCount, 3)
        }
    }

    func testWithRetryWithNonePolicy() async {
        var attemptCount = 0

        do {
            _ = try await withRetry(policy: .none) { () -> String in
                attemptCount += 1
                throw URLError(.timedOut)
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount, 1, "None policy should not retry")
        }
    }

    // MARK: - Global Retry Limiter Tests

    override func setUp() async throws {
        try await super.setUp()
        // Reset the global limiter before each test to ensure isolation
        #if DEBUG
            await GlobalRetryLimiter.shared.reset()
        #endif
    }

    func testGlobalRetryLimiterAllowsRetries() async {
        let limiter = GlobalRetryLimiter.shared

        // Should allow retry when under limit
        let began = await limiter.beginRetry()
        XCTAssertTrue(began)

        // Clean up
        await limiter.endRetry()
    }

    func testGlobalRetryLimiterTracksCount() async {
        let limiter = GlobalRetryLimiter.shared

        // Get initial count (should be 0 after reset)
        let initialCount = await limiter.currentRetryCount()
        XCTAssertEqual(initialCount, 0)

        // Begin a retry
        let began = await limiter.beginRetry()
        XCTAssertTrue(began)

        let newCount = await limiter.currentRetryCount()
        XCTAssertEqual(newCount, 1)

        // End the retry
        await limiter.endRetry()

        let finalCount = await limiter.currentRetryCount()
        XCTAssertEqual(finalCount, 0)
    }
}
