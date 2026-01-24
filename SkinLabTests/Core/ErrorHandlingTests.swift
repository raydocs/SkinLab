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
}
