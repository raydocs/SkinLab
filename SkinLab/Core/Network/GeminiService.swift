import Foundation
import UIKit

// MARK: - OpenRouter Configuration (Gemini via OpenRouter)
enum GeminiConfig {
    static let model = AppConfiguration.API.skinAnalysisModel
    static let baseURL = AppConfiguration.API.baseURL

    // API Key from environment or Info.plist (NEVER hardcode!)
    static var apiKey: String {
        // 1. Try environment variable (for development)
        if let envKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // 2. Try Info.plist (for production - set via xcconfig)
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String, !plistKey.isEmpty {
            return plistKey
        }
        // 3. Fallback - should trigger error in GeminiService
        return ""
    }

    // Image optimization settings
    static let maxImageDimension: CGFloat = AppConfiguration.ImageProcessing.maxImageDimension
    static let imageCompressionQuality: CGFloat = AppConfiguration.ImageProcessing.compressionQuality
}

// MARK: - Skin Analysis Service Protocol (for dependency injection)
protocol SkinAnalysisServiceProtocol: Sendable {
    func analyzeSkin(image: UIImage) async throws -> SkinAnalysis
}

// MARK: - Ingredient AI Service Protocol
protocol IngredientAIServiceProtocol: Sendable {
    func analyzeIngredients(request: IngredientAIRequest) async throws -> IngredientAIResult
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case invalidImage
    case invalidAPIKey
    case networkError(Error)
    case apiError(String)
    case parseError
    case rateLimited
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "图片无效，请重新拍摄"
        case .invalidAPIKey: return "API Key未配置"
        case .networkError(let error): return "网络错误: \(error.localizedDescription)"
        case .apiError(let message): return "API错误: \(message)"
        case .parseError: return "解析失败，请重试"
        case .rateLimited: return "请求过于频繁，请稍后再试"
        case .unauthorized: return "认证失败"
        }
    }
}

