import SwiftUI

struct EnhancedIngredientResultView: View {
    let enhancedResult: EnhancedIngredientScanResult
    let profile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ResultTab = .overview
    
    enum ResultTab: String, CaseIterable {
        case overview = "总览"
        case function = "功效分组"
        case personalized = "个性化"
        
        var icon: String {
            switch self {
            case .overview: return "doc.text.fill"
            case .function: return "square.grid.2x2.fill"
            case .personalized: return "person.fill"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with suitability
                headerSection
                
                // Tab Selector
                tabSelector
                
                // Content
                contentSection
            }
            .padding()
        }
        .background(Color.skinLabBackground)
        .navigationTitle("成分分析")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Suitability Score
            if enhancedResult.hasPersonalizedInfo {
                ZStack {
                    Circle()
                        .stroke(Color.skinLabSecondary.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(enhancedResult.suitabilityScore) / 100.0)
                        .stroke(
                            enhancedResult.suitableForUser ?
                                LinearGradient.skinLabSuccessGradient :
                                LinearGradient.skinLabWarningGradient,
                            lineWidth: 12
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(enhancedResult.suitabilityScore)")
                            .font(.skinLabTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.skinLabText)
                        
                        Text("适合度")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                }
                
                Text(enhancedResult.suitableForUser ? "适合你的肤质" : "需要谨慎使用")
                    .font(.skinLabHeadline)
                    .foregroundColor(enhancedResult.suitableForUser ? .skinLabSuccess : .skinLabWarning)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background((enhancedResult.suitableForUser ? Color.skinLabSuccess : Color.skinLabWarning).opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Overall Safety
            HStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .foregroundColor(safetyColor(enhancedResult.baseResult.overallSafety))
                
                Text("整体安全度：\(enhancedResult.baseResult.overallSafety.rawValue)")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(12)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(ResultTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.skinLabCaption)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .skinLabText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ?
                            AnyView(LinearGradient.skinLabRoseGradient) :
                            AnyView(Color.skinLabCardBackground)
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Content
    @ViewBuilder
    private var contentSection: some View {
        switch selectedTab {
        case .overview:
            overviewTab
        case .function:
            functionTab
        case .personalized:
            personalizedTab
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Highlights
            if !enhancedResult.baseResult.highlights.isEmpty {
                highlightSection(
                    title: "亮点成分",
                    icon: "star.fill",
                    items: enhancedResult.baseResult.highlights,
                    color: .skinLabSuccess
                )
            }
            
            // Warnings
            if !enhancedResult.baseResult.warnings.isEmpty {
                highlightSection(
                    title: "需要注意",
                    icon: "exclamationmark.triangle.fill",
                    items: enhancedResult.baseResult.warnings,
                    color: .skinLabWarning
                )
            }
            
            // All Ingredients
            VStack(alignment: .leading, spacing: 12) {
                Text("全部成分 (\(enhancedResult.baseResult.ingredients.count))")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
                
                FlowLayout(spacing: 8) {
                    ForEach(enhancedResult.baseResult.ingredients) { ingredient in
                        IngredientChip(ingredient: ingredient, isHighlighted: false)
                    }
                }
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Function Tab
    private var functionTab: some View {
        VStack(spacing: 16) {
            let analyzer = IngredientRiskAnalyzer()
            let groups = analyzer.getFunctionGroups(from: enhancedResult.baseResult.ingredients)
            
            ForEach(groups) { group in
                FunctionGroupCard(group: group)
            }
        }
    }
    
    // MARK: - Personalized Tab
    private var personalizedTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !enhancedResult.hasPersonalizedInfo {
                // No profile prompt
                noProfilePrompt
            } else {
                // Allergy warnings
                if !enhancedResult.allergyMatches.isEmpty {
                    allergyWarningSection
                }
                
                // Personalized warnings
                if !enhancedResult.personalizedWarnings.isEmpty {
                    highlightSection(
                        title: "个性化提醒",
                        icon: "exclamationmark.circle.fill",
                        items: enhancedResult.personalizedWarnings,
                        color: .skinLabError
                    )
                }
                
                // Concern matches
                if !enhancedResult.concernMatches.isEmpty {
                    concernMatchesSection
                }
                
                // Recommendations
                if !enhancedResult.personalizedRecommendations.isEmpty {
                    highlightSection(
                        title: "使用建议",
                        icon: "lightbulb.fill",
                        items: enhancedResult.personalizedRecommendations,
                        color: .skinLabAccent
                    )
                }
            }
        }
    }
    
    // MARK: - No Profile Prompt
    private var noProfilePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient.skinLabRoseGradient)
            
            Text("完善肤质档案")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)
            
            Text("添加肤质、关注问题和过敏成分，获得更准确的个性化分析")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)
            
            NavigationLink {
                // Link to profile edit
                Text("Edit Profile")
            } label: {
                Text("去设置")
                    .font(.skinLabHeadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient.skinLabRoseGradient)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Allergy Warning Section
    private var allergyWarningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.skinLabError)
                Text("过敏警告")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabError)
            }
            
