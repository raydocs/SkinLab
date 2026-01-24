import Foundation

// MARK: - App Configuration
/// Centralized configuration management for the SkinLab app.
/// All hardcoded URLs, API settings, and magic numbers should be defined here.
enum AppConfiguration {

    // MARK: - Environment
    enum Environment {
        case development
        case staging
        case production

        var apiBaseURL: String {
            switch self {
            case .development:
                return "https://openrouter.ai/api/v1"
            case .staging:
                return "https://staging-api.skinlab.app/v1"
            case .production:
                return "https://openrouter.ai/api/v1"
            }
        }

        var isDebug: Bool {
            switch self {
            case .development, .staging:
                return true
            case .production:
                return false
            }
        }
    }

    /// Current environment based on build configuration
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    // MARK: - API Configuration
    enum API {
        /// Base URL for OpenRouter API
        static var baseURL: String { current.apiBaseURL }

        /// HTTP Referer header value for API requests
        static let referer = "https://skinlab.app"

        /// X-Title header value for API requests
        static let title = "SkinLab"

        /// Default request timeout in seconds
        static let requestTimeout: TimeInterval = 30

        /// Resource timeout in seconds
        static let resourceTimeout: TimeInterval = 60

        /// Maximum retry attempts for API requests
        static let maxRetryAttempts = 3

        /// AI model for skin analysis
        static let skinAnalysisModel = "google/gemini-3-flash-preview"

        /// AI model for routine generation
        static let routineGenerationModel = "google/gemini-2.0-flash-exp:free"
    }

    // MARK: - Support Configuration
    enum Support {
        /// Support email address
        static let email = "support@skinlab.app"

        /// App website URL
        static let websiteURL = "https://skinlab.app"
    }

    // MARK: - Image Processing
    enum ImageProcessing {
        /// Maximum dimension for optimized images
        static let maxImageDimension: CGFloat = 1024

        /// JPEG compression quality for uploads
        static let compressionQuality: CGFloat = 0.6
    }

    // MARK: - Limits
    enum Limits {
        /// Maximum photos per day
        static let maxPhotosPerDay = 5

        /// Maximum products per check-in
        static let maxProductsPerCheckIn = 10

        /// Cache expiration in hours
        static let cacheExpirationHours = 24

        /// Maximum tokens for skin analysis response
        static let skinAnalysisMaxTokens = 512

        /// Maximum tokens for ingredient analysis response
        static let ingredientAnalysisMaxTokens = 1024

        /// Maximum tokens for routine generation response
        static let routineGenerationMaxTokens = 1024
    }

    // MARK: - Feature Flags
    enum Features {
        /// Weather feature enabled
        static var weatherEnabled: Bool { true }

        /// Analytics enabled (disabled in debug)
        static var analyticsEnabled: Bool { !current.isDebug }

        /// Verbose logging enabled
        static var verboseLoggingEnabled: Bool { current.isDebug }
    }
}
