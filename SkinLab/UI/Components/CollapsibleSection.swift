import SwiftUI

// MARK: - Collapsible Section Manager

/// Manages the expanded state of collapsible sections with persistence
@MainActor
final class CollapsibleSectionManager: ObservableObject {
    @AppStorage("report.expandedSections")
    private var expandedSectionsData: Data = Data()

    /// Default sections that should be expanded on first load
    /// Uses actual section IDs from TrackingReportView
    static let defaultExpandedSections: Set<String> = ["dimensionChanges", "recommendations"]

    /// Currently expanded section IDs (drives UI updates via @Published)
    @Published var expandedSections: Set<String> = []

    init(defaultExpandedSections: Set<String>? = nil) {
        // Load from storage or use defaults
        let defaults = defaultExpandedSections ?? CollapsibleSectionManager.defaultExpandedSections
        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: expandedSectionsData) {
            self.expandedSections = decoded
        } else {
            self.expandedSections = defaults
            persist()
        }
    }

    /// Check if a section is expanded
    func isExpanded(_ sectionId: String) -> Bool {
        expandedSections.contains(sectionId)
    }

    /// Toggle a section's expanded state
    func toggle(_ sectionId: String) {
        if expandedSections.contains(sectionId) {
            expandedSections.remove(sectionId)
        } else {
            expandedSections.insert(sectionId)
        }
        persist()
    }

    /// Set a section's expanded state
    func setExpanded(_ sectionId: String, _ expanded: Bool) {
        if expanded {
            expandedSections.insert(sectionId)
        } else {
            expandedSections.remove(sectionId)
        }
        persist()
    }

    /// Expand all sections
    func expandAll(_ sectionIds: [String]) {
        expandedSections.formUnion(sectionIds)
        persist()
    }

    /// Collapse all sections
    func collapseAll() {
        expandedSections.removeAll()
        persist()
    }

    /// Check if all sections are expanded
    func allExpanded(_ sectionIds: [String]) -> Bool {
        sectionIds.allSatisfy { expandedSections.contains($0) }
    }

    /// Reset to default expanded sections
    func resetToDefaults() {
        expandedSections = Self.defaultExpandedSections
        persist()
    }

    /// Persist current state to @AppStorage
    private func persist() {
        expandedSectionsData = (try? JSONEncoder().encode(expandedSections)) ?? Data()
    }
}

// MARK: - Collapsible Section View

/// A reusable collapsible section with smooth animation and accessibility support
struct CollapsibleSection<Content: View>: View {
    let sectionId: String
    let title: String
    let systemImage: String
    let badge: String?
    @ObservedObject var manager: CollapsibleSectionManager
    @ViewBuilder let content: () -> Content

    init(
        sectionId: String,
        title: String,
        systemImage: String,
        badge: String? = nil,
        manager: CollapsibleSectionManager,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.sectionId = sectionId
        self.title = title
        self.systemImage = systemImage
        self.badge = badge
        self.manager = manager
        self.content = content
    }

    private var isExpanded: Bool {
        manager.isExpanded(sectionId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    manager.toggle(sectionId)
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                        .frame(width: 24)

                    // Title
                    Text(title)
                        .font(.skinLabTitle3)
                        .foregroundColor(.skinLabText)

                    // Badge (optional)
                    if let badge = badge {
                        Text(badge)
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.skinLabSubtext.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.skinLabSubtext)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(badge != nil ? "\(title), \(badge!)" : title)
            .accessibilityValue(isExpanded ? "已展开" : "已折叠")
            .accessibilityHint(isExpanded ? "点击折叠" : "点击展开")
            .accessibilityAddTraits(.isButton)

            // Content (collapsible)
            if isExpanded {
                content()
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
}

// MARK: - Expand/Collapse All Control

/// A toolbar control for expanding or collapsing all sections
struct ExpandCollapseAllButton: View {
    @ObservedObject var manager: CollapsibleSectionManager
    let sectionIds: [String]

    private var allExpanded: Bool {
        manager.allExpanded(sectionIds)
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                if allExpanded {
                    manager.collapseAll()
                } else {
                    manager.expandAll(sectionIds)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: allExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                    .font(.subheadline)
                Text(allExpanded ? "全部折叠" : "全部展开")
                    .font(.skinLabCaption)
            }
            .foregroundColor(.skinLabPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.skinLabPrimary.opacity(0.1))
            .cornerRadius(8)
        }
        .accessibilityLabel(allExpanded ? "折叠所有区块" : "展开所有区块")
    }
}

// MARK: - Section Summary Badge

/// A compact summary badge that remains visible when section is collapsed
struct SectionSummaryBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.skinLabCaption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var manager = CollapsibleSectionManager()

        let sectionIds = ["section1", "section2", "section3"]

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Expand/Collapse All
                        HStack {
                            Spacer()
                            ExpandCollapseAllButton(manager: manager, sectionIds: sectionIds)
                        }
                        .padding(.horizontal)

                        // Section 1
                        CollapsibleSection(
                            sectionId: "section1",
                            title: "第一个区块",
                            systemImage: "star.fill",
                            manager: manager
                        ) {
                            Text("这是第一个区块的内容")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }

                        // Section 2 with badge
                        CollapsibleSection(
                            sectionId: "section2",
                            title: "第二个区块",
                            systemImage: "chart.bar.fill",
                            badge: "3项",
                            manager: manager
                        ) {
                            VStack(spacing: 8) {
                                ForEach(1...3, id: \.self) { index in
                                    Text("项目 \(index)")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }

                        // Section 3
                        CollapsibleSection(
                            sectionId: "section3",
                            title: "第三个区块",
                            systemImage: "lightbulb.fill",
                            manager: manager
                        ) {
                            Text("这是第三个区块的内容，包含更多详细信息。")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .navigationTitle("折叠区块示例")
            }
        }
    }

    return PreviewWrapper()
}
