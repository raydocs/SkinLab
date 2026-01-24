import Foundation

// MARK: - Protocol
protocol RoutineServiceProtocol: Sendable {
    func generateRoutine(
        analysis: SkinAnalysis,
        profile: UserProfile?,
        trackingReport: EnhancedTrackingReport?,
        negativeIngredients: [String]
    ) async throws -> SkincareRoutine
}

// MARK: - Service Implementation
@MainActor
final class RoutineService: RoutineServiceProtocol {
    private let geminiService: GeminiService

    init(geminiService: GeminiService = GeminiService()) {
        self.geminiService = geminiService
    }

    func generateRoutine(
        analysis: SkinAnalysis,
        profile: UserProfile? = nil,
        trackingReport: EnhancedTrackingReport? = nil,
        negativeIngredients: [String] = []
    ) async throws -> SkincareRoutine {
        // Build prompt for routine generation
        let prompt = buildRoutinePrompt(
            analysis: analysis,
            profile: profile,
            trackingReport: trackingReport,
            negativeIngredients: negativeIngredients
        )

        // Call Gemini API
        let response = try await geminiService.generateRoutine(prompt: prompt)

        // Parse and return routine
        return try parseRoutineResponse(response, analysis: analysis, profile: profile)
    }

    private func buildRoutinePrompt(
        analysis: SkinAnalysis,
        profile: UserProfile?,
        trackingReport: EnhancedTrackingReport?,
        negativeIngredients: [String]
    ) -> String {
        var sections: [String] = []

        // Current skin state
        var skinState = """
        ## 当前皮肤状态
        - 肤质：\(analysis.skinType.displayName)
        - 综合评分：\(analysis.overallScore)/100
        - 皮肤年龄：\(analysis.skinAge)岁
        - 主要问题：斑点(\(analysis.issues.spots)/10), 痘痘(\(analysis.issues.acne)/10), 毛孔(\(analysis.issues.pores)/10), 皱纹(\(analysis.issues.wrinkles)/10), 泛红(\(analysis.issues.redness)/10)
        """
        sections.append(skinState)

        // User profile
        if let profile = profile {
            var profileSection = "\n## 用户档案"
            if let skinType = profile.skinType {
                profileSection += "\n- 自述肤质：\(skinType.displayName)"
            }
            profileSection += "\n- 年龄段：\(profile.ageRange.displayName)"

            if !profile.concerns.isEmpty {
                profileSection += "\n- 关注问题：\(profile.concerns.map { $0.displayName }.joined(separator: "、"))"
            }

            if !profile.allergies.isEmpty {
                profileSection += "\n- 过敏成分：\(profile.allergies.joined(separator: "、"))"
            }

            if profile.pregnancyStatus.requiresSpecialCare {
                profileSection += "\n- 特殊状态：\(profile.pregnancyStatus.displayName)（需避免维A酸、水杨酸、精油等）"
            }

            if !profile.activePrescriptions.isEmpty {
                profileSection += "\n- 正在使用处方药：\(profile.activePrescriptions.joined(separator: "、"))"
            }

            let prefs = profile.routinePreferences
            var prefsList: [String] = []
            if prefs.preferVegan { prefsList.append("纯素") }
            if prefs.preferCrueltyFree { prefsList.append("零残忍") }
            if prefs.avoidAlcohol { prefsList.append("无酒精") }
            if prefs.avoidFragrance { prefsList.append("无香精") }
            if prefs.avoidEssentialOils { prefsList.append("无精油") }
            if prefs.preferNatural { prefsList.append("偏好天然") }

            if !prefsList.isEmpty {
                profileSection += "\n- 产品偏好：\(prefsList.joined(separator: "、"))"
            }

            if let maxPrice = profile.budgetLevel.maxPricePerProduct {
                profileSection += "\n- 预算：单品不超过¥\(maxPrice)"
            }

            profileSection += "\n- 护肤步骤：早上最多\(prefs.maxAMSteps)步，晚上最多\(prefs.maxPMSteps)步"

            if let texture = profile.preferredTexture {
                profileSection += "\n- 质地偏好：\(texture.displayName)"
            }

            sections.append(profileSection)
        }

        // Tracking insights
        if let report = trackingReport {
            var trackingSection = "\n## 追踪数据洞察（过去\(report.duration)天）"

            if let summary = report.aiSummary, !summary.isEmpty {
                trackingSection += "\n- 整体趋势：\(summary)"
            } else {
                if report.overallImprovement > 5 {
                    trackingSection += "\n- 皮肤状态有所改善（+\(String(format: "%.1f", report.overallImprovement))%）"
                } else if report.overallImprovement < -5 {
                    trackingSection += "\n- 皮肤状态有所恶化（\(String(format: "%.1f", report.overallImprovement))%）"
                }
            }

            let worsening = report.issuesNeedingAttention.prefix(3)
            if !worsening.isEmpty {
                trackingSection += "\n- 需要关注的问题："
                for issue in worsening {
                    trackingSection += "\n  · \(issue.dimension)（从\(issue.beforeScore)恶化到\(issue.afterScore)）"
                }
            }

            let improving = report.topImprovements.prefix(2)
            if !improving.isEmpty {
                trackingSection += "\n- 改善明显的方面："
                for issue in improving {
                    trackingSection += "\n  · \(issue.dimension)（从\(issue.beforeScore)改善到\(issue.afterScore)）"
                }
            }

            sections.append(trackingSection)
        }

        // Negative ingredients
        if !negativeIngredients.isEmpty {
            let negativeSection = "\n## 避免成分（用户反应不佳）\n\(negativeIngredients.prefix(10).joined(separator: "、"))"
            sections.append(negativeSection)
        }

        // JSON output format and requirements
        let outputFormat = """


        ## 输出要求
        请以JSON格式输出护肤方案：
        {
          "weeksDuration": 4-8周的整数,
          "adjustmentReason": "简短说明调整理由（基于追踪数据或用户偏好）",
          "goals": ["控痘祛痘"|"舒缓敏感"|"补水保湿"|"细致毛孔"|"淡化色斑"|"抗衰老化"],
          "notes": ["整体建议（2-3条）"],
          "amSteps": [
            {
              "order": 1,
              "title": "步骤名",
              "productType": "产品类型",
              "instructions": "使用方法",
              "frequency": "使用频率",
              "precautions": ["注意事项"],
              "alternatives": ["替代方案"]
            }
          ],
          "pmSteps": [同上结构]
        }

        核心原则：
        1. 必须避开过敏成分、负向成分、孕期禁忌
        2. 恶化问题需加强，改善问题可维持
        3. 控制步骤数在用户偏好范围
        4. 遵循预算和偏好约束

        仅返回JSON，不要其他文字或markdown。
        """

        sections.append(outputFormat)

        return "你是专业护肤顾问。根据以下信息生成个性化护肤方案。\n" + sections.joined(separator: "\n")
    }

