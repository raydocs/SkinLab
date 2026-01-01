import SwiftUI
import SwiftData

/// ViewModel for AnalysisResultView
/// Handles routine generation and tracking report retrieval
@MainActor
class AnalysisResultViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isGeneratingRoutine = false
    @Published var generatedRoutine: SkincareRoutine?
    @Published var showRoutine = false
    @Published var routineError: String?
    @Published var showRoutineError = false

    // MARK: - Dependencies
    private let routineService: RoutineService
    private let modelContext: ModelContext

    // MARK: - Initialization
    init(
        routineService: RoutineService = RoutineService(),
        modelContext: ModelContext
    ) {
        self.routineService = routineService
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Generate skincare routine based on analysis
    func generateRoutine(
        analysis: SkinAnalysis,
        userProfile: UserProfile?,
        trackingSessions: [TrackingSession],
        negativeIngredients: [String]
    ) async {
        isGeneratingRoutine = true
        routineError = nil
        showRoutineError = false

        do {
            // Get recent tracking report if available
            let trackingReport = await getRecentTrackingReport(
                from: trackingSessions
            )

            // Generate routine
            let routine = try await routineService.generateRoutine(
                analysis: analysis,
                profile: userProfile,
                trackingReport: trackingReport,
                negativeIngredients: negativeIngredients
            )

            // Save to SwiftData
            let record = SkincareRoutineRecord(from: routine)
            modelContext.insert(record)
            try modelContext.save()

            // Update UI state
            generatedRoutine = routine
            showRoutine = true
            isGeneratingRoutine = false
        } catch {
            routineError = error.localizedDescription
            showRoutineError = true
            isGeneratingRoutine = false
        }
    }

    // MARK: - Private Methods

    /// Fetch recent tracking report for routine optimization
    private func getRecentTrackingReport(
        from sessions: [TrackingSession]
    ) async -> EnhancedTrackingReport? {
        // Find most recent completed tracking session
        guard let recentSession = sessions
            .filter({ $0.status == .completed && $0.checkIns.count >= 2 })
            .sorted(by: { $0.startDate > $1.startDate })
            .first else {
            return nil
        }

        // Collect analyses for the check-ins
        var analyses: [UUID: SkinAnalysis] = [:]
        for checkIn in recentSession.checkIns {
            if let analysisId = checkIn.analysisId {
                // Fetch analysis from SwiftData
                let predicate = #Predicate<SkinAnalysisRecord> {
                    $0.id == analysisId
                }
                let descriptor = FetchDescriptor<SkinAnalysisRecord>(
                    predicate: predicate
                )

                if let record = try? modelContext.fetch(descriptor).first,
                   let skinAnalysis = record.toAnalysis() {
                    analyses[analysisId] = skinAnalysis
                }
            }
        }

        guard !analyses.isEmpty else { return nil }

        // Generate report using TrackingReportGenerator
        let generator = TrackingReportGenerator(
            geminiService: GeminiService.shared
        )
        return await generator.generateReport(
            session: recentSession,
            checkIns: recentSession.checkIns,
            analyses: analyses,
            productDatabase: [:]  // Could be enhanced with actual product database
        )
    }
}
