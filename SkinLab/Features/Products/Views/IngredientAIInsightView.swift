import SwiftUI

// MARK: - AI Insight View
struct IngredientAIInsightView: View {
    let result: IngredientAIResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.skinLabLavenderGradient.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(LinearGradient.skinLabLavenderGradient)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI 智能分析")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    
                    HStack(spacing: 4) {
                        Text("置信度")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                        Text("\(result.confidence)%")
                            .font(.skinLabCaption)
                            .fontWeight(.medium)
                            .foregroundStyle(confidenceGradient)
                    }
                }
                
                Spacer()
                
                // Compatibility Score
                CompatibilityScoreBadge(score: result.compatibilityScore)
            }
            
            // Summary
            Text(result.summary)
                .font(.skinLabBody)
                .foregroundColor(.skinLabText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.skinLabBackground.opacity(0.6))
                )
            
            // Risk Tags
            if !result.riskTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(result.riskTags, id: \.self) { tag in
                        RiskTagView(tag: tag)
                    }
                }
            }
            
            // Ingredient Concerns
            if !result.ingredientConcerns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("需关注成分")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSubtext)
                    
                    ForEach(result.ingredientConcerns) { concern in
                        IngredientConcernRow(concern: concern)
                    }
                }
            }
            
            // Usage Tips
            if !result.usageTips.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabAccent)
                        Text("使用建议")
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(result.usageTips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.skinLabSuccess)
                                Text(tip)
                                    .font(.skinLabBody)
                                    .foregroundColor(.skinLabText)
                            }
                        }
                    }
                }
            }
            
            // Avoid Combos
            if !result.avoidCombos.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabWarning)
                        Text("避免搭配")
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.avoidCombos, id: \.self) { combo in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.skinLabWarning)
                                Text(combo)
                                    .font(.skinLabBody)
                                    .foregroundColor(.skinLabText)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.skinLabCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.skinLabPrimary.opacity(0.3), Color.skinLabSecondary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
    
    private var confidenceGradient: LinearGradient {
        if result.confidence >= 80 {
            return LinearGradient(colors: [.skinLabSuccess, .skinLabSuccess.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        } else if result.confidence >= 60 {
            return LinearGradient.skinLabGoldGradient
        } else {
            return LinearGradient(colors: [.skinLabWarning, .skinLabWarning.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Compatibility Score Badge
struct CompatibilityScoreBadge: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(scoreGradient)
            Text("适配度")
                .font(.system(size: 10))
                .foregroundColor(.skinLabSubtext)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(scoreBackgroundColor.opacity(0.1))
        )
    }
    
    private var scoreGradient: LinearGradient {
        if score >= 80 {
            return LinearGradient(colors: [.skinLabSuccess, .skinLabSuccess.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        } else if score >= 60 {
            return LinearGradient.skinLabGoldGradient
        } else {
            return LinearGradient(colors: [.skinLabWarning, .skinLabWarning.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var scoreBackgroundColor: Color {
        if score >= 80 { return .skinLabSuccess }
        else if score >= 60 { return .skinLabAccent }
        else { return .skinLabWarning }
    }
}

// MARK: - Risk Tag View
struct RiskTagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.skinLabWarning)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.skinLabWarning.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(Color.skinLabWarning.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Ingredient Concern Row
struct IngredientConcernRow: View {
    let concern: IngredientConcern
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(riskColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(concern.name)
                    .font(.skinLabSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.skinLabText)
                
                Text(concern.reason)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }
            
            Spacer()
            
            Text(riskLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(riskColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(riskColor.opacity(0.12))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.skinLabBackground.opacity(0.5))
        )
    }
    
    private var riskColor: Color {
        switch concern.riskLevel {
        case .high: return .skinLabError
        case .medium: return .skinLabWarning
        case .low: return .skinLabAccent
        }
    }

    private var riskLabel: String {
        switch concern.riskLevel {
        case .high: return "高风险"
        case .medium: return "中风险"
        case .low: return "低风险"
        }
    }
}

// MARK: - AI Loading View
struct AIAnalysisLoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(LinearGradient.skinLabLavenderGradient.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(LinearGradient.skinLabLavenderGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI 正在分析成分...")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)
                
                Text("智能解读成分功效与风险")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skinLabCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient.skinLabLavenderGradient.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - AI Error View
struct AIAnalysisErrorView: View {
    let errorMessage: String?
    let onRetry: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 24))
                .foregroundColor(.skinLabSubtext)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI 分析暂不可用")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)
                
                if let message = errorMessage {
                    Text(message)
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button {
                onRetry()
            } label: {
                Text("重试")
                    .font(.skinLabCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.skinLabPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.skinLabPrimary.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skinLabCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            IngredientAIInsightView(result: IngredientAIResult(
                summary: "这款产品整体配方温和，适合敏感肌日常使用。含有透明质酸和烟酰胺等有效成分，保湿效果不错。",
                riskTags: ["含香精", "含防腐剂"],
                ingredientConcerns: [
                    IngredientConcern(name: "香精", reason: "可能引起敏感肌刺激", riskLevel: .medium),
                    IngredientConcern(name: "酒精", reason: "干性肌肤慎用", riskLevel: .low)
                ],
                compatibilityScore: 78,
                usageTips: ["建议晚间使用", "配合保湿霜效果更佳", "避免与高浓度酸类产品叠加"],
                avoidCombos: ["不建议与视黄醇同时使用", "避免与果酸类产品叠加"],
                confidence: 85
            ))
            
            AIAnalysisLoadingView()
            
            AIAnalysisErrorView(errorMessage: "网络连接失败") {
                print("Retry")
            }
        }
        .padding()
    }
    .background(Color.skinLabBackground)
}
