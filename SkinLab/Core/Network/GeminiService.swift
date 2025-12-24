import Foundation
import UIKit

// MARK: - OpenRouter Configuration (Gemini via OpenRouter)
enum GeminiConfig {
    static let model = "google/gemini-3-flash-preview"
    static let baseURL = "https://openrouter.ai/api/v1"

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
    static let maxImageDimension: CGFloat = 1024
    static let imageCompressionQuality: CGFloat = 0.6
}

// MARK: - Skin Analysis Service Protocol (for dependency injection)
protocol SkinAnalysisServiceProtocol: Sendable {
    func analyzeSkin(image: UIImage) async throws -> SkinAnalysis
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
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
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
                if retryCount < 3 {
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
            if retryCount < 2 {
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
        let endpoint = "(GeminiConfig.baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw GeminiError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer (GeminiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://skinlab.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("SkinLab", forHTTPHeaderField: "X-Title")
        
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
                                "url": "data:image/jpeg;base64,(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": 0.1,
            "max_tokens": 512
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

        // Flexible JSON structure that accepts both Int and Double
        struct AnalysisJSON: Codable {
            let skinType: String
            let skinAge: DoubleOrInt
            let overallScore: DoubleOrInt
            let issues: FlexibleIssueScores
            let regions: FlexibleRegionScores
            let recommendations: [String]
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
            recommendations: analysisJSON.recommendations
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
            上次分析结果（(daysAgo(from: previous.analyzedAt))天前）：
            - 肤质：(previous.skinType.displayName)
            - 皮肤年龄：(previous.skinAge)岁
            - 综合评分：(previous.overallScore)/100
            - 主要问题：痘痘(previous.issues.acne)/10，泛红(previous.issues.redness)/10，色斑(previous.issues.spots)/10
            
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

        ## 输出格式
        **仅返回JSON对象，不要包含任何其他文字、解释或markdown代码块标记。**
        所有数值必须是整数（不要使用小数）。
        """
    }
    
    private func daysAgo(from date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, days)
    }
}
