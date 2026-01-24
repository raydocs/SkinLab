//
//  ScenarioSelectionView.swift
//  SkinLab
//
//  场景选择视图
//  用户可以选择当前护肤场景，获取针对性护肤建议
//

import SwiftUI
import SwiftData

struct ScenarioSelectionView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: [SortDescriptor(\SkinAnalysisRecord.analyzedAt, order: .reverse)])
    private var recentAnalyses: [SkinAnalysisRecord]

    @State private var selectedScenario: SkinScenario?
    @State private var showRecommendation = false
    @State private var currentRecommendation: ScenarioRecommendation?

    private var profile: UserProfile? { profiles.first }
    private var latestAnalysis: SkinAnalysis? { recentAnalyses.first?.toAnalysis() }

    private let advisor = ScenarioAdvisor()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        quickAccessSection
                        allScenariosSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                        Text("场景护肤")
                            .font(.skinLabTitle3)
                            .foregroundColor(.skinLabText)
                    }
                }
            }
            .sheet(isPresented: $showRecommendation) {
                if let recommendation = currentRecommendation {
                    ScenarioRecommendationView(recommendation: recommendation)
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.romanticCream.ignoresSafeArea()

            Circle()
                .fill(LinearGradient.romanticBlushGradient)
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: -100, y: -200)
                .opacity(0.35)

            Circle()
                .fill(LinearGradient.skinLabLavenderGradient)
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 120, y: 300)
                .opacity(0.3)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }

            VStack(spacing: 8) {
                Text("选择你的场景")
                    .font(.skinLabTitle2)
                    .foregroundColor(.skinLabText)

                Text("获取针对当前情况的护肤建议")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(LinearGradient.skinLabGoldGradient)
                Text("常用场景")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach([SkinScenario.office, .outdoor, .travel, .homeRelax], id: \.self) { scenario in
                    ScenarioButton(
                        scenario: scenario,
                        isSelected: selectedScenario == scenario
                    ) {
                        selectScenario(scenario)
                    }
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - All Scenarios Section

    private var allScenariosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ScenarioCategory.allCases, id: \.self) { category in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                        Text(category.rawValue)
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                    }
                    .padding(.horizontal, 4)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(category.scenarios, id: \.self) { scenario in
                            ScenarioButton(
                                scenario: scenario,
                                isSelected: selectedScenario == scenario
                            ) {
                                selectScenario(scenario)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.skinLabCardBackground)
                .cornerRadius(20)
                .skinLabSoftShadow()
            }
        }
    }

    // MARK: - Actions

    private func selectScenario(_ scenario: SkinScenario) {
        selectedScenario = scenario

        // Track scenario selection
        AnalyticsEvents.scenarioSelected(scenario: scenario.rawValue)

        // Track first scenario used for feature usage depth
        FunnelTracker.shared.trackFirstScenarioUsed(scenario: scenario.rawValue)

        // Generate recommendation
        let defaultProfile = UserProfile(
            skinType: .combination,
            ageRange: .age25to30,
            concerns: [],
            allergies: []
        )

        currentRecommendation = advisor.generateRecommendation(
            scenario: scenario,
            profile: profile ?? defaultProfile,
            currentAnalysis: latestAnalysis
        )

        showRecommendation = true
    }
}

// MARK: - Scenario Button

struct ScenarioButton: View {
    let scenario: SkinScenario
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(scenario.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: scenario.icon)
                        .font(.system(size: 22))
                        .foregroundColor(scenario.color)
                }

                Text(scenario.rawValue)
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.romanticWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? scenario.color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: scenario.color.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scenario Recommendation View

struct ScenarioRecommendationView: View {
    @Environment(\.dismiss) private var dismiss
    let recommendation: ScenarioRecommendation

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerCard
                    summaryCard
                    doListCard
                    dontListCard
                    ingredientCard
                    productTipsCard
                }
                .padding()
                .padding(.bottom, 20)
            }
            .background(Color.skinLabBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(recommendation.scenario.rawValue)
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.skinLabSubtext)
                    }
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(recommendation.scenario.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: recommendation.scenario.icon)
                    .font(.system(size: 36))
                    .foregroundColor(recommendation.scenario.color)
            }

            VStack(spacing: 6) {
                Text(recommendation.scenario.rawValue)
                    .font(.skinLabTitle2)
                    .foregroundColor(.skinLabText)

                Text(recommendation.scenario.description)
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)

                Text(recommendation.scenario.durationHint)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.skinLabPrimary.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("建议概述")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            Text(recommendation.summary)
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Do List Card

    private var doListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.skinLabSuccess)
                Text("应该做")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(recommendation.doList, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.skinLabSuccess)
                            .frame(width: 20, height: 20)
                            .background(Color.skinLabSuccess.opacity(0.15))
                            .clipShape(Circle())

                        Text(item)
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.skinLabSuccess.opacity(0.2), lineWidth: 1)
        )
        .skinLabSoftShadow()
    }

    // MARK: - Don't List Card

    private var dontListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.skinLabError)
                Text("避免做")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(recommendation.dontList, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.skinLabError)
                            .frame(width: 20, height: 20)
                            .background(Color.skinLabError.opacity(0.15))
                            .clipShape(Circle())

                        Text(item)
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.skinLabError.opacity(0.2), lineWidth: 1)
        )
        .skinLabSoftShadow()
    }

    // MARK: - Ingredient Card

    private var ingredientCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "flask.fill")
                    .foregroundStyle(LinearGradient.skinLabLavenderGradient)
                Text("成分指南")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            // Focus ingredients
            if !recommendation.ingredientFocus.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("推荐成分")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)

                    FlowLayout(spacing: 8) {
                        ForEach(recommendation.ingredientFocus, id: \.self) { ingredient in
                            IngredientTag(name: ingredient, isPositive: true)
                        }
                    }
                }
            }

            // Avoid ingredients
            if !recommendation.ingredientAvoid.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("避免成分")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)

                    FlowLayout(spacing: 8) {
                        ForEach(recommendation.ingredientAvoid, id: \.self) { ingredient in
                            IngredientTag(name: ingredient, isPositive: false)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Product Tips Card

    private var productTipsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(LinearGradient.skinLabGoldGradient)
                Text("产品建议")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(recommendation.productTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.skinLabPrimary)
                            .padding(.top, 6)

                        Text(tip)
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
}

// MARK: - Ingredient Tag

struct IngredientTag: View {
    let name: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "plus" : "minus")
                .font(.system(size: 10, weight: .bold))
            Text(name)
                .font(.skinLabCaption)
        }
        .foregroundColor(isPositive ? .skinLabSuccess : .skinLabError)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            (isPositive ? Color.skinLabSuccess : Color.skinLabError).opacity(0.12)
        )
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ScenarioSelectionView()
}

#Preview("Recommendation") {
    ScenarioRecommendationView(
        recommendation: ScenarioRecommendation(
            scenario: .office,
            summary: "干性肤质在办公室场景下，需注意保湿补水和抗蓝光防护。",
            doList: [
                "每2-3小时使用保湿喷雾补水",
                "使用含抗蓝光成分的护肤品",
                "中午补涂防晒（如靠窗）",
                "定时起身活动促进血液循环"
            ],
            dontList: [
                "不要长时间不补水",
                "避免用手摸脸",
                "不要忽视室内防晒"
            ],
            productTips: [
                "选择轻薄保湿喷雾",
                "使用含抗蓝光成分的日霜",
                "备一支护手霜"
            ],
            ingredientFocus: ["透明质酸", "烟酰胺", "维生素E", "积雪草"],
            ingredientAvoid: ["高浓度酒精"]
        )
    )
}
