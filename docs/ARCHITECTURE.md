# SkinLab Architecture

## System Overview

SkinLab is an AI-powered skin analysis and skincare recommendation iOS application built with SwiftUI and following MVVM + Clean Architecture principles.

```mermaid
graph TB
    subgraph "Presentation Layer"
        Views[SwiftUI Views]
        ViewModels[ViewModels]
    end
    
    subgraph "Domain Layer"
        UseCases[Use Cases]
        Entities[Domain Entities]
        Protocols[Repository Protocols]
    end
    
    subgraph "Data Layer"
        Repositories[Repository Implementations]
        DataSources[Data Sources]
        Network[Network Layer]
        Storage[Storage Layer]
    end
    
    subgraph "External"
        GeminiAPI[Gemini Vision API]
        SwiftData[(SwiftData)]
        Keychain[(Keychain)]
    end
    
    Views --> ViewModels
    ViewModels --> UseCases
    UseCases --> Protocols
    Repositories --> Protocols
    Repositories --> DataSources
    DataSources --> Network
    DataSources --> Storage
    Network --> GeminiAPI
    Storage --> SwiftData
    Storage --> Keychain
```

## MVVM + Clean Architecture Layers

### Presentation Layer
- **Views**: SwiftUI views responsible for UI rendering
- **ViewModels**: Handle presentation logic, state management, and user interactions

### Domain Layer
- **Use Cases**: Business logic encapsulation
- **Entities**: Core business models
- **Protocols**: Repository interfaces for dependency inversion

### Data Layer
- **Repositories**: Concrete implementations of domain protocols
- **Data Sources**: Remote and local data source implementations
- **Mappers**: DTO to Entity conversions

## Feature Modules Structure

```mermaid
graph LR
    subgraph "Feature Modules"
        Analysis[Analysis Module]
        Tracking[Tracking Module]
        Products[Products Module]
        Profile[Profile Module]
        Community[Community Module]
    end
    
    subgraph "Core Modules"
        Network[Network]
        Storage[Storage]
        Utils[Utils]
    end
    
    subgraph "UI Module"
        Components[Shared Components]
        Theme[Theme]
    end
    
    Analysis --> Network
    Analysis --> Storage
    Analysis --> Components
    
    Tracking --> Storage
    Tracking --> Components
    
    Products --> Network
    Products --> Storage
    Products --> Components
    
    Profile --> Storage
    Profile --> Components
    
    Community --> Network
    Community --> Storage
    Community --> Components
```

### Module Breakdown

| Module | Description | Key Components |
|--------|-------------|----------------|
| **Analysis** | AI skin analysis | CameraView, AnalysisViewModel, GeminiService |
| **Tracking** | 28-day effect tracking | TrackingView, TrackingViewModel, ProgressCharts |
| **Products** | Product database & scanner | ProductListView, IngredientScanner, ProductRepository |
| **Profile** | User profile & settings | ProfileView, SkinFingerprint, SettingsView |
| **Community** | Social features | CommunityFeed, SkinTwinMatcher |

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant View
    participant ViewModel
    participant UseCase
    participant Repository
    participant API/Storage
    
    User->>View: Captures Photo
    View->>ViewModel: analyzeImage(image)
    ViewModel->>ViewModel: Update state (loading)
    ViewModel->>UseCase: execute(image)
    UseCase->>Repository: analyze(image)
    Repository->>API/Storage: POST /analyze
    API/Storage-->>Repository: AnalysisDTO
    Repository-->>UseCase: SkinAnalysis (Entity)
    UseCase-->>ViewModel: Result<SkinAnalysis>
    ViewModel->>ViewModel: Update state (success/error)
    ViewModel-->>View: Published state change
    View-->>User: Display Results
```

## Network Layer

### Gemini Vision API Integration

```mermaid
graph TB
    subgraph "Network Layer"
        APIClient[APIClient]
        GeminiService[GeminiService]
        ImageProcessor[ImageProcessor]
    end
    
    subgraph "Configuration"
        Endpoints[API Endpoints]
        Interceptors[Request Interceptors]
        ErrorHandler[Error Handler]
    end
    
    subgraph "Models"
        Request[Request DTOs]
        Response[Response DTOs]
    end
    
    GeminiService --> APIClient
    GeminiService --> ImageProcessor
    APIClient --> Endpoints
    APIClient --> Interceptors
    APIClient --> ErrorHandler
    GeminiService --> Request
    GeminiService --> Response
```

### API Client Architecture

```swift
// Protocol-based design for testability
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// Endpoint configuration
enum GeminiEndpoint: Endpoint {
    case analyzeImage(Data)
    case generateContent(String)
    
    var path: String { ... }
    var method: HTTPMethod { ... }
    var body: Data? { ... }
}
```

### Error Handling

| Error Type | Description | Recovery Action |
|------------|-------------|-----------------|
| `NetworkError.noConnection` | No internet | Show offline state |
| `NetworkError.timeout` | Request timeout | Retry with backoff |
| `NetworkError.serverError` | 5xx response | Retry or show error |
| `AnalysisError.invalidImage` | Bad image quality | Request new photo |
| `AnalysisError.parseError` | Response parsing failed | Log and show generic error |

## Storage Layer

```mermaid
graph TB
    subgraph "Storage Layer"
        SwiftDataManager[SwiftDataManager]
        KeychainManager[KeychainManager]
        UserDefaultsManager[UserDefaultsManager]
    end
    
    subgraph "SwiftData Models"
        AnalysisRecord[AnalysisRecord]
        ProductRecord[ProductRecord]
        TrackingRecord[TrackingRecord]
        UserProfileRecord[UserProfileRecord]
    end
    
    subgraph "Secure Storage"
        APIKeys[API Keys]
        UserCredentials[User Credentials]
    end
    
    subgraph "Preferences"
        AppSettings[App Settings]
        FeatureFlags[Feature Flags]
    end
    
    SwiftDataManager --> AnalysisRecord
    SwiftDataManager --> ProductRecord
    SwiftDataManager --> TrackingRecord
    SwiftDataManager --> UserProfileRecord
    
    KeychainManager --> APIKeys
    KeychainManager --> UserCredentials
    
    UserDefaultsManager --> AppSettings
    UserDefaultsManager --> FeatureFlags