    private func parseRoutineResponse(_ response: String, analysis: SkinAnalysis, profile: UserProfile?) throws -> SkincareRoutine {
        // Extract JSON from response
        guard let jsonStart = response.range(of: "{"),
              let jsonEnd = response.range(of: "}", options: .backwards) else {
            throw RoutineError.invalidResponse
        }

        let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw RoutineError.invalidResponse
        }

        // Parse JSON
        let decoder = JSONDecoder()
        let routineData = try decoder.decode(RoutineData.self, from: jsonData)

        // Convert to SkincareRoutine
        var allSteps: [RoutineStep] = []

        for (index, step) in routineData.amSteps.enumerated() {
            allSteps.append(RoutineStep(
                phase: .am,
                order: index + 1,
                title: step.title,
                productType: step.productType,
                instructions: step.instructions,
                frequency: step.frequency,
                precautions: step.precautions,
                alternatives: step.alternatives
            ))
        }

        for (index, step) in routineData.pmSteps.enumerated() {
            allSteps.append(RoutineStep(
                phase: .pm,
                order: index + 1,
                title: step.title,
                productType: step.productType,
                instructions: step.instructions,
                frequency: step.frequency,
                precautions: step.precautions,
                alternatives: step.alternatives
            ))
        }

        let goals = routineData.goals.compactMap { goalString -> RoutineGoal? in
            switch goalString {
            case "控痘祛痘": return .acne
            case "舒缓敏感": return .sensitivity
            case "补水保湿": return .dryness
            case "细致毛孔": return .pores
            case "淡化色斑": return .pigmentation
            case "抗衰老化": return .antiAging
            default: return nil
            }
        }

        return SkincareRoutine(
            skinType: analysis.skinType,
            concerns: profile?.concerns ?? [],
            goals: goals,
            steps: allSteps,
            notes: routineData.notes,
            weeksDuration: routineData.weeksDuration
        )
    }
}

// MARK: - Helper Structures
private struct RoutineData: Codable {
    let weeksDuration: Int
    let adjustmentReason: String?
    let goals: [String]
    let notes: [String]
    let amSteps: [StepData]
    let pmSteps: [StepData]
}

private struct StepData: Codable {
    let order: Int
    let title: String
    let productType: String
    let instructions: String
    let frequency: String
    let precautions: [String]
    let alternatives: [String]
}

// MARK: - Errors
enum RoutineError: LocalizedError {
    case invalidResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "方案生成失败，请重试"
        case .parseError: return "数据解析失败"
        }
    }
}

// MARK: - GeminiService Extension
extension GeminiService {
    func generateRoutine(prompt: String) async throws -> String {
        // Reuse existing Gemini infrastructure
        let endpoint = "\(AppConfiguration.API.baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw GeminiError.apiError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(GeminiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConfiguration.API.referer, forHTTPHeaderField: "HTTP-Referer")

        let requestBody: [String: Any] = [
            "model": AppConfiguration.API.routineGenerationModel,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": AppConfiguration.Limits.routineGenerationMaxTokens
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GeminiError.parseError
        }

        return content
    }
}
