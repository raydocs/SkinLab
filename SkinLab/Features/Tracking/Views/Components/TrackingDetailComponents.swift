import SwiftUI

// MARK: - Check-In Row
struct CheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text("Day")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                Text("\(checkIn.day)")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabPrimary)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.captureDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)

                if let feeling = checkIn.feeling {
                    HStack(spacing: 4) {
                        Image(systemName: feeling.icon)
                            .font(.caption)
                        Text(feeling.displayName)
                            .font(.skinLabCaption)
                    }
                    .foregroundColor(feelingColor(feeling))
                }
            }

            Spacer()

            // Reliability badge (persistent location in timeline list)
            if let reliability = checkIn.reliability {
                ReliabilityBadgeView(reliability: reliability, size: .small)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.skinLabSubtext)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func feelingColor(_ feeling: CheckIn.Feeling) -> Color {
        switch feeling {
        case .better: return .skinLabSuccess
        case .same: return .skinLabSubtext
        case .worse: return .skinLabWarning
        }
    }
}

// MARK: - Feeling Button
struct FeelingButton: View {
    let feeling: CheckIn.Feeling
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: feeling.icon)
                    .font(.title2)

                Text(feeling.displayName)
                    .font(.skinLabCaption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.skinLabPrimary.opacity(0.1) : Color.gray.opacity(0.05))
            .foregroundColor(isSelected ? .skinLabPrimary : .skinLabText)
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.skinLabPrimary : Color.clear, lineWidth: 2)
            }
        }
    }
}

// MARK: - Lifestyle Draft
/// Draft struct for lifestyle data collection with all optional fields
struct LifestyleDraft {
    var sleepHours: Double?
    var stressLevel: Int?
    var waterIntakeLevel: Int?
    var alcoholConsumed: Bool?
    var exerciseMinutes: Int?
    var sunExposureLevel: Int?
    var dietNotes: String?

    var hasAnyData: Bool {
        sleepHours != nil ||
        stressLevel != nil ||
        waterIntakeLevel != nil ||
        alcoholConsumed != nil ||
        exerciseMinutes != nil ||
        sunExposureLevel != nil ||
        (dietNotes != nil && !dietNotes!.isEmpty)
    }

    var summary: String {
        var parts: [String] = []
        if let sleep = sleepHours {
            parts.append("睡眠\(Int(sleep))h")
        }
        if let stress = stressLevel {
            parts.append("压力\(stress)")
        }
        if let sun = sunExposureLevel {
            parts.append("日晒\(sun)")
        }
        return parts.isEmpty ? "未记录" : parts.joined(separator: " · ")
    }
}
