import SwiftUI
import Network

// MARK: - Error Category

/// Categorizes errors for appropriate user messaging and recovery options
enum ErrorCategory {
    case network
    case offline
    case serverError
    case rateLimited
    case invalidInput
    case unauthorized
    case unknown

    init(from error: Error) {
        // Check for GeminiError types
        if let geminiError = error as? GeminiError {
            switch geminiError {
            case .networkError:
                self = .network
            case .rateLimited:
                self = .rateLimited
            case .unauthorized:
                self = .unauthorized
            case .invalidImage:
                self = .invalidInput
            case .invalidAPIKey:
                self = .unauthorized
            case .apiError:
                self = .serverError
            case .parseError:
                self = .serverError
            }
            return
        }

        // Check for URLError types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                self = .offline
            case .timedOut, .cannotConnectToHost, .cannotFindHost:
                self = .network
            default:
                self = .network
            }
            return
        }

        // Check for AppError types
        if let appError = error as? AppError {
            switch appError {
            case .networkRequest:
                self = .network
            default:
                self = .unknown
            }
            return
        }

        // Default to unknown
        self = .unknown
    }

    /// User-friendly title for the error category
    var title: String {
        switch self {
        case .network:
            return "网络连接失败"
        case .offline:
            return "无网络连接"
        case .serverError:
            return "服务暂时不可用"
        case .rateLimited:
            return "请求过于频繁"
        case .invalidInput:
            return "输入无效"
        case .unauthorized:
            return "认证失败"
        case .unknown:
            return "出错了"
        }
    }

    /// User-friendly description
    var description: String {
        switch self {
        case .network:
            return "请检查网络连接后重试"
        case .offline:
            return "请连接网络后再试"
        case .serverError:
            return "服务器繁忙，请稍后重试"
        case .rateLimited:
            return "请等待片刻后再次尝试"
        case .invalidInput:
            return "请检查输入内容后重试"
        case .unauthorized:
            return "请检查网络设置或联系支持"
        case .unknown:
            return "请稍后重试"
        }
    }

    /// SF Symbol icon name for the error category
    var iconName: String {
        switch self {
        case .network:
            return "wifi.exclamationmark"
        case .offline:
            return "wifi.slash"
        case .serverError:
            return "server.rack"
        case .rateLimited:
            return "clock.badge.exclamationmark"
        case .invalidInput:
            return "doc.questionmark"
        case .unauthorized:
            return "lock.trianglebadge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }

    /// Icon color for the error category
    var iconColor: Color {
        switch self {
        case .network, .offline:
            return .skinLabWarning
        case .serverError, .rateLimited:
            return .orange
        case .invalidInput:
            return .skinLabSecondary
        case .unauthorized:
            return .skinLabError
        case .unknown:
            return .skinLabWarning
        }
    }

    /// Whether retry is likely to help
    var isRetryable: Bool {
        switch self {
        case .network, .offline, .serverError, .rateLimited:
            return true
        case .invalidInput, .unauthorized, .unknown:
            return false
        }
    }

    /// Suggested wait time before retry (in seconds)
    var suggestedRetryDelay: TimeInterval {
        switch self {
        case .rateLimited:
            return 30
        case .serverError:
            return 5
        case .network, .offline:
            return 2
        default:
            return 0
        }
    }
}

// MARK: - Error Recovery View

/// A unified error recovery component that provides consistent error handling UI
/// with retry capability, loading states, and user-friendly messaging.
struct ErrorRecoveryView: View {
    let error: Error
    let retryAction: () async -> Void
    let dismissAction: (() -> Void)?

    @State private var isRetrying = false
    @State private var retryCountdown: Int = 0
    @State private var countdownTimer: Timer?

    private let category: ErrorCategory

    /// Creates an error recovery view
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - retryAction: Async action to retry the failed operation
    ///   - dismissAction: Optional action to dismiss/cancel (shows secondary button if provided)
    init(
        error: Error,
        retryAction: @escaping () async -> Void,
        dismissAction: (() -> Void)? = nil
    ) {
        self.error = error
        self.retryAction = retryAction
        self.dismissAction = dismissAction
        self.category = ErrorCategory(from: error)
    }

    var body: some View {
        VStack(spacing: 28) {
            // Icon section
            iconSection

            // Text section
            textSection

            // Action buttons
            actionSection
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .onDisappear {
            countdownTimer?.invalidate()
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(category.iconColor.opacity(0.12))
                .frame(width: 120, height: 120)

            // Inner circle
            Circle()
                .fill(category.iconColor.opacity(0.2))
                .frame(width: 90, height: 90)

            // Icon
            if isRetrying {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: category.iconColor))
                    .scaleEffect(1.5)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: 44))
                    .foregroundColor(category.iconColor)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: 12) {
            Text(category.title)
                .font(.skinLabTitle2)
                .foregroundColor(.skinLabText)
                .multilineTextAlignment(.center)

            Text(category.description)
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Show detailed error for debugging in non-release builds
            #if DEBUG
            if !error.localizedDescription.isEmpty {
                Text(error.localizedDescription)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            #endif
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 14) {
            // Retry button
            Button(action: handleRetry) {
                HStack(spacing: 10) {
                    if isRetrying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    if retryCountdown > 0 {
                        Text("重试 (\(retryCountdown)s)")
                            .font(.skinLabHeadline)
                    } else {
                        Text("重试")
                            .font(.skinLabHeadline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient.skinLabPrimaryGradient
                        .opacity(isRetrying || retryCountdown > 0 ? 0.6 : 1.0)
                )
                .cornerRadius(28)
                .shadow(
                    color: .skinLabPrimary.opacity(isRetrying ? 0.1 : 0.35),
                    radius: isRetrying ? 6 : 12,
                    y: isRetrying ? 3 : 6
                )
            }
            .disabled(isRetrying || retryCountdown > 0)
            .accessibilityLabel(isRetrying ? "正在重试" : "重试")
            .accessibilityHint(category.description)

            // Dismiss button (if provided)
            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Text("返回")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Color.skinLabPrimary.opacity(0.1)
                        )
                        .cornerRadius(28)
                }
                .disabled(isRetrying)
                .accessibilityLabel("返回")
            }
        }
    }

    // MARK: - Actions

    private func handleRetry() {
        // Start countdown if rate limited
        if category == .rateLimited && retryCountdown == 0 {
            startCountdown(Int(category.suggestedRetryDelay))
            return
        }

        isRetrying = true

        Task {
            await retryAction()
            await MainActor.run {
                isRetrying = false
            }
        }
    }

    private func startCountdown(_ seconds: Int) {
        retryCountdown = seconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if retryCountdown > 0 {
                retryCountdown -= 1
            } else {
                timer.invalidate()
                handleRetry()
            }
        }
    }
}