```

### SwiftData Schema

```swift
@Model
class AnalysisRecord {
    @Attribute(.unique) var id: UUID
    var skinType: String
    var skinAge: Int
    var overallScore: Int
    var issuesJSON: Data  // Encoded IssueScores
    var regionsJSON: Data // Encoded RegionScores
    var recommendations: [String]
    var analyzedAt: Date
    var imageHash: String?
    
    @Relationship(deleteRule: .cascade)
    var trackingRecords: [TrackingRecord]
}

@Model
class TrackingRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var score: Int
    var notes: String?
    var photoHash: String?
    
    @Relationship(inverse: \AnalysisRecord.trackingRecords)
    var analysis: AnalysisRecord?
}
```

### Keychain Security

| Item | Purpose | Access Control |
|------|---------|----------------|
| `gemini-api-key` | Gemini API authentication | After first unlock |
| `user-token` | User session token | When unlocked |
| `encryption-key` | Local data encryption | When unlocked, this device only |

## Dependency Injection

```mermaid
graph TB
    subgraph "DI Container"
        Container[AppContainer]
    end
    
    subgraph "Registrations"
        Services[Services]
        Repositories[Repositories]
        UseCases[Use Cases]
        ViewModels[ViewModels]
    end
    
    Container --> Services
    Container --> Repositories
    Container --> UseCases
    Container --> ViewModels
    
    Services --> Repositories
    Repositories --> UseCases
    UseCases --> ViewModels
```

### Container Setup

```swift
@MainActor
class AppContainer: ObservableObject {
    // Services
    lazy var apiClient: APIClientProtocol = APIClient()
    lazy var geminiService: GeminiServiceProtocol = GeminiService(client: apiClient)
    lazy var storageManager: StorageManagerProtocol = SwiftDataManager()
    lazy var keychainManager: KeychainManagerProtocol = KeychainManager()
    
    // Repositories
    lazy var analysisRepository: AnalysisRepositoryProtocol = 
        AnalysisRepository(gemini: geminiService, storage: storageManager)
    lazy var productRepository: ProductRepositoryProtocol = 
        ProductRepository(storage: storageManager)
    
    // Use Cases
    lazy var analyzeImageUseCase: AnalyzeImageUseCaseProtocol = 
        AnalyzeImageUseCase(repository: analysisRepository)
    
    // ViewModels
    func makeAnalysisViewModel() -> AnalysisViewModel {
        AnalysisViewModel(analyzeUseCase: analyzeImageUseCase)
    }
}
```

## Image Processing Pipeline

```mermaid
graph LR
    Capture[Photo Capture] --> Validate[Validation]
    Validate --> Preprocess[Preprocessing]
    Preprocess --> Compress[Compression]
    Compress --> Encode[Base64 Encode]
    Encode --> Upload[API Upload]
    
    Validate -->|Invalid| Error[Show Error]
    Preprocess -->|Poor Quality| Retry[Request Retry]
```

### Processing Steps

1. **Capture**: Camera or photo library selection
2. **Validation**: Check image dimensions, format, face detection
3. **Preprocessing**: Normalize lighting, crop to face region
4. **Compression**: JPEG compression to target size (<2MB)
5. **Encoding**: Base64 encoding for API transmission
6. **Upload**: Send to Gemini Vision API

## Threading Model

```mermaid
graph TB
    subgraph "Main Thread"
        UI[UI Updates]
        ViewModels[ViewModel State]
    end
    
    subgraph "Background Threads"
        Network[Network Requests]
        ImageProc[Image Processing]
        DataParsing[Data Parsing]
    end
    
    subgraph "Actor Isolation"
        Storage[Storage Operations]
    end
    
    UI <--> ViewModels
    ViewModels --> Network
    ViewModels --> ImageProc
    Network --> DataParsing
    DataParsing --> Storage
    Storage --> ViewModels
```

### Concurrency Guidelines

- Use `@MainActor` for all ViewModels
- Use Swift Concurrency (`async/await`) for all async operations
- Use `Task { }` for launching async work from sync contexts
- Use actors for shared mutable state (e.g., `StorageActor`)

## Performance Optimizations

| Area | Optimization | Impact |
|------|--------------|--------|
| **Images** | Lazy loading, caching, thumbnails | Memory, load time |
| **Network** | Request deduplication, retry with backoff | Reliability |
| **Storage** | Batch operations, background saves | UI responsiveness |
| **Lists** | Lazy stacks, prefetching | Scroll performance |
| **Analysis** | Result caching, incremental updates | API costs, speed |

## Security Considerations

1. **API Keys**: Stored in Keychain, never in code or UserDefaults
2. **User Photos**: Processed locally, sent via HTTPS, not stored on servers
3. **Local Data**: SwiftData with encrypted containers
4. **Network**: Certificate pinning, request signing
5. **Privacy**: Minimal data collection, user consent, data export/deletion
