# SkinLab Testing Guide

## Overview

SkinLab uses XCTest for unit and UI testing. This document outlines our testing conventions, strategies, and requirements.

## Test Naming Convention

Follow the pattern: `test_<methodName>_<scenario>_<expectedResult>()`

### Examples

```swift
// Good
func test_analyzeImage_withValidPhoto_returnsAnalysisResult()
func test_analyzeImage_withInvalidPhoto_throwsInvalidImageError()
func test_calculateScore_whenAllMetricsHigh_returns90Plus()
func test_saveProfile_withMissingRequiredFields_throwsValidationError()

// Bad
func testAnalyze()
func test_analysis()
func testItWorks()
```

### Components

| Component | Description | Example |
|-----------|-------------|---------|
| `methodName` | The method or functionality being tested | `analyzeImage`, `fetchProducts` |
| `scenario` | The specific condition or input state | `withValidPhoto`, `whenNetworkOffline` |
| `expectedResult` | What should happen | `returnsAnalysisResult`, `throwsError` |

## Test Structure

### AAA Pattern (Arrange-Act-Assert)

```swift
func test_calculateOverallScore_withMixedMetrics_returnsWeightedAverage() {
    // Arrange
    let issues = IssueScores(pores: 70, wrinkles: 80, spots: 60, acne: 90, texture: 75)
    let calculator = ScoreCalculator()
    
    // Act
    let result = calculator.calculateOverallScore(from: issues)
    
    // Assert
    XCTAssertEqual(result, 75, accuracy: 1.0)
}
```

### Given-When-Then (for BDD style)

```swift
func test_analysisHistory_whenUserHasNoHistory_showsEmptyState() {
    // Given
    let viewModel = HistoryViewModel(repository: MockEmptyRepository())
    
    // When
    viewModel.loadHistory()
    
    // Then
    XCTAssertTrue(viewModel.isEmpty)
    XCTAssertEqual(viewModel.analyses.count, 0)
}
```

## Test File Organization

```
SkinLabTests/
├── Features/
│   ├── Analysis/
│   │   ├── AnalysisViewModelTests.swift
│   │   ├── AnalyzeImageUseCaseTests.swift
│   │   └── ScoreCalculatorTests.swift
│   ├── Tracking/
│   │   └── TrackingViewModelTests.swift
│   └── Products/
│       └── ProductRepositoryTests.swift
├── Core/
│   ├── Network/
│   │   ├── APIClientTests.swift
│   │   └── GeminiServiceTests.swift
│   └── Storage/
│       └── SwiftDataManagerTests.swift
├── Mocks/
│   ├── MockAPIClient.swift
│   ├── MockGeminiService.swift
│   ├── MockAnalysisRepository.swift
│   └── MockStorageManager.swift
├── Helpers/
│   ├── XCTestCase+Extensions.swift
│   └── TestData.swift
└── Resources/
    ├── test_image.jpg
    └── mock_responses/
        └── analysis_response.json
```

## Mocking Strategies

### Protocol-Based Mocking

```swift
// Protocol
protocol AnalysisRepositoryProtocol {
    func analyze(image: UIImage) async throws -> SkinAnalysis
    func getHistory() async throws -> [SkinAnalysis]
}

// Mock
class MockAnalysisRepository: AnalysisRepositoryProtocol {
    var analyzeResult: Result<SkinAnalysis, Error> = .success(.mock)
    var analyzeCallCount = 0
    var lastAnalyzedImage: UIImage?
    
    func analyze(image: UIImage) async throws -> SkinAnalysis {
        analyzeCallCount += 1
        lastAnalyzedImage = image
        return try analyzeResult.get()
    }
    
    var historyResult: Result<[SkinAnalysis], Error> = .success([])
    
    func getHistory() async throws -> [SkinAnalysis] {
        return try historyResult.get()
    }
}
```

### Spy Pattern

```swift
class SpyGeminiService: GeminiServiceProtocol {
    private(set) var receivedPrompts: [String] = []
    private(set) var receivedImages: [Data] = []
    
    var stubbedResponse: GeminiResponse = .mock
    
    func analyze(image: Data, prompt: String) async throws -> GeminiResponse {
        receivedPrompts.append(prompt)
        receivedImages.append(image)
        return stubbedResponse
    }
}
```

### Stub Pattern

```swift
class StubNetworkClient: APIClientProtocol {
    var stubbedResult: Any?
    var stubbedError: Error?
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        if let error = stubbedError {
            throw error
        }
        guard let result = stubbedResult as? T else {
            fatalError("Stubbed result type mismatch")
        }
        return result
    }
}
```

## Async Testing

### Using async/await

