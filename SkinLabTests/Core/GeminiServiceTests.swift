// SkinLabTests/Core/GeminiServiceTests.swift
@testable import SkinLab
import UIKit
import XCTest

final class GeminiServiceTests: XCTestCase {
    var sut: GeminiService!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        let mockSession = MockURLProtocol.createMockSession()
        sut = GeminiService(session: mockSession, apiKey: "test-key")
    }

    override func tearDown() {
        sut = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Create a test image for skin analysis
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    /// Create a valid OpenRouter-style skin analysis response
    private func createValidSkinAnalysisResponse() -> Data {
        let responseJSON = """
        {
            "choices": [
                {
                    "message": {
                        "content": "{\\"skinType\\": \\"combination\\", \\"skinAge\\": 28, \\"overallScore\\": 75, \\"issues\\": {\\"spots\\": 3, \\"acne\\": 2, \\"pores\\": 4, \\"wrinkles\\": 1, \\"redness\\": 2, \\"evenness\\": 3, \\"texture\\": 2}, \\"regions\\": {\\"tZone\\": 70, \\"leftCheek\\": 75, \\"rightCheek\\": 74, \\"eyeArea\\": 80, \\"chin\\": 72}, \\"recommendations\\": [\\"Use sunscreen daily\\", \\"Apply vitamin C serum\\"], \\"confidenceScore\\": 85}"
                    }
                }
            ]
        }
        """
        return responseJSON.data(using: .utf8)!
    }

    /// Create a valid OpenRouter-style ingredient analysis response
    private func createValidIngredientAnalysisResponse() -> Data {
        let responseJSON = """
        {
            "choices": [
                {
                    "message": {
                        "content": "{\\"summary\\": \\"This formula is suitable for combination skin.\\", \\"riskTags\\": [\\"Contains fragrance\\"], \\"ingredientConcerns\\": [{\\"name\\": \\"Fragrance\\", \\"reason\\": \\"May cause sensitivity\\", \\"riskLevel\\": \\"low\\"}], \\"compatibilityScore\\": 75, \\"usageTips\\": [\\"Apply in the morning\\", \\"Follow with sunscreen\\"], \\"avoidCombos\\": [\\"Avoid using with retinol\\"], \\"confidence\\": 80}"
                    }
                }
            ]
        }
        """
        return responseJSON.data(using: .utf8)!
    }

    /// Create an invalid JSON response
    private func createInvalidJSONResponse() -> Data {
        let responseJSON = """
        {
            "choices": [
                {
                    "message": {
                        "content": "This is not valid JSON"
                    }
                }
            ]
        }
        """
        return responseJSON.data(using: .utf8)!
    }

    // MARK: - Test Cases

    /// Test 1: Valid skin analysis response should be parsed correctly
    func testAnalyzeSkinWithValidResponse() async throws {
        // Given: A valid API response
        MockURLProtocol.mockResponseData = createValidSkinAnalysisResponse()
        MockURLProtocol.mockStatusCode = 200

        let testImage = createTestImage()

        // When
        let result = try await sut.analyzeSkin(image: testImage)

        // Then
        XCTAssertEqual(result.skinType, .combination, "Should parse skin type correctly")
        XCTAssertEqual(result.skinAge, 28, "Should parse skin age correctly")
        XCTAssertEqual(result.overallScore, 75, "Should parse overall score correctly")
        XCTAssertEqual(result.issues.spots, 3, "Should parse spots score correctly")
        XCTAssertEqual(result.issues.acne, 2, "Should parse acne score correctly")
        XCTAssertEqual(result.issues.pores, 4, "Should parse pores score correctly")
        XCTAssertEqual(result.regions.tZone, 70, "Should parse T-zone score correctly")
        XCTAssertEqual(result.confidenceScore, 85, "Should parse confidence score correctly")
        XCTAssertEqual(result.recommendations.count, 2, "Should parse recommendations")
    }

    /// Test 2: Network error should throw GeminiError.networkError
    func testAnalyzeSkinWithNetworkError() async {
        // Given: A network error
        let networkError = URLError(.notConnectedToInternet)
        MockURLProtocol.mockError = networkError

        let testImage = createTestImage()

        // When/Then
        do {
            _ = try await sut.analyzeSkin(image: testImage)
            XCTFail("Should throw network error")
        } catch let error as GeminiError {
            if case .networkError = error {
                // Expected error type
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Expected GeminiError, got \(error)")
        }
    }

    /// Test 3: Invalid JSON should throw GeminiError.parseError
    func testAnalyzeSkinWithInvalidJSON() async {
        // Given: An invalid JSON response
        MockURLProtocol.mockResponseData = createInvalidJSONResponse()
        MockURLProtocol.mockStatusCode = 200

        let testImage = createTestImage()

        // When/Then
        do {
            _ = try await sut.analyzeSkin(image: testImage)
            XCTFail("Should throw parse error")
        } catch let error as GeminiError {
            if case .parseError = error {
                // Expected error type
            } else {
                XCTFail("Expected parseError, got \(error)")
            }
        } catch {
            XCTFail("Expected GeminiError, got \(error)")
        }
    }

    /// Test 4: Request construction should be correct
    func testRequestConstruction() async throws {
        // Given: A valid response (to let the request complete)
        MockURLProtocol.mockResponseData = createValidSkinAnalysisResponse()
        MockURLProtocol.mockStatusCode = 200

        let testImage = createTestImage()

        // When
        _ = try await sut.analyzeSkin(image: testImage)

        // Then: Verify captured request
        let capturedRequest = MockURLProtocol.capturedRequest
        XCTAssertNotNil(capturedRequest, "Request should be captured")

        // Verify URL contains /chat/completions
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("/chat/completions"), "URL should contain /chat/completions endpoint")

        // Verify Authorization header contains Bearer prefix
        let authHeader = capturedRequest?.value(forHTTPHeaderField: "Authorization") ?? ""
        XCTAssertTrue(authHeader.hasPrefix("Bearer "), "Authorization header should have Bearer prefix")

        // Verify Content-Type header
        let contentType = capturedRequest?.value(forHTTPHeaderField: "Content-Type")
        XCTAssertEqual(contentType, "application/json", "Content-Type should be application/json")

        // Verify HTTP method
        XCTAssertEqual(capturedRequest?.httpMethod, "POST", "HTTP method should be POST")

        // Verify body contains expected structure (use capturedRequestBody since httpBody may be nil)
        if let bodyData = MockURLProtocol.capturedRequestBody {
            let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            XCTAssertNotNil(bodyJSON, "Body should be valid JSON")

            // Check model field exists
            XCTAssertNotNil(bodyJSON?["model"], "Body should contain model field")

            // Check messages array exists and contains image data
            if let messages = bodyJSON?["messages"] as? [[String: Any]],
               let firstMessage = messages.first,
               let content = firstMessage["content"] as? [[String: Any]] {
                // Find the image_url content
                let hasImageContent = content.contains { item in
                    if let type = item["type"] as? String, type == "image_url",
                       let imageUrl = item["image_url"] as? [String: Any],
                       let url = imageUrl["url"] as? String {
                        return url.hasPrefix("data:image/jpeg;base64,") && url.count > 30
                    }
                    return false
                }
                XCTAssertTrue(
                    hasImageContent,
                    "Body should contain base64 image data with data:image/jpeg;base64, prefix"
                )
            } else {
                XCTFail("Body should contain messages array with content")
            }
        } else {
            XCTFail("Request should have body data")
        }
    }

    /// Test 5: Valid ingredient analysis response should be parsed correctly
    func testAnalyzeIngredientsWithValidResponse() async throws {
        // Given: A valid ingredient analysis response
        MockURLProtocol.mockResponseData = createValidIngredientAnalysisResponse()
        MockURLProtocol.mockStatusCode = 200

        let request = IngredientAIRequest(
            ingredients: ["Niacinamide", "Hyaluronic Acid", "Fragrance"],
            profileSnapshot: nil,
            historySnapshot: nil,
            preferences: []
        )

        // When
        let result = try await sut.analyzeIngredients(request: request)

        // Then
        XCTAssertEqual(
            result.summary,
            "This formula is suitable for combination skin.",
            "Should parse summary correctly"
        )
        XCTAssertEqual(result.compatibilityScore, 75, "Should parse compatibility score correctly")
        XCTAssertEqual(result.confidence, 80, "Should parse confidence correctly")
        XCTAssertEqual(result.riskTags.count, 1, "Should parse risk tags")
        XCTAssertEqual(result.ingredientConcerns.count, 1, "Should parse ingredient concerns")
        XCTAssertEqual(result.usageTips.count, 2, "Should parse usage tips")
        XCTAssertEqual(result.avoidCombos.count, 1, "Should parse avoid combos")

        // Verify ingredient concern details
        if let concern = result.ingredientConcerns.first {
            XCTAssertEqual(concern.name, "Fragrance", "Should parse concern name")
            XCTAssertEqual(concern.riskLevel, .low, "Should parse risk level")
        }
    }

    /// Test 6: Unauthorized (401) response should throw GeminiError.unauthorized
    func testAnalyzeSkinWithUnauthorizedResponse() async {
        // Given: A 401 unauthorized response
        MockURLProtocol.mockResponseData = Data()
        MockURLProtocol.mockStatusCode = 401

        let testImage = createTestImage()

        // When/Then
        do {
            _ = try await sut.analyzeSkin(image: testImage)
            XCTFail("Should throw unauthorized error")
        } catch let error as GeminiError {
            if case .unauthorized = error {
                // Expected error type
            } else {
                XCTFail("Expected unauthorized, got \(error)")
            }
        } catch {
            XCTFail("Expected GeminiError, got \(error)")
        }
    }

    /// Test 7: API error response should throw GeminiError.apiError
    func testAnalyzeSkinWithAPIErrorResponse() async {
        // Given: A 500 server error response
        let errorMessage = "Internal server error"
        MockURLProtocol.mockResponseData = errorMessage.data(using: .utf8)
        MockURLProtocol.mockStatusCode = 500

        let testImage = createTestImage()

        // When/Then
        do {
            _ = try await sut.analyzeSkin(image: testImage)
            XCTFail("Should throw API error")
        } catch let error as GeminiError {
            if case let .apiError(message) = error {
                XCTAssertEqual(message, errorMessage, "Should contain error message")
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected GeminiError, got \(error)")
        }
    }

    /// Test 8: Ingredient analysis request construction should be correct
    func testIngredientAnalysisRequestConstruction() async throws {
        // Given: A valid response
        MockURLProtocol.mockResponseData = createValidIngredientAnalysisResponse()
        MockURLProtocol.mockStatusCode = 200

        let request = IngredientAIRequest(
            ingredients: ["Vitamin C", "Retinol"],
            profileSnapshot: nil,
            historySnapshot: nil,
            preferences: ["hydrating"]
        )

        // When
        _ = try await sut.analyzeIngredients(request: request)

        // Then: Verify captured request
        let capturedRequest = MockURLProtocol.capturedRequest
        XCTAssertNotNil(capturedRequest, "Request should be captured")

        // Verify URL
        let urlString = capturedRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("/chat/completions"), "URL should contain /chat/completions endpoint")

        // Verify headers
        let authHeader = capturedRequest?.value(forHTTPHeaderField: "Authorization") ?? ""
        XCTAssertTrue(authHeader.hasPrefix("Bearer "), "Authorization header should have Bearer prefix")

        let contentType = capturedRequest?.value(forHTTPHeaderField: "Content-Type")
        XCTAssertEqual(contentType, "application/json", "Content-Type should be application/json")
    }

    /// Test 9: Response with markdown code blocks should be parsed correctly
    func testAnalyzeSkinWithMarkdownWrappedResponse() async throws {
        // Given: A response with markdown code blocks
        let responseJSON = """
        {
            "choices": [
                {
                    "message": {
                        "content": "```json\\n{\\"skinType\\": \\"oily\\", \\"skinAge\\": 25, \\"overallScore\\": 80, \\"issues\\": {\\"spots\\": 2, \\"acne\\": 3, \\"pores\\": 5, \\"wrinkles\\": 1, \\"redness\\": 1, \\"evenness\\": 2, \\"texture\\": 2}, \\"regions\\": {\\"tZone\\": 65, \\"leftCheek\\": 78, \\"rightCheek\\": 77, \\"eyeArea\\": 85, \\"chin\\": 70}, \\"recommendations\\": [\\"Control oil\\"], \\"confidenceScore\\": 90}\\n```"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponseData = responseJSON.data(using: .utf8)
        MockURLProtocol.mockStatusCode = 200

        let testImage = createTestImage()

        // When
        let result = try await sut.analyzeSkin(image: testImage)

        // Then: Should still parse correctly despite markdown wrapping
        XCTAssertEqual(result.skinType, .oily, "Should parse skin type from markdown-wrapped response")
        XCTAssertEqual(result.skinAge, 25, "Should parse skin age from markdown-wrapped response")
    }

    /// Test 10: Response with float values should be parsed correctly (converted to Int)
    func testAnalyzeSkinWithFloatValues() async throws {
        // Given: A response with float values instead of integers
        let responseJSON = """
        {
            "choices": [
                {
                    "message": {
                        "content": "{\\"skinType\\": \\"dry\\", \\"skinAge\\": 30.5, \\"overallScore\\": 72.8, \\"issues\\": {\\"spots\\": 2.1, \\"acne\\": 1.9, \\"pores\\": 3.0, \\"wrinkles\\": 2.5, \\"redness\\": 1.0, \\"evenness\\": 2.0, \\"texture\\": 2.0}, \\"regions\\": {\\"tZone\\": 75.5, \\"leftCheek\\": 80.0, \\"rightCheek\\": 79.0, \\"eyeArea\\": 85.0, \\"chin\\": 77.0}, \\"recommendations\\": [\\"Hydrate\\"], \\"confidenceScore\\": 88.0}"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponseData = responseJSON.data(using: .utf8)
        MockURLProtocol.mockStatusCode = 200

        let testImage = createTestImage()

        // When
        let result = try await sut.analyzeSkin(image: testImage)

        // Then: Float values should be rounded to integers
        XCTAssertEqual(result.skinType, .dry, "Should parse skin type")
        XCTAssertEqual(result.skinAge, 31, "Should round skin age (30.5 -> 31)")
        XCTAssertEqual(result.overallScore, 73, "Should round overall score (72.8 -> 73)")
        XCTAssertEqual(result.issues.spots, 2, "Should round spots (2.1 -> 2)")
        XCTAssertEqual(result.regions.tZone, 76, "Should round T-zone (75.5 -> 76)")
    }
}
