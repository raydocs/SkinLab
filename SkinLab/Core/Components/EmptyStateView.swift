import SwiftUI

/// A reusable empty state component for guiding users when there's no content.
/// Provides consistent styling with customizable icon, text, and action.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    let features: [EmptyStateFeature]
    let iconGradient: LinearGradient

    /// Creates an empty state with optional features list
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String,
        iconGradient: LinearGradient = .skinLabPrimaryGradient,
        features: [EmptyStateFeature] = [],
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.iconGradient = iconGradient
        self.features = features
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon with layered circle effect
            iconSection

            // Text content
            textSection

            // Features list (if provided)
            if !features.isEmpty {
                featuresSection
            }

            // Action button
            actionButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(iconGradient.opacity(0.12))
                .frame(width: 120, height: 120)

            // Inner circle
            Circle()
                .fill(iconGradient.opacity(0.2))
                .frame(width: 90, height: 90)

            // Icon
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(iconGradient)

            // Sparkle decoration
            SparkleView(size: 16)
                .offset(x: 45, y: -40)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.skinLabTitle2)
                .foregroundColor(.skinLabText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features) { feature in
                EmptyStateFeatureRow(feature: feature)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                Text(actionTitle)
                    .font(.skinLabHeadline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(iconGradient)
            .cornerRadius(28)
            .shadow(color: .skinLabPrimary.opacity(0.35), radius: 12, y: 6)
        }
        .accessibilityLabel(actionTitle)
        .accessibilityHint(message)
    }
}

// MARK: - Empty State Feature

/// A feature item to display in the empty state
struct EmptyStateFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    var gradient: LinearGradient = .skinLabPrimaryGradient
}

// MARK: - Feature Row

private struct EmptyStateFeatureRow: View {
    let feature: EmptyStateFeature

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(feature.gradient.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: feature.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(feature.gradient)
            }

            Text(feature.text)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feature.text)
    }
}

// MARK: - Preview

#Preview("Empty State - Simple") {
    EmptyStateView(
        icon: "face.smiling",
        title: "Start Your Skin Journey",
        message: "Take your first photo to get a personalized skin analysis",
        actionTitle: "Start Analysis",
        action: {
            print("Action tapped")
        }
    )
}

#Preview("Empty State - With Features") {
    EmptyStateView(
        icon: "chart.line.uptrend.xyaxis",
        title: "Start 28-Day Tracking",
        message: "Record your skincare journey\nWitness real skin changes",
        actionTitle: "Start Tracking",
        features: [
            EmptyStateFeature(
                icon: "camera.fill",
                text: "Standardized photos for accurate comparison",
                gradient: .skinLabPrimaryGradient
            ),
            EmptyStateFeature(
                icon: "calendar.badge.clock",
                text: "Day 7/14/21/28 check-in reminders",
                gradient: .skinLabLavenderGradient
            ),
            EmptyStateFeature(icon: "chart.bar.fill", text: "AI-powered trend analysis", gradient: .skinLabGoldGradient)
        ],
        action: {
            print("Action tapped")
        }
    )
}