```swift
func test_fetchProducts_withValidQuery_returnsMatchingProducts() async throws {
    // Arrange
    let repository = ProductRepository(storage: mockStorage)
    
    // Act
    let products = try await repository.search(query: "vitamin c")
    
    // Assert
    XCTAssertFalse(products.isEmpty)
    XCTAssertTrue(products.allSatisfy { $0.name.lowercased().contains("vitamin c") })
}
```

### Testing Published Properties

```swift
func test_viewModel_whenLoadCalled_updatesStateToLoaded() async {
    // Arrange
    let viewModel = AnalysisViewModel(repository: mockRepository)
    
    // Act
    await viewModel.loadAnalysis()
    
    // Assert
    XCTAssertEqual(viewModel.state, .loaded)
}
```

### Using Expectations (for Combine/callbacks)

```swift
func test_imageProcessor_whenProcessingComplete_notifiesDelegate() {
    // Arrange
    let expectation = expectation(description: "Processing complete")
    let processor = ImageProcessor()
    processor.onComplete = { _ in
        expectation.fulfill()
    }
    
    // Act
    processor.process(testImage)
    
    // Assert
    wait(for: [expectation], timeout: 5.0)
}
```

## Test Data

### Mock Objects

```swift
extension SkinAnalysis {
    static var mock: SkinAnalysis {
        SkinAnalysis(
            id: UUID(),
            skinType: .combination,
            skinAge: 25,
            overallScore: 78,
            issues: .mock,
            regions: .mock,
            recommendations: ["Use sunscreen daily", "Add retinol to routine"],
            analyzedAt: Date()
        )
    }
}

extension IssueScores {
    static var mock: IssueScores {
        IssueScores(pores: 70, wrinkles: 80, spots: 75, acne: 85, texture: 72)
    }
}
```

### JSON Fixtures

```swift
enum TestFixtures {
    static func loadJSON<T: Decodable>(_ filename: String) throws -> T {
        let bundle = Bundle(for: SkinLabTestCase.self)
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw TestError.fixtureNotFound(filename)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Usage
func test_parseResponse_withValidJSON_createsAnalysis() throws {
    let response: GeminiResponse = try TestFixtures.loadJSON("analysis_response")
    let analysis = try SkinAnalysisMapper.map(response)
    XCTAssertNotNil(analysis)
}
```

## Coverage Requirements

### Minimum Coverage: 60%

| Module | Target Coverage | Priority |
|--------|-----------------|----------|
| ViewModels | 80% | P0 |
| Use Cases | 90% | P0 |
| Repositories | 70% | P1 |
| Services | 70% | P1 |
| Utilities | 60% | P2 |
| Views | N/A | UI Tests |

### Checking Coverage

```bash
# Run tests with coverage
xcodebuild test \
    -project SkinLab.xcodeproj \
    -scheme SkinLab \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -enableCodeCoverage YES

# Generate report
xcrun xccov view --report Build/Logs/Test/*.xcresult
```

## UI Testing Guidelines

### Accessibility Identifiers

```swift
// In Views
Button("Analyze") {
    viewModel.analyze()
}
.accessibilityIdentifier("analyzeButton")

// In Tests
func test_analysisButton_whenTapped_startsAnalysis() {
    let analyzeButton = app.buttons["analyzeButton"]
    XCTAssertTrue(analyzeButton.exists)
    analyzeButton.tap()
}
```

### Launch Arguments

```swift
// Test setup
app.launchArguments = ["--uitesting", "--reset-state"]
app.launchEnvironment = [
    "MOCK_API": "true",
    "SKIP_ONBOARDING": "true"
]
app.launch()

// In App
if CommandLine.arguments.contains("--uitesting") {
    // Configure for UI testing
}
```

## Best Practices

### Do's ✅

- Test one behavior per test method
- Use descriptive test names
- Keep tests independent (no shared state)
- Use factory methods for test data
- Test edge cases and error conditions
- Clean up after tests

### Don'ts ❌

- Don't test private methods directly
- Don't use real network calls in unit tests
- Don't sleep in tests (use expectations)
- Don't test implementation details
- Don't ignore flaky tests (fix them)
- Don't duplicate production code in tests

## Running Tests

```bash
# All tests
make test

# Unit tests only
xcodebuild test -project SkinLab.xcodeproj -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests only
xcodebuild test -project SkinLab.xcodeproj -scheme SkinLabUITests -destination 'platform=iOS Simulator,name=iPhone 15'

# Specific test
xcodebuild test -project SkinLab.xcodeproj -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SkinLabTests/AnalysisViewModelTests/test_analyzeImage_withValidPhoto_returnsAnalysisResult
```

## Continuous Integration

Tests are automatically run on:
- Every push to `main` and `develop`
- All pull requests
- Nightly scheduled builds

See `.github/workflows/ci.yml` for configuration.