// MARK: - Compact Error Recovery View

/// A more compact version of ErrorRecoveryView for inline error display
struct CompactErrorRecoveryView: View {
    let error: Error
    let retryAction: () async -> Void

    @State private var isRetrying = false

    private let category: ErrorCategory

    init(error: Error, retryAction: @escaping () async -> Void) {
        self.error = error
        self.retryAction = retryAction
        self.category = ErrorCategory(from: error)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                if isRetrying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: category.iconColor))
                } else {
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(category.iconColor)
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Text(category.description)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            Spacer()

            // Retry button
            Button(action: {
                isRetrying = true
                Task {
                    await retryAction()
                    await MainActor.run {
                        isRetrying = false
                    }
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient.skinLabPrimaryGradient
                    )
                    .clipShape(Circle())
            }
            .disabled(isRetrying)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(category.iconColor.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title). \(category.description)")
        .accessibilityHint("双击重试")
    }
}

// MARK: - Offline Banner View

/// A banner to show when the device is offline
struct OfflineBannerView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Text("当前无网络连接")
                .font(.skinLabSubheadline)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.skinLabWarning, Color.skinLabWarning.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .skinLabWarning.opacity(0.3), radius: 8, y: 4)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .accessibilityLabel("当前无网络连接")
    }
}

// MARK: - Network Monitor

/// A simple network monitor for checking connectivity status
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Preview

#Preview("Error Recovery - Network") {
    ErrorRecoveryView(
        error: URLError(.notConnectedToInternet),
        retryAction: {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        },
        dismissAction: {
            print("Dismissed")
        }
    )
}

#Preview("Error Recovery - Rate Limited") {
    ErrorRecoveryView(
        error: GeminiError.rateLimited,
        retryAction: {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    )
}

#Preview("Compact Error") {
    CompactErrorRecoveryView(
        error: GeminiError.networkError(URLError(.timedOut)),
        retryAction: {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    )
    .padding()
}

#Preview("Offline Banner") {
    VStack {
        OfflineBannerView()
            .padding()
        Spacer()
    }
}
