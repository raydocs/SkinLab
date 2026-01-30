// SkinLabTests/Mocks/MockURLProtocol.swift
import Foundation

/// A URLProtocol subclass that intercepts network requests for testing.
/// Configure with static properties before use.
final class MockURLProtocol: URLProtocol {
    // MARK: - Static Configuration

    /// The mock response data to return
    static var mockResponseData: Data?

    /// The HTTP status code to return
    static var mockStatusCode: Int = 200

    /// Optional error to throw instead of returning data
    static var mockError: Error?

    /// Captured request for inspection in tests
    static var capturedRequest: URLRequest?

    /// Captured request body data (since httpBody might be nil after sending)
    static var capturedRequestBody: Data?

    /// Custom response handler for complex scenarios
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    // MARK: - URLProtocol Overrides

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests when using this protocol
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        // Capture the request for test inspection
        MockURLProtocol.capturedRequest = request

        // Capture body data (httpBody might be nil, try httpBodyStream)
        if let bodyData = request.httpBody {
            MockURLProtocol.capturedRequestBody = bodyData
        } else if let bodyStream = request.httpBodyStream {
            bodyStream.open()
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
                bodyStream.close()
            }
            while bodyStream.hasBytesAvailable {
                let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data.append(buffer, count: bytesRead)
                } else {
                    break
                }
            }
            MockURLProtocol.capturedRequestBody = data
        }

        // Check for error first
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        // Use custom handler if provided
        if let handler = MockURLProtocol.requestHandler {
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
            return
        }

        // Default behavior with static properties
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: MockURLProtocol.mockStatusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = MockURLProtocol.mockResponseData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // No-op for mock
    }

    // MARK: - Helper Methods

    /// Reset all static configuration to defaults
    static func reset() {
        mockResponseData = nil
        mockStatusCode = 200
        mockError = nil
        capturedRequest = nil
        capturedRequestBody = nil
        requestHandler = nil
    }

    /// Create a URLSession configured to use this mock protocol
    static func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
