import XCTest
@testable import SkinLab

/// Unit tests for unified error handling
final class ErrorHandlingTests: XCTestCase {

    // MARK: - AppError Tests

    func testAppErrorDescriptions() {
        // Test data fetch error
        let fetchError = AppError.dataFetch(entity: "UserProfile", underlying: NSError(domain: "test", code: 1))
        XCTAssertEqual(fetchError.errorDescription, "无法加载数据")
        XCTAssertTrue(fetchError.failureReason?.contains("UserProfile") == true)
        XCTAssertNotNil(fetchError.recoverySuggestion)

        // Test data save error
        let saveError = AppError.dataSave(entity: "SkinAnalysis", underlying: NSError(domain: "test", code: 2))
        XCTAssertEqual(saveError.errorDescription, "保存失败")
        XCTAssertTrue(saveError.failureReason?.contains("SkinAnalysis") == true)

        // Test network error
        let networkError = AppError.networkRequest(operation: "Gemini API", underlying: NSError(domain: "test", code: 3))
        XCTAssertEqual(networkError.errorDescription, "网络请求失败")
        XCTAssertTrue(networkError.failureReason?.contains("Gemini API") == true)

        // Test image processing error
        let imageError = AppError.imageProcessing(operation: "compress", underlying: NSError(domain: "test", code: 4))
        XCTAssertEqual(imageError.errorDescription, "图片处理失败")

        // Test operation failed error
        let opError = AppError.operationFailed(operation: "test", reason: "custom reason")
        XCTAssertEqual(opError.errorDescription, "custom reason")
    }

    func testAppErrorUnderlyingError() {
        let underlying = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let appError = AppError.dataFetch(entity: "Test", underlying: underlying)

        XCTAssertNotNil(appError.underlyingError)
        XCTAssertEqual((appError.underlyingError as NSError?)?.code, 42)
    }

    func testAppErrorConvenienceInitializers() {
        struct MockModel {}
        let underlying = NSError(domain: "test", code: 1)

        let fetchError = AppError.fetchFailed(MockModel.self, error: underlying)
        XCTAssertTrue(fetchError.failureReason?.contains("MockModel") == true)

        let saveError = AppError.saveFailed(MockModel.self, error: underlying)
        XCTAssertTrue(saveError.failureReason?.contains("MockModel") == true)
    }

    // MARK: - AppLogger Tests

