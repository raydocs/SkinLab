import SwiftUI
import SwiftData

/// ViewModel for TrackingDetailView
/// Handles tracking report generation
@MainActor
class TrackingDetailViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isGeneratingReport = false
    @Published var generatedReport: EnhancedTrackingReport?
    @Published var showReport = false
    @Published var reportError: String?

    // MARK: - Dependencies
    private let modelContext: ModelContext

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Generate enhanced tracking report for a session
    func generateReport(for session: TrackingSession) async {
        isGeneratingReport = true
        reportError = nil

        do {
            // Collect analysis IDs from current session's checkIns
            let analysisIds = session.checkIns.compactMap { $0.analysisId }

            guard analysisIds.count >= 2 else {
                reportError = "需要至少2次打卡记录才能生成报告"
                isGeneratingReport = false
                return
            }

            // Query only relevant analysis records for this session
            let predicate = #Predicate<SkinAnalysisRecord> { record in
                analysisIds.contains(record.id)
            }
            let descriptor = FetchDescriptor<SkinAnalysisRecord>(predicate: predicate)
            let relevantRecords = try modelContext.fetch(descriptor)

            // Convert to SkinAnalysis dictionary
            var analysisDict: [UUID: SkinAnalysis] = [:]
            for record in relevantRecords {
                if let analysis = record.toAnalysis() {
                    analysisDict[record.id] = analysis
                }
            }

            // Generate report
            let generator = TrackingReportGenerator()
            if let report = await generator.generateReport(
                session: session,
                checkIns: session.checkIns,
                analyses: analysisDict
            ) {
                generatedReport = report
                showReport = true
                isGeneratingReport = false
            } else {
                reportError = "生成报告失败"
                isGeneratingReport = false
            }
        } catch {
            reportError = error.localizedDescription
            isGeneratingReport = false
        }
    }

    /// Complete the tracking session
    func completeSession(_ session: TrackingSession) {
        session.status = .completed
        session.endDate = Date()
    }
}
