import SwiftUI

/// A card showing photo quality score and AI confidence score with improvement suggestions
struct ConfidenceScoreCardView: View {
    let photoQualityReport: PhotoQualityReport?
    let aiConfidenceScore: Int
    let onRetake: () -> Void

    private var photoQualityScore: Int {
        photoQualityReport?.overallScore ?? 0
    }

    private var shouldShow: Bool {
        aiConfidenceScore < 80 || photoQualityScore < 80 || !(photoQualityReport?.issues.isEmpty ?? true)
    }

    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 16) {
                scoresSection
                issuesSection
                retakeButton
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
            .skinLabSoftShadow()
        }
    }

    // MARK: - Scores Section

    private var scoresSection: some View {
        HStack(spacing: 20) {
            scoreItem(
                title: "照片质量",
                score: photoQualityScore,
                icon: "camera.fill",
                level: photoQualityReport?.qualityLevel ?? .poor
            )

            Divider()
                .frame(height: 50)

            scoreItem(
                title: "分析可信度",
                score: aiConfidenceScore,
                icon: "brain.head.profile",
                level: confidenceLevel
            )
        }
    }

    private func scoreItem(title: String, score: Int, icon: String, level: QualityLevel) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(level.swiftUIColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(level.swiftUIColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                HStack(spacing: 4) {
                    Text("\(score)%")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)

                    Text(level.displayName)
                        .font(.skinLabCaption)
                        .foregroundColor(level.swiftUIColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(level.swiftUIColor.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(score)%，\(level.displayName)")
    }

    private var confidenceLevel: QualityLevel {
        switch aiConfidenceScore {
        case 80...: .excellent
        case 60 ..< 80: .good
        case 40 ..< 60: .fair
        default: .poor
        }
    }

    // MARK: - Issues Section

    @ViewBuilder
    private var issuesSection: some View {
        if let report = photoQualityReport, !report.issues.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                    .background(Color.skinLabSubtext.opacity(0.2))

                Text("可改进点")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                ForEach(report.issues.prefix(3), id: \.self) { issue in
                    issueRow(issue: issue)
                }
            }
        }
    }

    private func issueRow(issue: QualityIssue) -> some View {
        HStack(spacing: 10) {
            Image(systemName: issue.icon)
                .font(.system(size: 12))
                .foregroundColor(issue.severity.swiftUIColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.displayName)
                    .font(.skinLabCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.skinLabText)

                Text(issue.suggestion)
                    .font(.system(size: 11))
                    .foregroundColor(.skinLabSubtext)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(issue.displayName)：\(issue.suggestion)")
    }

    // MARK: - Retake Button

    @ViewBuilder
    private var retakeButton: some View {
        let shouldShowRetake = photoQualityScore < 60 || aiConfidenceScore < 60
        if shouldShowRetake {
            Button {
                onRetake()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("重新拍照获取更准确的分析")
                }
                .font(.skinLabSubheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(LinearGradient.skinLabPrimaryGradient)
                .cornerRadius(12)
            }
            .accessibilityLabel("重新拍照")
            .accessibilityHint("拍摄更清晰的照片以获得更准确的皮肤分析")
        }
    }
}

// MARK: - QualityLevel SwiftUI Extension

extension QualityLevel {
    var swiftUIColor: Color {
        switch self {
        case .excellent: .skinLabSuccess
        case .good: .skinLabInfo
        case .fair: .skinLabWarning
        case .poor: .skinLabError
        }
    }
}

// MARK: - IssueSeverity SwiftUI Extension

extension IssueSeverity {
    var swiftUIColor: Color {
        switch self {
        case .critical: .skinLabError
        case .warning: .skinLabWarning
        case .minor: .skinLabSubtext
        }
    }
}

// MARK: - Preview

#Preview("Low Quality") {
    ConfidenceScoreCardView(
        photoQualityReport: PhotoQualityReport(
            overallScore: 45,
            blurScore: 30,
            brightnessScore: 50,
            faceDetectionScore: 55,
            issues: [.tooBlurry, .tooDark, .faceNotCentered]
        ),
        aiConfidenceScore: 55,
        onRetake: {}
    )
    .padding()
}

#Preview("Good Quality") {
    ConfidenceScoreCardView(
        photoQualityReport: PhotoQualityReport(
            overallScore: 85,
            blurScore: 90,
            brightnessScore: 80,
            faceDetectionScore: 85,
            issues: []
        ),
        aiConfidenceScore: 90,
        onRetake: {}
    )
    .padding()
}

#Preview("Medium Quality") {
    ConfidenceScoreCardView(
        photoQualityReport: PhotoQualityReport(
            overallScore: 65,
            blurScore: 60,
            brightnessScore: 70,
            faceDetectionScore: 65,
            issues: [.slightlyBlurry]
        ),
        aiConfidenceScore: 72,
        onRetake: {}
    )
    .padding()
}
