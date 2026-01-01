import SwiftUI

struct RoutineView: View {
    let routine: SkincareRoutine
    @State private var selectedPhase: RoutinePhase = .am
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Phase Selector
                phaseSelector
                
                // Steps
                stepsSection
                
                // Notes
                if !routine.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .background(Color.skinLabBackground)
        .navigationTitle("护肤方案")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Duration
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.freshPrimary)
                Text("\(routine.weeksDuration) 周计划")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            
            // Goals
            if !routine.goals.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(routine.goals, id: \.self) { goal in
                        Text(goal.displayName)
                            .font(.skinLabCaption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.freshPrimary.opacity(0.15))
                            .foregroundColor(.freshPrimary)
                            .cornerRadius(12)
                    }
                }
            }
            
            // Skin Type
            if let skinType = routine.skinType {
                Text("适合 \(skinType.displayName)")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
            }
        }
        .padding()
        .freshGlassCard()
    }
    
    private var phaseSelector: some View {
        HStack(spacing: 12) {
            ForEach(RoutinePhase.allCases, id: \.self) { phase in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPhase = phase
                    }
                } label: {
                    HStack {
                        Image(systemName: phase == .am ? "sun.max.fill" : "moon.stars.fill")
                        Text(phase.displayName)
                            .font(.skinLabHeadline)
                    }
                    .foregroundColor(selectedPhase == phase ? .white : .skinLabText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        selectedPhase == phase ? 
                            AnyView(Color.freshPrimary) :
                            AnyView(Color.freshWhite.opacity(0.4))
                    )
                    .cornerRadius(16)
                }
            }
        }
    }
    
    private var stepsSection: some View {
        VStack(spacing: 12) {
            let steps = selectedPhase == .am ? routine.amSteps : routine.pmSteps
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                RoutineStepCard(step: step, stepNumber: index + 1)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(LinearGradient.skinLabAccentGradient)
                Text("重要提示")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            
            ForEach(routine.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.skinLabAccent)
                    Text(note)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .padding()
        .background(Color.skinLabAccent.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Routine Step Card
struct RoutineStepCard: View {
    let step: RoutineStep
    let stepNumber: Int
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    // Step Number
                    ZStack {
                        Circle()
                            .fill(Color.freshPrimary)
                            .frame(width: 32, height: 32)
                        Text("\(stepNumber)")
                            .font(.skinLabCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                        Text(step.productType)
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    Spacer()
                    
                    // Frequency Badge
                    Text(step.frequency)
                        .font(.skinLabCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.freshSecondary.opacity(0.2))
                        .foregroundColor(.freshSecondary)
                        .cornerRadius(8)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.skinLabSubtext)
                }
            }
            
            // Expanded Content
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Instructions
                    DetailRow(icon: "hand.point.up.left.fill", title: "使用方法", content: step.instructions)
                    
                    // Precautions
                    if !step.precautions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("注意事项", systemImage: "exclamationmark.triangle.fill")
                                .font(.skinLabCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(.skinLabWarning)
                            ForEach(step.precautions, id: \.self) { precaution in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(precaution)
                                        .font(.skinLabSubheadline)
                                        .foregroundColor(.skinLabText)
                                }
                            }
                        }
                    }
                    
                    // Alternatives
                    if !step.alternatives.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("替代方案", systemImage: "arrow.triangle.2.circlepath")
                                .font(.skinLabCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(.freshSecondary)
                            ForEach(step.alternatives, id: \.self) { alternative in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(alternative)
                                        .font(.skinLabSubheadline)
                                        .foregroundColor(.skinLabText)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .freshGlassCard()
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.skinLabCaption)
                .fontWeight(.semibold)
                .foregroundColor(.freshPrimary)
            Text(content)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RoutineView(routine: SkincareRoutine(
            skinType: .combination,
            concerns: [.acne, .pores],
            goals: [.acne, .pores],
            steps: [
                RoutineStep(phase: .am, order: 1, title: "清洁", productType: "洗面奶", instructions: "温水打湿面部，取适量洗面奶打圈按摩1-2分钟，用清水洗净", frequency: "每天", precautions: ["避免用力过度"], alternatives: ["敏感肌可选氨基酸洗面奶"]),
                RoutineStep(phase: .am, order: 2, title: "保湿", productType: "面霜", instructions: "取适量均匀涂抹全脸", frequency: "每天"),
                RoutineStep(phase: .pm, order: 1, title: "卸妆", productType: "卸妆油", instructions: "干手干脸，取适量卸妆油按摩全脸", frequency: "每天")
            ],
            notes: ["坚持使用4周可见效", "如有不适请停用"],
            weeksDuration: 4
        ))
    }
}