// MARK: - Gemini Service
actor GeminiService: SkinAnalysisServiceProtocol {
    static let shared = GeminiService()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init(session: URLSession? = nil) {
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = AppConfiguration.API.requestTimeout
            config.timeoutIntervalForResource = AppConfiguration.API.resourceTimeout
            self.session = URLSession(configuration: config)
        }
    }
    
    // MARK: - Skin Analysis
    // Protocol conformance
    func analyzeSkin(image: UIImage) async throws -> SkinAnalysis {
        return try await analyzeSkin(image: image, previousAnalysis: nil, retryCount: 0)
    }

    // Enhanced version with context
    func analyzeSkin(
        image: UIImage,
        previousAnalysis: SkinAnalysis? = nil,
        retryCount: Int = 0
    ) async throws -> SkinAnalysis {
        guard !GeminiConfig.apiKey.isEmpty else {
            throw GeminiError.invalidAPIKey
        }
        
        // Optimize image before upload
        let optimizedImage = optimizeImage(image)
        
        guard let imageData = optimizedImage.jpegData(compressionQuality: GeminiConfig.imageCompressionQuality) else {
            throw GeminiError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        let request = try buildAnalysisRequest(
            base64Image: base64Image,
            previousAnalysis: previousAnalysis
        )
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.networkError(URLError(.badServerResponse))
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try parseAnalysisResponse(data)
            case 401:
                throw GeminiError.unauthorized
            case 429:
                // Rate limited - retry with exponential backoff
                if retryCount < AppConfiguration.API.maxRetryAttempts {
                    let delay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await analyzeSkin(
                        image: image,
                        previousAnalysis: previousAnalysis,
                        retryCount: retryCount + 1
                    )
                }
                throw GeminiError.rateLimited
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw GeminiError.apiError(errorMessage)
            }
        } catch let error as GeminiError {
            throw error
        } catch {
            // Network error - retry
            if retryCount < AppConfiguration.API.maxNetworkRetryAttempts {
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await analyzeSkin(
                    image: image,
                    previousAnalysis: previousAnalysis,
                    retryCount: retryCount + 1
                )
            }
            throw GeminiError.networkError(error)
        }
    }
    
    // MARK: - Image Optimization
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let maxDimension = GeminiConfig.maxImageDimension
        let size = image.size
        
        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Request Building (OpenRouter Format)
    private func buildAnalysisRequest(
        base64Image: String,
        previousAnalysis: SkinAnalysis?
    ) throws -> URLRequest {
        guard let url = URL(string: AppConfiguration.API.chatCompletionsEndpoint) else {
            throw GeminiError.apiError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(GeminiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConfiguration.API.referer, forHTTPHeaderField: "HTTP-Referer")
        request.setValue(AppConfiguration.API.title, forHTTPHeaderField: "X-Title")

        // Build prompt with historical context if available
        let prompt = buildPrompt(with: previousAnalysis)

        // OpenRouter uses OpenAI-compatible format
        let body: [String: Any] = [
            "model": GeminiConfig.model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": AppConfiguration.API.defaultTemperature,
            "max_tokens": AppConfiguration.Limits.skinAnalysisMaxTokens
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    // MARK: - Response Parsing (OpenRouter/OpenAI Format)
    private func parseAnalysisResponse(_ data: Data) throws -> SkinAnalysis {
        struct OpenRouterResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try decoder.decode(OpenRouterResponse.self, from: data)
        
        guard let text = response.choices.first?.message.content else {
            throw GeminiError.parseError
        }
        
        // Extract JSON object from text (handle markdown, extra text, etc.)
        guard let jsonString = extractJSON(from: text),
              let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.parseError
        }
        
        // Helper function to clamp values
        func clamp(_ value: Int, _ min: Int, _ max: Int) -> Int {
            Swift.max(min, Swift.min(max, value))
        }

        // Helper to decode Int or Double
        struct DoubleOrInt: Codable {
            let value: Int

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let intValue = try? container.decode(Int.self) {
                    value = intValue
                } else if let doubleValue = try? container.decode(Double.self) {
                    value = Int(doubleValue.rounded())
                } else {
                    throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected Int or Double"
                    ))
                }
            }
        }

        struct FlexibleIssueScores: Codable {
            let spots: DoubleOrInt
            let acne: DoubleOrInt
            let pores: DoubleOrInt
            let wrinkles: DoubleOrInt
            let redness: DoubleOrInt
            let evenness: DoubleOrInt
            let texture: DoubleOrInt

            func toIssueScores() -> IssueScores {
                func clamp(_ value: Int, _ min: Int, _ max: Int) -> Int {
                    Swift.max(min, Swift.min(max, value))
                }
                return IssueScores(
                    spots: clamp(spots.value, 0, 10),
                    acne: clamp(acne.value, 0, 10),
                    pores: clamp(pores.value, 0, 10),
                    wrinkles: clamp(wrinkles.value, 0, 10),
                    redness: clamp(redness.value, 0, 10),
                    evenness: clamp(evenness.value, 0, 10),
                    texture: clamp(texture.value, 0, 10)
                )
            }
        }

        struct FlexibleRegionScores: Codable {
            let tZone: DoubleOrInt
            let leftCheek: DoubleOrInt
            let rightCheek: DoubleOrInt
            let eyeArea: DoubleOrInt
            let chin: DoubleOrInt

            func toRegionScores() -> RegionScores {
                func clamp(_ value: Int, _ min: Int, _ max: Int) -> Int {
                    Swift.max(min, Swift.min(max, value))
                }
                return RegionScores(
                    tZone: clamp(tZone.value, 0, 100),
                    leftCheek: clamp(leftCheek.value, 0, 100),
                    rightCheek: clamp(rightCheek.value, 0, 100),
                    eyeArea: clamp(eyeArea.value, 0, 100),
                    chin: clamp(chin.value, 0, 100)
                )
            }
        }

        // Flexible Image Quality structure
        struct FlexibleImageQuality: Codable {
            let lighting: DoubleOrInt
            let sharpness: DoubleOrInt
            let angle: DoubleOrInt
            let occlusion: DoubleOrInt
            let faceCoverage: DoubleOrInt
            let notes: [String]
            
            func toImageQuality() -> ImageQuality {
                func clamp(_ value: Int, _ min: Int, _ max: Int) -> Int {
                    Swift.max(min, Swift.min(max, value))
                }
                return ImageQuality(
                    lighting: clamp(lighting.value, 0, 100),
                    sharpness: clamp(sharpness.value, 0, 100),
                    angle: clamp(angle.value, 0, 100),
                    occlusion: clamp(occlusion.value, 0, 100),
                    faceCoverage: clamp(faceCoverage.value, 0, 100),
                    notes: notes
                )
            }
        }
        
        // Flexible JSON structure that accepts both Int and Double
        struct AnalysisJSON: Codable {
            let skinType: String
            let skinAge: DoubleOrInt
            let overallScore: DoubleOrInt
            let issues: FlexibleIssueScores
            let regions: FlexibleRegionScores
            let recommendations: [String]
            let confidenceScore: DoubleOrInt?
            let imageQuality: FlexibleImageQuality?
        }
        
        let analysisJSON = try decoder.decode(AnalysisJSON.self, from: jsonData)
        
        guard let skinType = SkinType(rawValue: analysisJSON.skinType) else {
            throw GeminiError.parseError
        }
        
        return SkinAnalysis(
            skinType: skinType,
            skinAge: clamp(analysisJSON.skinAge.value, 15, 80),
            overallScore: clamp(analysisJSON.overallScore.value, 0, 100),
            issues: analysisJSON.issues.toIssueScores(),
            regions: analysisJSON.regions.toRegionScores(),
            recommendations: analysisJSON.recommendations,
            confidenceScore: analysisJSON.confidenceScore.map { clamp($0.value, 0, 100) } ?? 70,
            imageQuality: analysisJSON.imageQuality?.toImageQuality()
        )
    }
    
    /// Extract first JSON object from text
    private func extractJSON(from text: String) -> String? {
        // Remove markdown code blocks
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find first { and last }
        guard let start = cleaned.firstIndex(of: "{"),
              let end = cleaned.lastIndex(of: "}") else {
            return nil
        }
        
        return String(cleaned[start...end])
    }
    
    // MARK: - Prompt Building
    private func buildPrompt(with previousAnalysis: SkinAnalysis?) -> String {
        var prompt = baseAnalysisPrompt
        
        // Add historical context if available
        if let previous = previousAnalysis {
            let historyContext = """

            ## 历史数据参考
            上次分析结果（\(daysAgo(from: previous.analyzedAt))天前）：
            - 肤质：\(previous.skinType.displayName)
            - 皮肤年龄：\(previous.skinAge)岁
            - 综合评分：\(previous.overallScore)/100
            - 主要问题：痘痘\(previous.issues.acne)/10，泛红\(previous.issues.redness)/10，色斑\(previous.issues.spots)/10

            **重要提示**：如果当前照片的评分与历史相比变化超过2级（如痘痘从3变到6+，或泛红从7降到4-），请在recommendations中说明可能的原因。
            """
            
            prompt += historyContext
        }
        
        return prompt
    }
    
    private var baseAnalysisPrompt: String {
        """
        你是一位专业皮肤科医生，拥有20年临床经验。请仔细分析这张面部照片。

        ## 分析要求
        请评估以下维度，以JSON格式返回结果：

        1. skinType: 肤质类型（仅返回以下之一）
           - "dry": 干性
           - "oily": 油性
           - "combination": 混合性
           - "sensitive": 敏感性

        2. skinAge: 皮肤表观年龄（整数，15-80之间）

        3. overallScore: 综合健康评分（整数，0-100，100为完美）

        4. issues: 问题评分（每项为整数，0-10，0为无问题，10为严重）
           - spots: 色斑/色素沉着
           - acne: 痘痘/粉刺
           - pores: 毛孔粗大
           - wrinkles: 皱纹/细纹
           - redness: 红血丝/泛红
           - evenness: 肤色不均（0为均匀，10为很不均匀）
           - texture: 纹理粗糙（0为光滑，10为很粗糙）

        5. regions: 区域评分（每项为整数，0-100，100为最佳）
           - tZone: T区（额头+鼻子）
           - leftCheek: 左脸颊
           - rightCheek: 右脸颊
           - eyeArea: 眼周
           - chin: 下巴

        6. recommendations: 护肤建议数组（3-5条，具体可执行的建议）

        7. confidenceScore: 分析可信度评分（整数，0-100，表示对分析结果的信心程度）

        8. imageQuality: 图片质量评估（可选对象，如果照片质量不理想请提供）
           - lighting: 光线质量（0-100，光线是否充足均匀）
           - sharpness: 清晰度（0-100，图片是否清晰）
           - angle: 角度正面程度（0-100，是否正面拍摄）
           - occlusion: 遮挡程度（0-100，面部是否无遮挡，100表示无遮挡）
           - faceCoverage: 面部覆盖度（0-100，面部是否完整可见）
           - notes: 质量改进建议数组（1-3条，如果有问题请说明）

        ## 输出格式
        **仅返回JSON对象，不要包含任何其他文字、解释或markdown代码块标记。**
        所有数值必须是整数（不要使用小数）。
        如果照片质量良好，imageQuality可以省略。
        """
    }
    
    private func daysAgo(from date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, days)
    }
}

