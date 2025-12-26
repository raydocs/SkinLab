# SkinLab iOS App - AI Agent Guidelines

## 项目概述
SkinLab是一个AI驱动的皮肤分析与护肤品推荐应用。
- **核心理念**：用数据说话，让用户愿意分享
- **目标用户**：18-35岁注重护肤的用户
- **差异化**：效果验证引擎 + 皮肤双胞胎匹配 + 反软广承诺

## 技术栈
- **平台**: iOS 17+
- **语言**: Swift 5.9+
- **UI框架**: SwiftUI
- **架构**: MVVM + Clean Architecture
- **存储**: SwiftData
- **AI**: Gemini 3.0 Flash Vision API
- **图像处理**: Vision Framework

## 项目结构
```
SkinLab/
├── App/
│   ├── SkinLabApp.swift           # 应用入口
│   └── AppDelegate.swift          # 生命周期
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift
│   │   └── GeminiService.swift
│   ├── Storage/
│   │   ├── SwiftDataManager.swift
│   │   └── KeychainManager.swift
│   └── Utils/
│       ├── Extensions/
│       └── Helpers/
├── Features/
│   ├── Analysis/                  # 皮肤分析
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   ├── Tracking/                  # 效果追踪
│   ├── Products/                  # 产品库
│   ├── Profile/                   # 用户档案
│   └── Community/                 # 社区功能
├── UI/
│   ├── Components/                # 共享组件
│   └── Theme/                     # 主题配置
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    └── Data/
        ├── ingredients.json       # 成分数据库
        └── products.json          # 产品数据库
```

## 代码规范

### 命名规范
- 类型名：PascalCase (e.g., `SkinAnalysis`, `ProductViewModel`)
- 变量/函数：camelCase (e.g., `skinType`, `analyzeImage()`)
- 常量：camelCase (e.g., `maxRetryCount`)
- 协议：形容词或名词+able/Protocol (e.g., `Analyzable`, `DataStorable`)

### 文件组织
- 每个功能模块包含: Views/, ViewModels/, Models/, Services/
- 一个文件只包含一个主要类型
- 扩展放在同一文件或 Extensions/ 目录

### SwiftUI规范
```swift
// 视图结构示例
struct AnalysisResultView: View {
    // 1. 状态属性
    @StateObject private var viewModel: AnalysisViewModel
    @State private var showDetail = false
    
    // 2. 环境变量
    @Environment(\.dismiss) private var dismiss
    
    // 3. 初始化器
    init(analysis: SkinAnalysis) {
        _viewModel = StateObject(wrappedValue: AnalysisViewModel(analysis: analysis))
    }
    
    // 4. body
    var body: some View {
        content
            .navigationTitle("分析结果")
    }
    
    // 5. 子视图（私有计算属性）
    private var content: some View { ... }
    private var scoreSection: some View { ... }
}

// 6. Preview
#Preview {
    AnalysisResultView(analysis: .mock)
}
```

### 错误处理
```swift
// 使用Result或async throws
func analyzeImage(_ image: UIImage) async throws -> SkinAnalysis

// 自定义错误枚举
enum AnalysisError: LocalizedError {
    case invalidImage
    case networkError(underlying: Error)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "图片无效"
        case .networkError(let error): return "网络错误: \(error.localizedDescription)"
        case .parseError: return "解析失败"
        }
    }
}
```

## 隐私要求

### 数据收集原则
- 最小化收集：只收集必要数据
- 明确告知：用户知道收集什么、为什么
- 用户控制：随时导出/删除

### 照片处理
- 用户照片不存储到自有服务器
- 仅在用户授权后调用Gemini API
- 分析完成后不保留API端数据
- 本地存储使用加密

### Info.plist 隐私说明
```xml
<key>NSCameraUsageDescription</key>
<string>用于拍摄面部照片进行皮肤分析</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>用于选择已有照片进行皮肤分析</string>
```

## 测试要求
- ViewModel必须有单元测试
- 关键业务逻辑测试覆盖
- UI关键路径有UI测试
- 目标覆盖率：60%+

## Git提交规范
```
feat: 新功能
fix: 修复bug
refactor: 重构
docs: 文档
test: 测试
style: 格式调整
chore: 构建/工具
```

## 核心模型定义

### SkinAnalysis
```swift
struct SkinAnalysis: Codable, Identifiable {
    let id: UUID
    let skinType: SkinType
    let skinAge: Int
    let overallScore: Int
    let issues: IssueScores
    let regions: RegionScores
    let recommendations: [String]
    let analyzedAt: Date
}
```

### UserProfile
```swift
struct UserProfile: Codable {
    let id: UUID
    var skinType: SkinType?
    var ageRange: AgeRange
    var concerns: [SkinConcern]
    var allergies: [String]
    var fingerprint: SkinFingerprint
}
```

### Product
```swift
struct Product: Codable, Identifiable {
    let id: UUID
    let name: String
    let brand: String
    let category: ProductCategory
    let ingredients: [Ingredient]
    let skinTypes: [SkinType]
    let concerns: [SkinConcern]
    let priceRange: PriceRange
}
```

## 可用的Skills
1. `gemini-skin-analysis` - AI皮肤分析
2. `photo-standardization` - 标准化拍照
3. `ingredient-scanner` - 成分扫描
4. `effect-tracking` - 效果追踪
5. `skin-matching` - 皮肤匹配
6. `product-recommendation` - 产品推荐

## 可用的Droids
1. `ios-architect` - 架构设计
2. `skin-ai-engineer` - AI功能
3. `ui-designer` - UI设计
4. `product-data-curator` - 产品数据
5. `privacy-guardian` - 隐私审查
6. `community-designer` - 社区功能

## 开发优先级
1. P0: AI皮肤分析核心功能
2. P0: 标准化拍照引导
3. P1: 成分扫描仪
4. P1: 28天效果追踪
5. P2: 皮肤双胞胎匹配
6. P2: 产品推荐引擎
7. P3: 社区分享功能
