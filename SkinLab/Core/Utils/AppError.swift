import Foundation

// MARK: - App Error

// Unified error types for SkinLab
// Provides user-friendly error messages and logging integration

enum AppError: LocalizedError {
    /// Failed to fetch data from SwiftData
    case dataFetch(entity: String, underlying: Error)

    /// Failed to save data to SwiftData
    case dataSave(entity: String, underlying: Error)

    /// Failed to delete data from SwiftData
    case dataDelete(entity: String, underlying: Error)

    /// Network request failed
    case networkRequest(operation: String, underlying: Error)

    /// Image processing failed
    case imageProcessing(operation: String, underlying: Error)

    /// JSON encoding failed
    case jsonEncode(type: String, underlying: Error)

    /// JSON decoding failed
    case jsonDecode(type: String, underlying: Error)

    /// File system operation failed
    case fileSystem(operation: String, underlying: Error)

    /// Notification scheduling failed
    case notification(operation: String, underlying: Error)

    /// Generic operation failure
    case operationFailed(operation: String, reason: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .dataFetch:
            "无法加载数据"
        case .dataSave:
            "保存失败"
        case .dataDelete:
            "删除失败"
        case .networkRequest:
            "网络请求失败"
        case .imageProcessing:
            "图片处理失败"
        case .jsonEncode:
            "数据编码失败"
        case .jsonDecode:
            "数据解析失败"
        case .fileSystem:
            "文件操作失败"
        case .notification:
            "通知设置失败"
        case let .operationFailed(_, reason):
            reason
        }
    }

    var failureReason: String? {
        switch self {
        case let .dataFetch(entity, error):
            "获取\(entity)时出错: \(error.localizedDescription)"
        case let .dataSave(entity, error):
            "保存\(entity)时出错: \(error.localizedDescription)"
        case let .dataDelete(entity, error):
            "删除\(entity)时出错: \(error.localizedDescription)"
        case let .networkRequest(operation, error):
            "\(operation)失败: \(error.localizedDescription)"
        case let .imageProcessing(operation, error):
            "\(operation)失败: \(error.localizedDescription)"
        case let .jsonEncode(type, error):
            "编码\(type)失败: \(error.localizedDescription)"
        case let .jsonDecode(type, error):
            "解析\(type)失败: \(error.localizedDescription)"
        case let .fileSystem(operation, error):
            "\(operation)失败: \(error.localizedDescription)"
        case let .notification(operation, error):
            "\(operation)失败: \(error.localizedDescription)"
        case let .operationFailed(operation, reason):
            "\(operation)失败: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .dataFetch:
            "请稍后重试，如问题持续请重启应用"
        case .dataSave:
            "请检查存储空间后重试"
        case .dataDelete:
            "请稍后重试"
        case .networkRequest:
            "请检查网络连接后重试"
        case .imageProcessing:
            "请尝试使用其他图片"
        case .jsonEncode, .jsonDecode:
            "请重启应用后重试"
        case .fileSystem:
            "请检查存储空间后重试"
        case .notification:
            "请检查通知权限设置"
        case .operationFailed:
            "请稍后重试"
        }
    }

    /// The underlying error for debugging
    var underlyingError: Error? {
        switch self {
        case let .dataFetch(_, error),
             let .dataSave(_, error),
             let .dataDelete(_, error),
             let .networkRequest(_, error),
             let .imageProcessing(_, error),
             let .jsonEncode(_, error),
             let .jsonDecode(_, error),
             let .fileSystem(_, error),
             let .notification(_, error):
            error
        case .operationFailed:
            nil
        }
    }

    // MARK: - Logging Integration

    /// Log this error using the AppLogger utility
    func log(file: String = #file, function: String = #function, line: Int = #line) {
        AppLogger.error(
            errorDescription ?? "Unknown error",
            error: underlyingError,
            file: file,
            function: function,
            line: line
        )
    }
}

// MARK: - Result Extension

extension Result where Failure == AppError {
    /// Log the error if this result is a failure
    @discardableResult
    func logIfFailure(file: String = #file, function: String = #function, line: Int = #line) -> Self {
        if case let .failure(error) = self {
            error.log(file: file, function: function, line: line)
        }
        return self
    }
}

// MARK: - Convenience Initializers

extension AppError {
    /// Create a data fetch error with automatic logging
    static func fetchFailed(
        _ type: (some Any).Type,
        error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> AppError {
        let appError = AppError.dataFetch(entity: String(describing: type), underlying: error)
        appError.log(file: file, function: function, line: line)
        return appError
    }

    /// Create a data save error with automatic logging
    static func saveFailed(
        _ type: (some Any).Type,
        error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> AppError {
        let appError = AppError.dataSave(entity: String(describing: type), underlying: error)
        appError.log(file: file, function: function, line: line)
        return appError
    }
}