// MARK: - Ingredient AI Analysis Extension
extension GeminiService: IngredientAIServiceProtocol {
    
    func analyzeIngredients(request: IngredientAIRequest) async throws -> IngredientAIResult {
        guard !GeminiConfig.apiKey.isEmpty else {
            throw GeminiError.invalidAPIKey
        }

        // Retry logic with exponential backoff
        let maxRetries = AppConfiguration.API.maxRetryAttempts
        var retryDelay: TimeInterval = 1.0

        for attempt in 0..<maxRetries {
            // Check if task is cancelled
            if Task.isCancelled {
                throw CancellationError()
            }

            do {
                let apiRequest = try buildIngredientAnalysisRequest(request: request)
                let (data, response) = try await session.data(for: apiRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GeminiError.networkError(URLError(.badServerResponse))
                }

                switch httpResponse.statusCode {
                case 200:
                    return try parseIngredientAnalysisResponse(data)

                case 401:
                    throw GeminiError.unauthorized

                case 429:
                    // Rate limited - respect Retry-After header if present
                    if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let seconds = TimeInterval(retryAfter) {
                        retryDelay = seconds
                    }

                    // Only retry if we have attempts left
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                        retryDelay *= 2  // Exponential backoff
                        continue
                    }
                    throw GeminiError.rateLimited

                case 500...599:
                    // Server error - retry with backoff
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                        retryDelay *= 2
                        continue
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                    throw GeminiError.apiError(errorMessage)

                default:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw GeminiError.apiError(errorMessage)
                }
            } catch let error as GeminiError {
                // Don't retry on client errors (401, invalid key, parse errors)
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Network errors - retry
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    retryDelay *= 2
                    continue
                }
                throw GeminiError.networkError(error)
            }
        }

        // Should never reach here
        throw GeminiError.networkError(URLError(.unknown))
    }
    
    private func buildIngredientAnalysisRequest(request: IngredientAIRequest) throws -> URLRequest {
        guard let url = URL(string: AppConfiguration.API.chatCompletionsEndpoint) else {
            throw GeminiError.apiError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(GeminiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(AppConfiguration.API.referer, forHTTPHeaderField: "HTTP-Referer")
        urlRequest.setValue(AppConfiguration.API.title, forHTTPHeaderField: "X-Title")

        let prompt = buildIngredientPrompt(request: request)

        let body: [String: Any] = [
            "model": GeminiConfig.model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": AppConfiguration.API.defaultTemperature,
            "max_tokens": AppConfiguration.Limits.ingredientAnalysisMaxTokens
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        return urlRequest
    }

    private func buildIngredientPrompt(request: IngredientAIRequest) -> String {
        var prompt = """
        你是资深皮肤科医生和化妆品配方专家，拥有15年临床经验。请基于用户的个人资料，对以下成分配方进行专业、个性化的分析。

        ## 成分列表
        \(request.ingredients.joined(separator: ", "))

        """

        // Enhanced profile section with priority emphasis
        if let profile = request.profileSnapshot {
            prompt += """

            ## 用户个人资料（分析重点）
            """

            // Skin type with specific guidance
            if let skinType = profile.skinType {
                prompt += "\n**肤质**：\(skinType)"
                switch skinType.lowercased() {
                case "dry", "干性":
                    prompt += "（需要重点关注成分的保湿能力，避免过度清洁和刺激性成分）"
                case "oily", "油性":
                    prompt += "（需要重点关注成分的控油、抗痘能力，避免致痘性成分）"
                case "sensitive", "敏感性":
                    prompt += "（这是最高优先级！必须严格筛查刺激性成分，即使是功效成分也要评估耐受性）"
                case "combination", "混合性":
                    prompt += "（需要平衡分析，关注成分的温和性和适配性）"
                default:
                    break
                }
            }

            // Concerns with explicit priorities
            if !profile.concerns.isEmpty {
                prompt += "\n**关注问题（按优先级）**：\(profile.concerns.joined(separator: " > "))"
                prompt += "\n→ 请在usageTips中针对这些问题给出具体的使用建议"
            }

            // Allergies - critical safety check
            if !profile.allergies.isEmpty {
                prompt += "\n**⚠️ 过敏史（极高优先级）**：\(profile.allergies.joined(separator: ", "))"
                prompt += "\n→ 如果成分列表中包含这些或相关成分，必须在ingredientConcerns中标记为high风险"
            }

            // Pregnancy status - safety critical
            if let pregnancy = profile.pregnancyStatus, pregnancy != "none" && pregnancy != "无" {
                prompt += "\n**⚠️ 孕期状态**：\(pregnancy)"
                prompt += "\n→ 必须筛查孕妇禁用成分（如维A醇类、水杨酸高浓度、某些精油等），并在riskTags中标注"
            }

            // Fragrance tolerance
            if let fragrance = profile.fragranceTolerance {
                prompt += "\n**香精耐受度**：\(fragrance)"
                if fragrance == "low" || fragrance == "低" {
                    prompt += "（如含香精，需在ingredientConcerns中说明）"
                }
            }
        }

        // Historical issues with context
        if let history = request.historySnapshot, !history.severeIssues.isEmpty {
            prompt += """

            ## 历史皮肤严重问题
            \(history.severeIssues.joined(separator: ", "))
            → 请分析成分配方是否有助于改善这些问题，或可能加重

            """

            // Add ingredient effectiveness data if available
            if !history.ingredientStats.isEmpty {
                let problematicIngredients = history.ingredientStats.filter { $0.value.worseCount > $0.value.betterCount }
                if !problematicIngredients.isEmpty {
                    prompt += """
                    **用户使用历史记录中的问题成分**：
                    \(problematicIngredients.keys.joined(separator: ", "))
                    → 如果这些成分出现在当前配方中，请在ingredientConcerns中特别说明

                    """
                }
            }
        }

        // User preferences
        if !request.preferences.isEmpty {
            prompt += """

            ## 用户偏好成分
            \(request.preferences.joined(separator: ", "))
            → 这些是用户希望看到的成分，如果配方中包含，请在summary中积极提及

            """
        }

        prompt += """

        ## 分析要求
        1. **个性化优先**：基于用户肤质、过敏史、孕期状态进行定制化评估，而非通用分析
        2. **风险分级明确**（严格遵循以下定义）：
           - **high**:
             * 用户过敏史中明确提到的成分或其衍生物
             * 孕妇/哺乳期禁用成分（维A类、高浓度水杨酸、某些精油等）
             * 对敏感肌的已知高刺激成分（高浓度酒精、强效去角质酸等）
             * 与用户历史严重不良反应成分相同或相似的成分
           - **medium**:
             * 潜在致敏成分但用户无过敏史（如香精、某些防腐剂）
             * 功效成分浓度可能过高或需要建立耐受（如高浓度烟酰胺、视黄醇）
             * 与用户肤质不完全适配的成分（如油性肌用厚重油脂）
             * 用户历史中有轻微不良反应的成分类别
           - **low**:
             * 需要注意使用方法的常规成分（如需要防晒的光敏成分）
             * 可能影响其他产品吸收的成分
             * 需要特定使用顺序的成分

        3. **机制说明**：每个ingredientConcerns的reason必须说明"为什么这个成分对该用户是问题"
           - ❌ 错误："可能引起刺激" → 太笼统
           - ✅ 正确："您的敏感性肤质对酒精的耐受度较低，高浓度酒精可能破坏皮肤屏障导致泛红"

        4. **建议可执行**：usageTips必须具体且可操作
           - ❌ 错误："请谨慎使用"、"建议咨询医生"
           - ✅ 正确："建议先在耳后或手腕内侧测试72小时，无不适后再小面积使用"、"初次使用每周2次，2周后可增至每日使用"

        5. **compatibilityScore 评分标准**：
           - 90-100: 完美适配，所有成分都适合用户，无任何风险
           - 70-89: 良好适配，主要成分适合，有少量需要注意的点
           - 50-69: 中等适配，有部分成分需要谨慎使用或建立耐受
           - 30-49: 适配度较低，有多个不适合成分或中等风险
           - 0-29: 不推荐，含有高风险成分或明确不适合用户

        6. **置信度诚实**：
           - 80-100: 用户资料完整，成分常见，分析基于充分证据
           - 60-79: 用户资料较完整或成分较常见，分析基本可靠
           - 40-59: 用户资料不完整或含有不常见成分，分析有一定推测
           - 0-39: 用户资料缺失严重或成分罕见，分析主要基于推测

        ## 分析示例（参考格式）
        **场景**: 敏感肌用户，香精过敏，关注泛红问题
        **成分**: Water, Niacinamide, Fragrance, Glycerin

        **正确输出**:
        {
            "summary": "此配方含有烟酰胺适合改善您的泛红问题，但含有香精成分与您的过敏史冲突，不建议使用",
            "riskTags": ["含过敏原-香精", "敏感肌需谨慎"],
            "ingredientConcerns": [
                {
                    "name": "Fragrance",
                    "reason": "您有明确的香精过敏史，使用含香精产品可能引发过敏反应，导致皮肤泛红、瘙痒或刺痛",
                    "riskLevel": "high"
                }
            ],
            "compatibilityScore": 25,
            "usageTips": [
                "由于含有您过敏的香精成分，强烈建议避免使用此产品",
                "如果一定要尝试，请先在耳后或手臂内侧小面积测试24-72小时",
                "出现任何不适（发红、刺痛、瘙痒）应立即停用并用清水冲洗"
            ],
            "avoidCombos": ["避免与其他含香精或潜在致敏成分的产品同时使用"],
            "confidence": 90
        }

        ## 输出格式（仅输出JSON，不要任何解释或markdown标记）
        {
            "summary": "基于用户资料的整体适配评价（2-3句话，说明为什么适合/不适合此用户，要具体提到关键成分和用户关注点）",
            "riskTags": ["针对用户的风险标签，如：含过敏原-具体成分名、孕妇禁用-具体成分名、敏感肌慎用、含酒精、含香精、需要建立耐受等"],
            "ingredientConcerns": [
                {
                    "name": "具体成分名",
                    "reason": "对该用户的具体影响机制（必须个性化，说明为什么对这个用户是问题）",
                    "riskLevel": "low/medium/high"（严格按照上述定义评级）
                }
            ],
            "compatibilityScore": 0-100的整数（严格按照上述评分标准打分）,
            "usageTips": ["3-5条具体可执行的建议，必须包含具体的使用方法、频率、顺序或注意事项"],
            "avoidCombos": ["基于用户当前状态和成分特性，该配方应避免与哪些其他成分/产品同时使用，要说明原因"],
            "confidence": 0-100的整数（严格按照上述置信度标准评估）
        }

        **关键要求**：
        - 所有字段必须完整填写，不能为空
        - 所有数值必须是整数（不要小数）
        - riskLevel只能是 "low"、"medium" 或 "high" 之一
        - 如果没有风险成分，ingredientConcerns可以为空数组[]
        - 如果没有需要避免的组合，avoidCombos可以为空数组[]
        - summary和usageTips必须个性化，不能使用通用模板话术
        """

        return prompt
    }
    
    private func parseIngredientAnalysisResponse(_ data: Data) throws -> IngredientAIResult {
        struct OpenRouterResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try decoder.decode(OpenRouterResponse.self, from: data)
        
        guard let text = response.choices.first?.message.content else {
            throw GeminiError.parseError
        }
        
        guard let jsonString = extractJSON(from: text),
              let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.parseError
        }
        
        let result = try decoder.decode(IngredientAIResult.self, from: jsonData)
        
        return IngredientAIResult(
            summary: result.summary,
            riskTags: result.riskTags,
            ingredientConcerns: result.ingredientConcerns,
            compatibilityScore: max(0, min(100, result.compatibilityScore)),
            usageTips: result.usageTips,
            avoidCombos: result.avoidCombos,
            confidence: max(0, min(100, result.confidence))
        )
    }
}
