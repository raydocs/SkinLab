import SwiftUI

struct EvidenceBadgeView: View {
    let level: EvidenceLevel
    var isCompact: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: level.icon)
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                Text(level.displayName)
                    .font(isCompact ? .skinLabCaption : .skinLabSubheadline)
            }
            .foregroundColor(color)
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.vertical, isCompact ? 4 : 6)
            .background(color.opacity(0.15))
            .cornerRadius(isCompact ? 8 : 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("证据等级：\(level.displayName)")
    }

    private var color: Color {
        switch level {
        case .limited: .gray
        case .moderate: .orange
        case .strong: .skinLabSuccess
        }
    }
}

struct EvidenceSourcesSheet: View {
    let entry: EvidenceEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let description = entry.description {
                    Text(description)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }

                sourcesSection
                studyCountSection

                Spacer()
            }
            .padding()
            .navigationTitle("证据来源")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.ingredientName)
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            EvidenceBadgeView(level: entry.level, isCompact: true)
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("来源")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)

            ForEach(entry.sources, id: \.self) { source in
                HStack(spacing: 8) {
                    Image(systemName: source.icon)
                        .font(.caption)
                        .foregroundColor(.skinLabPrimary)
                    Text(source.displayName)
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabText)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(12)
    }

    @ViewBuilder
    private var studyCountSection: some View {
        if let count = entry.studyCount {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.skinLabSecondary)
                Text("\(count)项相关研究")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)
                Spacer()
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        EvidenceBadgeView(level: .limited)
        EvidenceBadgeView(level: .moderate)
        EvidenceBadgeView(level: .strong)
    }
    .padding()
}
