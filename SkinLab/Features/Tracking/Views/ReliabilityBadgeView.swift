import SwiftUI

// MARK: - Reliability Badge View

/// Displays the reliability score for a check-in with visual indicator
struct ReliabilityBadgeView: View {
    let reliability: ReliabilityMetadata
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: 12
            case .medium: 16
            case .large: 20
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: 10
            case .medium: 12
            case .large: 14
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            indicator
            label
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(color.opacity(0.15))
        .cornerRadius(cornerRadius)
    }

    private var indicator: some View {
        Circle()
            .fill(color)
            .frame(width: size.iconSize, height: size.iconSize)
    }

    private var label: some View {
        Text(labelText)
            .font(.system(size: size.fontSize, weight: .medium))
            .foregroundColor(color)
    }

    private var color: Color {
        switch reliability.level {
        case .high: .green
        case .medium: .orange
        case .low: .red
        }
    }

    private var labelText: String {
        let score = Int(reliability.score * 100)
        return "\(score)%"
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: 6
        case .medium: 8
        case .large: 10
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: 3
        case .medium: 4
        case .large: 5
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: 4
        case .medium: 6
        case .large: 8
        }
    }
}

// MARK: - Reliability Reasons View

/// Displays the reasons for low reliability in a card
struct ReliabilityReasonsView: View {
    let reliability: ReliabilityMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("数据可靠性因素")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)
            }

            ForEach(reliability.reasonDescriptions(), id: \.reason) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(reasonColor(item.reason))
                        .frame(width: 6, height: 6)

                    Text(item.description)
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func reasonColor(_ reason: ReliabilityMetadata.ReliabilityReason) -> Color {
        switch reason {
        case .lowLight, .highLight, .angleOff, .distanceOff, .centeringOff,
             .blurry, .noFaceDetected, .missingLiveConditions, .longInterval,
             .userFlaggedIssue, .lowAnalysisConfidence, .inconsistentCameraPosition:
            .orange
        }
    }
}

// MARK: - Timeline Mode Toggle

/// Toggle between all data and reliable data
struct TimelineModeToggle: View {
    @Binding var mode: TimelineDisplayPolicy.TimelineMode
    let policy: TimelineDisplayPolicy

    var body: some View {
        Picker("", selection: $mode) {
            Text("全部数据").tag(TimelineDisplayPolicy.TimelineMode.all)
            Text("可靠数据").tag(TimelineDisplayPolicy.TimelineMode.reliable)
        }
        .pickerStyle(SegmentedPickerStyle())
        .overlay(
            reliabilityIndicator,
            alignment: .trailing
        )
    }

    @ViewBuilder
    private var reliabilityIndicator: some View {
        if policy.excludedCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)

                Text("\(policy.excludedCount)个数据点已过滤")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            .padding(.trailing, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // High reliability
        ReliabilityBadgeView(
            reliability: ReliabilityMetadata(
                score: 0.85,
                level: .high,
                reasons: []
            ),
            size: .medium
        )

        // Medium reliability
        ReliabilityBadgeView(
            reliability: ReliabilityMetadata(
                score: 0.55,
                level: .medium,
                reasons: [.lowLight, .angleOff]
            ),
            size: .medium
        )

        // Low reliability
        ReliabilityBadgeView(
            reliability: ReliabilityMetadata(
                score: 0.30,
                level: .low,
                reasons: [.noFaceDetected, .missingLiveConditions]
            ),
            size: .medium
        )

        // Reasons view
        ReliabilityReasonsView(
            reliability: ReliabilityMetadata(
                score: 0.40,
                level: .medium,
                reasons: [.lowLight, .angleOff, .distanceOff]
            )
        )
    }
    .padding()
}