            Text("检测到以下可能导致过敏的成分：")
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
            
            ForEach(enhancedResult.allergyMatches, id: \.self) { ingredient in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(.skinLabError)
                    
                    Text(ingredient)
                        .font(.skinLabBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .padding()
        .background(Color.skinLabError.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.skinLabError.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
    }
    
    // MARK: - Concern Matches Section
    private var concernMatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("针对你的关注")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)
            
            ForEach(Array(enhancedResult.concernMatches.keys), id: \.self) { concern in
                if let ingredients = enhancedResult.concernMatches[concern] {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(concern.rawValue, systemImage: "checkmark.circle.fill")
                            .font(.skinLabSubheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.skinLabSuccess)
                        
                        Text("含有：\(ingredients.joined(separator: "、"))")
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabText)
                    }
                    .padding()
                    .background(Color.skinLabSuccess.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Highlight Section
    private func highlightSection(title: String, icon: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
            }
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(color)
                    
                    Text(item)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    private func safetyColor(_ level: IngredientScanResult.SafetyLevel) -> Color {
        switch level {
        case .safe: return .skinLabSuccess
        case .caution: return .skinLabWarning
        case .warning: return .skinLabError
        }
    }
}

// MARK: - Function Group Card
struct FunctionGroupCard: View {
    let group: FunctionGroup
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
                    Image(systemName: group.icon)
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.displayName)
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                        
                        Text(group.description)
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    Spacer()
                    
                    // Count badge
                    Text("\(group.ingredients.count)")
                        .font(.skinLabCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(LinearGradient.skinLabPrimaryGradient)
                        .clipShape(Circle())
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.skinLabSubtext)
                }
            }
            
            // Expanded content
            if isExpanded {
                Divider()
                
                FlowLayout(spacing: 8) {
                    ForEach(group.ingredients) { ingredient in
                        IngredientChip(ingredient: ingredient, isHighlighted: true)
                    }
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

// MARK: - Ingredient Chip
struct IngredientChip: View {
    let ingredient: IngredientScanResult.ParsedIngredient
    let isHighlighted: Bool
    
    var body: some View {
        Text(ingredient.name)
            .font(.skinLabCaption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(chipBackground)
            .foregroundColor(chipTextColor)
            .cornerRadius(10)
    }
    
    private var chipBackground: some View {
        Group {
            if ingredient.isWarning {
                Color.skinLabError.opacity(0.15)
            } else if ingredient.isHighlight {
                Color.skinLabSuccess.opacity(0.15)
            } else if isHighlighted {
                LinearGradient.skinLabPrimaryGradient.opacity(0.15)
            } else {
                Color.skinLabSecondary.opacity(0.1)
            }
        }
    }
    
    private var chipTextColor: Color {
        if ingredient.isWarning {
            return .skinLabError
        } else if ingredient.isHighlight {
            return .skinLabSuccess
        } else {
            return .skinLabText
        }
    }
}