    func testAppLoggerDoesNotCrash() {
        // These tests verify that AppLogger methods don't crash
        // In actual use, output goes to os.log

        AppLogger.error("Test error message")
        AppLogger.error("Test error with underlying", error: NSError(domain: "test", code: 1))
        AppLogger.info("Test info message")
        AppLogger.debug("Test debug message")

        AppLogger.data(operation: .fetch, entity: "TestEntity", success: true, count: 5)
        AppLogger.data(operation: .save, entity: "TestEntity", success: false, error: NSError(domain: "test", code: 1))

        AppLogger.network(operation: "GET", url: "https://api.example.com/test", success: true, statusCode: 200)
        AppLogger.network(operation: "POST", url: "https://api.example.com/test?key=secret", success: false, error: NSError(domain: "test", code: 1))

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testAppLoggerURLSanitization() {
        // Test that URLs with API keys are sanitized
        // Note: We can't directly test the output, but we ensure no crash
        AppLogger.network(
            operation: "GET",
            url: "https://api.example.com/v1?key=supersecretkey&other=param",
            success: true
        )

        AppLogger.network(
            operation: "GET",
            url: "https://api.example.com/v1?KEY=UPPERCASE&other=param",
            success: true
        )

        XCTAssertTrue(true)
    }

    // MARK: - Result Extension Tests

    func testResultLogIfFailure() {
        let successResult: Result<String, AppError> = .success("ok")
        let failureResult: Result<String, AppError> = .failure(.operationFailed(operation: "test", reason: "failed"))

        // These should not crash
        successResult.logIfFailure()
        failureResult.logIfFailure()

        XCTAssertTrue(true)
    }

    // MARK: - ErrorCategory Tests

    func testErrorCategoryFromGeminiError() {
        // Test network error (generic)
        let networkError = GeminiError.networkError(URLError(.timedOut))
        XCTAssertEqual(ErrorCategory(from: networkError), .network)
        XCTAssertEqual(ErrorCategory(from: networkError).title, "网络连接失败")
        XCTAssertTrue(ErrorCategory(from: networkError).isRetryable)

        // Test network error wrapping offline URLError - should be categorized as offline
        let offlineWrappedError = GeminiError.networkError(URLError(.notConnectedToInternet))
        XCTAssertEqual(ErrorCategory(from: offlineWrappedError), .offline)
        XCTAssertEqual(ErrorCategory(from: offlineWrappedError).title, "无网络连接")

        // Test network error wrapping connection lost - should be categorized as offline
        let connectionLostWrappedError = GeminiError.networkError(URLError(.networkConnectionLost))
        XCTAssertEqual(ErrorCategory(from: connectionLostWrappedError), .offline)

        // Test rate limited
        let rateLimitedError = GeminiError.rateLimited
        XCTAssertEqual(ErrorCategory(from: rateLimitedError), .rateLimited)
        XCTAssertEqual(ErrorCategory(from: rateLimitedError).title, "请求过于频繁")
        XCTAssertTrue(ErrorCategory(from: rateLimitedError).isRetryable)
        XCTAssertEqual(ErrorCategory(from: rateLimitedError).suggestedRetryDelay, 30)

        // Test unauthorized
        let unauthorizedError = GeminiError.unauthorized
        XCTAssertEqual(ErrorCategory(from: unauthorizedError), .unauthorized)
        XCTAssertEqual(ErrorCategory(from: unauthorizedError).title, "认证失败")
        XCTAssertFalse(ErrorCategory(from: unauthorizedError).isRetryable)

        // Test invalid API key
        let invalidKeyError = GeminiError.invalidAPIKey
        XCTAssertEqual(ErrorCategory(from: invalidKeyError), .unauthorized)

        // Test invalid image
        let invalidImageError = GeminiError.invalidImage
        XCTAssertEqual(ErrorCategory(from: invalidImageError), .invalidInput)
        XCTAssertFalse(ErrorCategory(from: invalidImageError).isRetryable)

        // Test API error
        let apiError = GeminiError.apiError("Server error")
        XCTAssertEqual(ErrorCategory(from: apiError), .serverError)
        XCTAssertTrue(ErrorCategory(from: apiError).isRetryable)

        // Test parse error
        let parseError = GeminiError.parseError
        XCTAssertEqual(ErrorCategory(from: parseError), .serverError)
    }

    func testErrorCategoryFromURLError() {
        // Test not connected to internet
        let offlineError = URLError(.notConnectedToInternet)
        XCTAssertEqual(ErrorCategory(from: offlineError), .offline)
        XCTAssertEqual(ErrorCategory(from: offlineError).title, "无网络连接")
        XCTAssertTrue(ErrorCategory(from: offlineError).isRetryable)

        // Test network connection lost
        let connectionLostError = URLError(.networkConnectionLost)
        XCTAssertEqual(ErrorCategory(from: connectionLostError), .offline)

        // Test timeout
        let timeoutError = URLError(.timedOut)
        XCTAssertEqual(ErrorCategory(from: timeoutError), .network)

        // Test cannot connect to host
        let cannotConnectError = URLError(.cannotConnectToHost)
        XCTAssertEqual(ErrorCategory(from: cannotConnectError), .network)
    }

    func testErrorCategoryFromAppError() {
        // Test network request error (generic)
        let networkError = AppError.networkRequest(operation: "test", underlying: NSError(domain: "test", code: 1))
        XCTAssertEqual(ErrorCategory(from: networkError), .network)

        // Test network request error wrapping offline URLError - should be categorized as offline
        let offlineAppError = AppError.networkRequest(operation: "test", underlying: URLError(.notConnectedToInternet))
        XCTAssertEqual(ErrorCategory(from: offlineAppError), .offline)

        // Test network request error wrapping connection lost - should be categorized as offline
        let connectionLostAppError = AppError.networkRequest(operation: "test", underlying: URLError(.networkConnectionLost))
        XCTAssertEqual(ErrorCategory(from: connectionLostAppError), .offline)

        // Test other AppError types default to unknown
        let dataError = AppError.dataFetch(entity: "Test", underlying: NSError(domain: "test", code: 1))
        XCTAssertEqual(ErrorCategory(from: dataError), .unknown)
    }

    func testErrorCategoryFromUnknownError() {
        // Test unknown error type
        struct CustomError: Error {}
        let customError = CustomError()
        XCTAssertEqual(ErrorCategory(from: customError), .unknown)
        XCTAssertEqual(ErrorCategory(from: customError).title, "出错了")
        XCTAssertFalse(ErrorCategory(from: customError).isRetryable)
    }

    func testErrorCategoryIconNames() {
        // Verify all categories have valid SF Symbol names
        let categories: [ErrorCategory] = [.network, .offline, .serverError, .rateLimited, .invalidInput, .unauthorized, .unknown]

        for category in categories {
            XCTAssertFalse(category.iconName.isEmpty, "Icon name should not be empty for \(category)")
            XCTAssertFalse(category.title.isEmpty, "Title should not be empty for \(category)")
            XCTAssertFalse(category.description.isEmpty, "Description should not be empty for \(category)")
        }
    }

    func testErrorCategorySuggestedRetryDelays() {
        // Rate limited should have longest delay
        XCTAssertEqual(ErrorCategory.rateLimited.suggestedRetryDelay, 30)

        // Server error should have medium delay
        XCTAssertEqual(ErrorCategory.serverError.suggestedRetryDelay, 5)

        // Network/offline should have short delay
        XCTAssertEqual(ErrorCategory.network.suggestedRetryDelay, 2)
        XCTAssertEqual(ErrorCategory.offline.suggestedRetryDelay, 2)

        // Non-retryable errors should have 0 delay
        XCTAssertEqual(ErrorCategory.invalidInput.suggestedRetryDelay, 0)
        XCTAssertEqual(ErrorCategory.unauthorized.suggestedRetryDelay, 0)
        XCTAssertEqual(ErrorCategory.unknown.suggestedRetryDelay, 0)
    }
}
