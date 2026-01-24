import SwiftUI
import SwiftData
import os.log

@main
struct SkinLabApp: App {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.skinlab",
        category: "AppStartup"
    )

    /// Initialization state for the app
    @State private var initializationState: InitializationState

    /// The model container for SwiftData
    private let modelContainer: ModelContainer?

    /// Possible initialization states
    private enum InitializationState {
        case success
        case inMemoryMode(Error)  // Running with in-memory storage due to error
        case recoveryNeeded(Error)  // Complete failure, needs user intervention
    }

    /// Explicit store URL for reliable data reset
    private static let storeURL: URL = {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupportURL.appendingPathComponent("SkinLab.store")
    }()

    init() {
        let schema = Schema([
            UserProfile.self,
            SkinAnalysisRecord.self,
            TrackingSession.self,
            ProductRecord.self,
            SkincareRoutineRecord.self,
            IngredientExposureRecord.self,
            UserIngredientPreference.self,

            // Community 模块
            MatchResultRecord.self,
            UserFeedbackRecord.self,

            // Engagement 模块
            UserEngagementMetrics.self,
            AchievementProgress.self
        ])

        // Use explicit store URL for reliable data management
        let persistentConfig = ModelConfiguration(
            schema: schema,
            url: Self.storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        // Attempt primary initialization with explicit store URL
        do {
            let container = try ModelContainer(for: schema, configurations: [persistentConfig])
            self.modelContainer = container
            self._initializationState = State(initialValue: .success)
            Self.logger.info("ModelContainer initialized successfully at \(Self.storeURL.path)")
        } catch let primaryError {
            Self.logger.error("Primary ModelContainer initialization failed: \(primaryError.localizedDescription)")

            // Attempt recovery with in-memory configuration
            let inMemoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            do {
                let recoveryContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                self.modelContainer = recoveryContainer
                self._initializationState = State(initialValue: .inMemoryMode(primaryError))
                Self.logger.warning("ModelContainer recovered with in-memory storage. Original error: \(primaryError.localizedDescription)")
            } catch let recoveryError {
                // Complete failure - will show recovery UI
                Self.logger.critical("ModelContainer recovery also failed: \(recoveryError.localizedDescription). Original error: \(primaryError.localizedDescription)")
                self.modelContainer = nil
                self._initializationState = State(initialValue: .recoveryNeeded(primaryError))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            contentView
                .alert(
                    resetError == nil ? "重置完成" : "重置失败",
                    isPresented: $showResetCompleteAlert
                ) {
                    Button("确定") {
                        // User acknowledges - they need to restart manually
                    }
                } message: {
                    if let error = resetError {
                        Text("无法重置数据: \(error.localizedDescription)")
                    } else {
                        Text("数据已清除。请关闭并重新打开应用以完成重置。")
                    }
                }
        }
    }

    /// Whether to show the recovery mode banner
    @State private var showRecoveryBanner = false

    @ViewBuilder
    private var contentView: some View {
        switch initializationState {
        case .success:
            if let container = modelContainer {
                ContentView()
                    .modelContainer(container)
            } else {
                // This should not happen, but handle gracefully
                AppRecoveryView(error: nil, onResetData: resetAppData)
            }

        case .inMemoryMode(let error):
            if let container = modelContainer {
                // Running in-memory mode - show content with persistent warning banner
                ContentView()
                    .modelContainer(container)
                    .safeAreaInset(edge: .top) {
                        if showRecoveryBanner {
                            recoveryBanner(error: error)
                        }
                    }
                    .onAppear {
                        showRecoveryBanner = true
                        Self.logger.warning("App running in recovery mode with in-memory storage")
                    }
            } else {
                AppRecoveryView(error: error, onResetData: resetAppData)
            }

        case .recoveryNeeded(let error):
            // Complete failure - show recovery UI
            AppRecoveryView(error: error, onResetData: resetAppData)
        }
    }

    @ViewBuilder
    private func recoveryBanner(error: Error) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("数据未保存")
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showRecoveryBanner = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            Text("应用正在临时模式下运行。您的更改不会被保存。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("重置数据以修复") {
                resetAppData()
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    /// State to show reset completion alert
    @State private var showResetCompleteAlert = false
    @State private var resetError: Error?

    /// Attempts to reset app data by deleting the SwiftData store
    private func resetAppData() {
        Self.logger.info("Attempting to reset app data at \(Self.storeURL.path)")

        // Use the explicit store URL we configured
        let shmURL = Self.storeURL.deletingPathExtension().appendingPathExtension("store-shm")
        let walURL = Self.storeURL.deletingPathExtension().appendingPathExtension("store-wal")

        do {
            let fileManager = FileManager.default

            // Remove store files if they exist
            for url in [Self.storeURL, shmURL, walURL] {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                    Self.logger.info("Removed: \(url.lastPathComponent)")
                }
            }

            Self.logger.info("App data reset complete")

            // Show completion alert prompting user to restart
            resetError = nil
            showResetCompleteAlert = true
        } catch {
            Self.logger.error("Failed to reset app data: \(error.localizedDescription)")
            resetError = error
            showResetCompleteAlert = true
        }
    }
}
