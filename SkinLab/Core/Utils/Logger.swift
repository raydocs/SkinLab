import Foundation
import os.log

// MARK: - App Logger
/// Unified logging utility for SkinLab
/// Uses os.log for system-level logging with structured categories

enum AppLogger {
    // MARK: - Private Properties

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.skinlab"

    // MARK: - Log Categories

    private static let errorLog = OSLog(subsystem: subsystem, category: "Error")
    private static let infoLog = OSLog(subsystem: subsystem, category: "Info")
    private static let debugLog = OSLog(subsystem: subsystem, category: "Debug")
    private static let dataLog = OSLog(subsystem: subsystem, category: "Data")
    private static let networkLog = OSLog(subsystem: subsystem, category: "Network")

    // MARK: - Public Methods

    /// Log an error with optional underlying error
    /// - Parameters:
    ///   - message: Description of what went wrong
    ///   - error: Optional underlying error
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let location = "\(fileName):\(line) \(function)"

        if let error = error {
            os_log(.error, log: errorLog, "[%{public}@] %{public}@: %{public}@",
                   location, message, error.localizedDescription)
            #if DEBUG
            print("[ERROR] [\(location)] \(message): \(error.localizedDescription)")
            #endif
        } else {
            os_log(.error, log: errorLog, "[%{public}@] %{public}@", location, message)
            #if DEBUG
            print("[ERROR] [\(location)] \(message)")
            #endif
        }
    }

    /// Log an informational message
    /// - Parameters:
    ///   - message: Information to log
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    static func info(
        _ message: String,
        file: String = #file,
        function: String = #function
    ) {
        let fileName = (file as NSString).lastPathComponent
        os_log(.info, log: infoLog, "[%{public}@:%{public}@] %{public}@",
               fileName, function, message)
        #if DEBUG
        print("[INFO] [\(fileName):\(function)] \(message)")
        #endif
    }

    /// Log a debug message (only in DEBUG builds)
    /// - Parameters:
    ///   - message: Debug information
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        os_log(.debug, log: debugLog, "[%{public}@:%{public}@] %{public}@",
               fileName, function, message)
        print("[DEBUG] [\(fileName):\(function)] \(message)")
        #endif
    }

    /// Log a data operation (fetch, save, delete)
    /// - Parameters:
    ///   - operation: Type of operation (fetch, save, delete)
    ///   - entity: Entity type being operated on
    ///   - success: Whether the operation succeeded
    ///   - count: Number of records affected (optional)
    ///   - error: Error if operation failed (optional)
    static func data(
        operation: DataOperation,
        entity: String,
        success: Bool,
        count: Int? = nil,
        error: Error? = nil
    ) {
        let countStr = count.map { " (\($0) records)" } ?? ""

        if success {
            os_log(.info, log: dataLog, "%{public}@ %{public}@ succeeded%{public}@",
                   operation.rawValue, entity, countStr)
            #if DEBUG
            print("[DATA] \(operation.rawValue) \(entity) succeeded\(countStr)")
            #endif
        } else {
            let errorStr = error?.localizedDescription ?? "Unknown error"
            os_log(.error, log: dataLog, "%{public}@ %{public}@ failed: %{public}@",
                   operation.rawValue, entity, errorStr)
            #if DEBUG
            print("[DATA] \(operation.rawValue) \(entity) failed: \(errorStr)")
            #endif
        }
    }

    /// Log a network operation
    /// - Parameters:
    ///   - operation: Description of the network operation
    ///   - url: URL being accessed (will be sanitized)
    ///   - success: Whether the operation succeeded
    ///   - statusCode: HTTP status code (optional)
    ///   - error: Error if operation failed (optional)
    static func network(
        operation: String,
        url: String,
        success: Bool,
        statusCode: Int? = nil,
        error: Error? = nil
    ) {
        let sanitizedURL = sanitizeURL(url)
        let statusStr = statusCode.map { " (HTTP \($0))" } ?? ""

        if success {
            os_log(.info, log: networkLog, "%{public}@ to %{public}@ succeeded%{public}@",
                   operation, sanitizedURL, statusStr)
        } else {
            let errorStr = error?.localizedDescription ?? "Unknown error"
            os_log(.error, log: networkLog, "%{public}@ to %{public}@ failed%{public}@: %{public}@",
                   operation, sanitizedURL, statusStr, errorStr)
        }
    }

    // MARK: - Private Helpers

    /// Remove sensitive information from URLs
    private static func sanitizeURL(_ url: String) -> String {
        // Remove API keys and tokens from URL for logging
        var sanitized = url
        if let range = sanitized.range(of: "key=", options: .caseInsensitive) {
            let start = range.upperBound
            if let end = sanitized[start...].firstIndex(of: "&") {
                sanitized.replaceSubrange(start..<end, with: "[REDACTED]")
            } else {
                sanitized.replaceSubrange(start..., with: "[REDACTED]")
            }
        }
        return sanitized
    }
}

// MARK: - Data Operation Types

extension AppLogger {
    enum DataOperation: String {
        case fetch = "Fetch"
        case save = "Save"
        case delete = "Delete"
        case update = "Update"
    }
}
