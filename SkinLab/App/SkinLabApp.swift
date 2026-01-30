import os.log
import SwiftData
import SwiftUI
#if canImport(FirebaseCore)
    import FirebaseCore
#endif

@main
struct SkinLabApp: App {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.skinlab",
        category: "AppStartup"
    )

    /// Initialization state for the app
    @State private var initializationState: InitializationState

    /// Scene phase for tracking app activation (DAU/WAU)
    @Environment(\.scenePhase) private var scenePhase

    /// The model container for SwiftData
    private let modelContainer: ModelContainer?

    /// Possible initialization states
    private enum InitializationState {
        case success
        case recoveryNeeded(Error) // Reset+retry failed, needs user intervention (may have in-memory fallback)
    }

    /// Explicit store URL for reliable data reset
    private static let storeURL: URL = {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        // Ensure the Application Support directory exists
        do {
            try FileManager.default.createDirectory(
                at: applicationSupportURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            logger.error("Failed to create Application Support directory: \(error.localizedDescription)")
        }

        return applicationSupportURL.appendingPathComponent("SkinLab.store")
    }()

    /// Attempts to delete store files for reset
    /// Returns true if files were deleted, false otherwise
    private static func deleteStoreFiles() -> Bool {
        let shmURL = storeURL.deletingPathExtension().appendingPathExtension("store-shm")
        let walURL = storeURL.deletingPathExtension().appendingPathExtension("store-wal")
        let fileManager = FileManager.default
        var deletedAny = false

        for url in [storeURL, shmURL, walURL] {
            if fileManager.fileExists(atPath: url.path) {
                do {
                    try fileManager.removeItem(at: url)
                    logger.info("Deleted store file: \(url.lastPathComponent)")
                    deletedAny = true
                } catch {
                    logger.error("Failed to delete \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
        return deletedAny
    }

    /// Configures Firebase and Analytics services
    private static func configureAnalytics() {
        #if canImport(FirebaseCore)
            // Configure Firebase first (required before using Firebase Analytics)
            FirebaseApp.configure()
            logger.info("Firebase configured successfully")
        #else
            logger.info("Firebase SDK not available - using debug analytics only")
        #endif

        // Configure the analytics service (will use Firebase if available, debug otherwise)
        AnalyticsService.shared.configure()

        // Log app launch event
        AnalyticsEvents.logEvent(name: "app_launched", parameters: [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        ])

        // Track first open for activation funnel
        FunnelTracker.shared.trackFirstOpen()

        // Track session start for DAU/WAU
        FunnelTracker.shared.trackSessionStart()
    }

    init() {
        // Configure Firebase and Analytics
        Self.configureAnalytics()

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

        // Helper to create persistent container
        func createPersistentContainer() throws -> ModelContainer {
            try ModelContainer(for: schema, configurations: [persistentConfig])
        }

        // Attempt primary initialization with explicit store URL
        do {
            let container = try createPersistentContainer()
            self.modelContainer = container
            self._initializationState = State(initialValue: .success)
            Self.logger.info("ModelContainer initialized successfully at \(Self.storeURL.path)")
        } catch let primaryError {
            Self.logger.error("Primary ModelContainer initialization failed: \(primaryError.localizedDescription)")

            // Step 2: Attempt reset + retry (per acceptance criteria #2)
            Self.logger.info("Attempting store reset and retry...")
            _ = Self.deleteStoreFiles() // Always attempt delete, even if no files found

            // Retry persistent initialization after reset attempt
            do {
                let resetContainer = try createPersistentContainer()
                self.modelContainer = resetContainer
                self._initializationState = State(initialValue: .success)
                Self.logger.info("ModelContainer recovered after store reset")
                return
            } catch let resetError {
                Self.logger.error("ModelContainer still failed after reset: \(resetError.localizedDescription)")
            }

            // Step 3: Per acceptance criteria #3 - show recovery UI when reset fails
            // We provide in-memory fallback WITH recovery UI (not just banner)
            let inMemoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            do {
                // Create in-memory container but show recovery UI for user intervention
                let recoveryContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                self.modelContainer = recoveryContainer
                // Show recovery UI since reset+retry failed (acceptance criteria #3)
                self._initializationState = State(initialValue: .recoveryNeeded(primaryError))
                Self.logger.warning("Reset+retry failed. Showing recovery UI with in-memory fallback.")
            } catch let recoveryError {
                // Complete failure - no container at all
                Self.logger
                    .critical(
                        "All recovery attempts failed: \(recoveryError.localizedDescription). Original error: \(primaryError.localizedDescription)"
                    )
                self.modelContainer = nil
                self._initializationState = State(initialValue: .recoveryNeeded(primaryError))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            contentView
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Track session start when app becomes active (including from background)
                        // This is deduplicated per-day in trackSessionStart()
                        FunnelTracker.shared.trackSessionStart()
                    }
                }
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

        case let .recoveryNeeded(error):
            // Reset+retry failed - show recovery UI (per acceptance criteria #3)
            // AppRecoveryView provides both "Reset Data" and "Contact Support" options
            AppRecoveryView(error: error, onResetData: resetAppData)
        }
    }

    /// State to show reset completion alert
    @State private var showResetCompleteAlert = false
    @State private var resetError: Error?

    /// Attempts to reset app data by deleting the SwiftData store
    private func resetAppData() {
        Self.logger.info("User-initiated reset at \(Self.storeURL.path)")

        // Reuse the consolidated delete logic
        let deleted = Self.deleteStoreFiles()

        if deleted {
            Self.logger.info("App data reset complete")
            resetError = nil
        } else {
            Self.logger.warning("No store files found to delete")
            // Still consider this a success - files may already be gone
            resetError = nil
        }

        showResetCompleteAlert = true
    }
}
