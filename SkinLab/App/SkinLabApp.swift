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
        case recoveryNeeded(Error)
    }

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

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        // Attempt primary initialization
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContainer = container
            self._initializationState = State(initialValue: .success)
            Self.logger.info("ModelContainer initialized successfully")
        } catch {
            Self.logger.error("Primary ModelContainer initialization failed: \(error.localizedDescription)")

            // Attempt recovery with in-memory configuration
            let inMemoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            do {
                let recoveryContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                self.modelContainer = recoveryContainer
                self._initializationState = State(initialValue: .recoveryNeeded(error))
                Self.logger.warning("ModelContainer recovered with in-memory storage")
            } catch {
                // Complete failure - will show recovery UI
                Self.logger.critical("ModelContainer recovery failed: \(error.localizedDescription)")
                self.modelContainer = nil
                self._initializationState = State(initialValue: .recoveryNeeded(error))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            contentView
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

        case .recoveryNeeded(let error):
            if let container = modelContainer {
                // We have a recovery container (in-memory), show content with warning
                ContentView()
                    .modelContainer(container)
                    .onAppear {
                        Self.logger.warning("App running in recovery mode with in-memory storage")
                    }
            } else {
                // Complete failure - show recovery UI
                AppRecoveryView(error: error, onResetData: resetAppData)
            }
        }
    }

    /// Attempts to reset app data by deleting the SwiftData store
    private func resetAppData() {
        Self.logger.info("Attempting to reset app data")

        // Get the default SwiftData store URL
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            Self.logger.error("Could not find Application Support directory")
            return
        }

        let storeURL = applicationSupportURL.appendingPathComponent("default.store")
        let shmURL = applicationSupportURL.appendingPathComponent("default.store-shm")
        let walURL = applicationSupportURL.appendingPathComponent("default.store-wal")

        do {
            let fileManager = FileManager.default

            // Remove store files if they exist
            for url in [storeURL, shmURL, walURL] {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                    Self.logger.info("Removed: \(url.lastPathComponent)")
                }
            }

            Self.logger.info("App data reset complete. Please restart the app.")

            // Request app termination so user can restart fresh
            // Note: In production, you might want to handle this differently
            exit(0)
        } catch {
            Self.logger.error("Failed to reset app data: \(error.localizedDescription)")
        }
    }
}
