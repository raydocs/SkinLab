import Foundation

// MARK: - App Error
/// Unified error types for SkinLab
/// Provides user-friendly error messages and logging integration

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
            return "无法加载数据"
        case .dataSave:
            return "保存失败"
        case .dataDelete:
            return "删除失败"
        case .networkRequest:
            return "网络请求失败"
        case .imageProcessing:
            return "图片处理失败"
        case .jsonEncode:
            return "数据编码失败"
        case .jsonDecode:
            return "数据解析失败"
        case .fileSystem:
            return "文件操作失败"
        case .notification:
            return "通知设置失败"
        case .operationFailed(_, let reason):
            return reason
        }
    }

    var failureReason: String? {
        switch self {
        case .dataFetch(let entity, let error):
            return "获取\(entity)时出错: \(error.localizedDescription)"
        case .dataSave(let entity, let error):
            return "保存\(entity)时出错: \(error.localizedDescription)"
        case .dataDelete(let entity, let error):
            return "删除\(entity)时出错: \(error.localizedDescription)"
        case .networkRequest(let operation, let error):
            return "\(operation)失败: \(error.localizedDescription)"
        case .imageProcessing(let operation, let error):
            return "\(operation)失败: \(error.localizedDescription)"
        case .jsonEncode(let type, let error):
            return "编码\(type)失败: \(error.localizedDescription)"
        case .jsonDecode(let type, let error):
            return "解析\(type)失败: \(error.localizedDescription)"
        case .fileSystem(let operation, let error):
            return "\(operation)失败: \(error.localizedDescription)"
        case .notification(let operation, let error):
            return "\(operation)失败: \(error.localizedDescription)"
        case .operationFailed(let operation, let reason):
            return "\(operation)失败: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .dataFetch:
            return "请稍后重试，如问题持续请重启应用"
        case .dataSave:
            return "请检查存储空间后重试"
        case .dataDelete:
            return "请稍后重试"
        case .networkRequest:
            return "请检查网络连接后重试"
        case .imageProcessing:
            return "请尝试使用其他图片"
        case .jsonEncode, .jsonDecode:
            return "请重启应用后重试"
        case .fileSystem:
            return "请检查存储空间后重试"
        case .notification:
            return "请检查通知权限设置"
        case .operationFailed:
            return "请稍后重试"
        }
    }

    /// The underlying error for debugging
    var underlyingError: Error? {
        switch self {
        case .dataFetch(_, let error),
             .dataSave(_, let error),
             .dataDelete(_, let error),
             .networkRequest(_, let error),
             .imageProcessing(_, let error),
             .jsonEncode(_, let error),
             .jsonDecode(_, let error),
             .fileSystem(_, let error),
             .notification(_, let error):
            return error
        case .operationFailed:
            return nil
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
        if case .failure(let error) = self {
            error.log(file: file, function: function, line: line)
        }
        return self
    }
}

// MARK: - Convenience Initializers

extension AppError {
    /// Create a data fetch error with automatic logging
    static func fetchFailed<T>(
        _ type: T.Type,
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
    static func saveFailed<T>(
        _ type: T.Type,
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
