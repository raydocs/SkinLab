# SkinLab 数据抓取与扩充方案

## 一、当前状态分析

### 1.1 现有数据文件
- **成分数据库**: `SkinLab/Resources/Data/ingredients.json`
  - 格式：字典结构，key 为小写成分名
  - 字段：name, function, safetyRating, irritationRisk, benefits, warnings
  - 规模：约 24 个成分
  - **问题**：未被代码实际加载使用

- **产品数据库**: `SkinLab/Resources/Data/products.json`
  - 格式：对象数组
  - 字段：id, name, brand, category, skinTypes, concerns, priceRange, ingredients(字符串数组), effectiveRate, sampleSize
  - 规模：10 个产品
  - **问题**：未被代码实际加载；ingredients 为字符串数组，与 Product 模型不匹配

### 1.2 代码实现状况
- `IngredientDatabase`（SkinLab/Core/Utils/IngredientOCR.swift）：**硬编码**成分数据
- `ProductsView`（SkinLab/Features/Products/Views/ProductsView.swift）：使用**静态硬编码** RealProductData
- 结论：JSON 文件存在但**未被使用**，需要实现加载机制

### 1.3 模型不匹配问题
- `ingredients.json` 的 `function` 包含 `"solvent"`，但 `IngredientFunction` 枚举无此值
- `products.json` 的 `ingredients` 是字符串数组，而 `Product.ingredients` 期望 `[Ingredient]` 对象数组

---

## 二、数据抓取方案

### 2.1 成分数据抓取（目标：Top 100 常见护肤品成分）

#### 数据源选择（优先级排序）
1. **INCI/CosIng（欧盟官方）** ⭐️⭐️⭐️⭐️⭐️
   - 优势：权威、标准化、免费
   - 用途：主词典、INCI 名称规范化
   - URL: https://ec.europa.eu/growth/tools-databases/cosing/

2. **Paula's Choice 成分词典** ⭐️⭐️⭐️⭐️
   - 优势：通俗易懂、适合用户展示
   - 注意：需核对版权和使用条款
   - URL: https://www.paulaschoice.com/ingredient-dictionary

3. **CosDNA** ⭐️⭐️⭐️
   - 优势：成分评分系统、数据丰富
   - 注意：有使用限制，优先考虑商务授权
   - URL: https://www.cosdna.com/

4. **PubChem/CAS**
   - 用途：化学信息、同义词映射
   - URL: https://pubchem.ncbi.nlm.nih.gov/

#### 成分字段映射表

| 数据源字段 | 目标模型字段 | 规范化规则 | 备注 |
|-----------|------------|----------|------|
| Ingredient Name / INCI | `Ingredient.name` | 保留官方 INCI 名 | 主键 |
| Synonyms / Aliases | `Ingredient.aliases` | 全部小写 + 去标点 | OCR 归一化 |
| Function / Category | `Ingredient.function` | 映射表转换 | 见功能映射表 |
| Safety / Rating | `Ingredient.safetyRating` | 归一到 1-10 | 超界 clamp |
| Irritation / Irritancy | `Ingredient.irritationRisk` | 映射到枚举值 | none/low/medium/high |
| Benefits / Description | `Ingredient.benefits` | 提取关键词列表 | 数组格式 |
| Warnings / Notes | `Ingredient.warnings` | 列表化 | 可为 nil |
| Concentration | `Ingredient.concentration` | 纯文本保留 | 可选字段 |
| Source URL | metadata | 记录来源 | 审计用 |

#### 功能类别映射表

| 数据源分类 | IngredientFunction 枚举 |
|-----------|----------------------|
| Humectant / Emollient / Occlusive | `.moisturizing` |
| Brightening / Whitening | `.brightening` |
| Anti-aging / Repair | `.antiAging` |
| Anti-acne / Sebum control | `.acneFighting` |
| Soothing / Anti-inflammatory | `.soothing` |
| Exfoliant / AHA / BHA | `.exfoliating` |
| UV filter / Sunscreen | `.sunProtection` |
| Preservative | `.preservative` |
| Fragrance / Parfum | `.fragrance` |
| Solvent / Vehicle | `.other` ⚠️ |

> ⚠️ **注意**：`solvent` 当前在枚举中不存在，短期映射为 `.other`，建议未来扩展枚举

---

### 2.2 产品数据抓取（目标：50-100 个真实产品）

#### 数据源选择
1. **iHerb** ⭐️⭐️⭐️⭐️⭐️
   - 优势：成分表完整、多语言、价格透明
   - 适合：国际品牌、有机产品
   - URL: https://www.iherb.com/

2. **Sephora** ⭐️⭐️⭐️⭐️
   - 优势：高端品牌、评价丰富
   - URL: https://www.sephora.com/

3. **美丽修行 App**
   - 优势：中文数据、成分分析
   - 注意：需确认使用授权

#### 产品字段映射表

| 数据源字段 | 目标模型字段 | 规范化规则 | 备注 |
|-----------|------------|----------|------|
| Product Name | `Product.name` | 原文保留 | |
| Brand | `Product.brand` | 原文保留 | |
| Category | `Product.category` | 关键词映射 | 见分类映射表 |
| Ingredient List | `Product.ingredients` | 拆分→归一化→匹配词典 | 复杂流程 |
| Price | `Product.priceRange` | 价格→档位映射 | |
| Rating | `Product.averageRating` | 0-5 浮点数 | |
| Review Count | `Product.sampleSize` | 整数 | |
| Product URL | `PurchaseLink.url` | 原链接保留 | |
| Platform | `PurchaseLink.platform` | 固定值 | iHerb/Sephora |
| Image URL | `Product.imageUrl` | 原文保留 | 可选 |

#### 产品分类映射表

| 关键词（数据源） | ProductCategory 枚举 |
|----------------|---------------------|
| 洁面/cleanser/face wash | `.cleanser` |
| 化妆水/toner/essence | `.toner` |
| 精华/serum | `.serum` |
| 面霜/cream/moisturizer | `.moisturizer` |
| 防晒/sunscreen/spf | `.sunscreen` |
| 面膜/mask | `.mask` |
| 去角质/exfoliant/acid | `.exfoliant` |
| 眼霜/eye cream | `.eyeCream` |

#### 价格档位映射规则

```swift
// PriceRange 映射逻辑
func mapPriceRange(_ price: Double) -> PriceRange {
    switch price {
    case 0..<50: return .budget
    case 50..<150: return .midRange
    case 150..<300: return .premium
    default: return .luxury
    }
}
```

---

## 三、数据规范化流程

### 3.1 成分数据规范化管道

```
抓取原始页面
    ↓
存储 raw_html + source_url + timestamp
    ↓
提取结构化字段
    ↓
成分名称规范化
  - 转小写
  - 去除标点符号
  - 别名映射
    ↓
功能分类映射
  - function → IngredientFunction 枚举
    ↓
安全性评级归一化
  - safetyRating → 1-10（clamp）
  - irritationRisk → none/low/medium/high
    ↓
生成 ingredients_seed.json
    ↓
质检（抽样 10%）
    ↓
更新 ingredients.json
```

### 3.2 产品数据规范化管道

```
抓取产品页面
    ↓
提取基础信息（name, brand, category, price, rating）
    ↓
成分表拆分
  - 统一分隔符（, ， ; 、）
  - 去除百分比和括号说明
  - 转小写 + trim
    ↓
成分匹配
  - 使用 Ingredient.aliases 匹配词典
  - 未匹配：创建占位 Ingredient
    ↓
价格档位映射
    ↓
分类映射
    ↓
生成 products_seed.json
    ↓
质检（核对成分匹配率）
    ↓
更新 products.json
```

### 3.3 数据质检清单

- [ ] 成分名称是否标准化（INCI 格式）
- [ ] function 是否成功映射到枚举值
- [ ] safetyRating 在 1-10 范围内
- [ ] irritationRisk 为有效枚举值
- [ ] benefits/warnings 为数组格式
- [ ] 产品成分匹配率 > 80%
- [ ] 价格档位映射正确
- [ ] sourceUrl 完整记录
- [ ] 无重复数据

---

## 四、使用 Claude in Chrome 抓取数据

### 4.1 合规前提

⚠️ **重要**：在抓取前必须确认：
1. 目标网站 Terms of Service (ToS) 允许内容抽取
2. robots.txt 未禁止访问
3. 数据使用符合版权和商业用途许可
4. **不建议在无授权情况下批量抓取**

### 4.2 单页抓取操作步骤

#### 步骤 1：准备工作
1. 安装 Claude in Chrome 扩展
2. 准备目标 URL 列表（Top 100 成分/50 个产品）
3. 准备数据收集表格（Google Sheets 或本地 CSV）

#### 步骤 2：打开目标页面
```
示例：Paula's Choice 成分词典页面
https://www.paulaschoice.com/ingredient-dictionary/ingredient-niacinamide.html
```

#### 步骤 3：启动 Claude in Chrome
1. 点击浏览器扩展图标
2. 选择 "Use this page"
3. 等待页面内容加载

#### 步骤 4：输入结构化提取提示词

**成分数据抽取提示词模板：**
```
请从当前页面提取成分信息，严格按以下 JSON 结构输出，不要推测或填充缺失数据：

{
  "name": "",           // INCI 标准名称
  "aliases": [],        // 所有同义词/别名
  "function": "",       // 功能分类（如 moisturizing, brightening）
  "safetyRating": "",   // 安全评级（1-10 或文本）
  "irritationRisk": "", // 刺激性（none/low/medium/high）
  "benefits": [],       // 功效列表
  "warnings": [],       // 警告/注意事项
  "sourceUrl": ""       // 当前页面URL
}

规则：
1. 如果字段缺失，使用空字符串或空数组
2. benefits 提取关键词，不要完整句子
3. warnings 只提取明确的禁忌/注意事项
4. 保留原始英文术语
```

**产品数据抽取提示词模板：**
```
请从当前产品页面提取以下信息，严格按 JSON 格式输出：

{
  "name": "",
  "brand": "",
  "category": "",       // 产品类型（cleanser/serum/moisturizer等）
  "ingredients": "",    // 完整成分表（逗号分隔字符串）
  "price": 0,           // 数值（美元）
  "rating": 0,          // 评分 0-5
  "reviewCount": 0,     // 评价数量
  "imageUrl": "",
  "productUrl": "",     // 当前页面URL
  "platform": ""        // iHerb/Sephora/etc
}

规则：
1. ingredients 保留完整成分表，不要截断
2. price 仅数值，不要货币符号
3. rating 保留一位小数
4. 缺失字段填 null 或 0
```

#### 步骤 5：验证和保存输出
1. 检查 JSON 格式是否正确
2. 验证关键字段是否完整
3. 复制到本地文件或表格
4. 记录抓取时间和来源

#### 步骤 6：批量处理建议
```
批量抓取流程：
1. 整理待抓取 URL 列表（100 个成分）
2. 每 10 个 URL 为一批
3. 使用统一提示词模板
4. 每批次后休息 5-10 分钟（避免高频请求）
5. 抽样 10% 进行人工质检
6. 合并数据到 ingredients_seed.json
```

### 4.3 数据抽取示例

#### 示例 1：从 Paula's Choice 抽取 Niacinamide

**输入提示词：**
```
请从当前页面提取 Niacinamide 成分信息，按照前面的 JSON 模板输出。
```

**预期输出：**
```json
{
  "name": "Niacinamide",
  "aliases": ["vitamin b3", "nicotinamide"],
  "function": "brightening",
  "safetyRating": "9",
  "irritationRisk": "low",
  "benefits": ["brightening", "pore minimizing", "oil control", "barrier repair"],
  "warnings": [],
  "sourceUrl": "https://www.paulaschoice.com/ingredient-dictionary/ingredient-niacinamide.html"
}
```

#### 示例 2：从 iHerb 抽取产品

**输入提示词：**
```
请提取这个 CeraVe 保湿霜的产品信息，按照产品数据模板输出。
```

**预期输出：**
```json
{
  "name": "CeraVe Moisturizing Cream",
  "brand": "CeraVe",
  "category": "moisturizer",
  "ingredients": "Water, Glycerin, Cetearyl Alcohol, Caprylic/Capric Triglyceride, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Dimethicone, Behentrimonium Methosulfate, Sodium Lauroyl Lactylate, Sodium Hyaluronate, Cholesterol, Phenoxyethanol, Disodium EDTA, Dipotassium Phosphate, Tocopherol, Phytosphingosine, Xanthan Gum, Polysorbate 20, Ethylhexylglycerin",
  "price": 16.99,
  "rating": 4.7,
  "reviewCount": 3421,
  "imageUrl": "https://s3.images-iherb.com/cve/cve00001/y/1.jpg",
  "productUrl": "https://www.iherb.com/pr/cerave-moisturizing-cream-16-oz-453-g/70826",
  "platform": "iHerb"
}
```

---

## 五、实施路线图

### Phase 1: 基础设施准备（1-2 天）
- [ ] 创建 `ingredients_seed.json` 和 `products_seed.json` 模板
- [ ] 编写数据验证脚本（验证 JSON 格式和字段完整性）
- [ ] 准备 URL 列表（Top 100 成分 + 50 个产品）
- [ ] 设置 Google Sheets 数据收集表

### Phase 2: 成分数据抓取（3-5 天）
- [ ] 从 INCI/CosIng 抓取前 50 个成分（基础款）
- [ ] 从 Paula's Choice 补充详细说明和功效
- [ ] 数据规范化和清洗
- [ ] 质检和修正（抽样 10%）
- [ ] 生成 `ingredients_seed.json`

### Phase 3: 产品数据抓取（3-5 天）
- [ ] 从 iHerb 抓取 30 个产品
- [ ] 从 Sephora 抓取 20 个产品
- [ ] 成分表拆分和匹配
- [ ] 数据规范化
- [ ] 生成 `products_seed.json`

### Phase 4: 代码集成（2-3 天）
- [ ] 实现 JSON 加载机制
  - IngredientDatabase 从 ingredients.json 加载
  - ProductsView 从 products.json 加载
- [ ] 处理模型不匹配问题
  - 扩展 IngredientFunction 枚举（添加 `.solvent`）
  - 实现字符串 → Ingredient 对象转换
- [ ] 单元测试
- [ ] 集成测试

### Phase 5: 数据扩充迭代（持续）
- [ ] 收集用户反馈
- [ ] 补充缺失成分
- [ ] 更新产品数据
- [ ] 定期质检和清理

---

## 六、技术实现要点

### 6.1 JSON 加载机制

```swift
// IngredientDatabase 改造示例
actor IngredientDatabase {
    private var ingredients: [String: IngredientInfo] = [:]

    init() {
        // 1. 尝试从 Bundle 加载 ingredients.json
        if let loadedIngredients = loadIngredientsFromJSON() {
            self.ingredients = loadedIngredients
        } else {
            // 2. 加载失败，使用硬编码默认数据
            self.ingredients = hardcodedIngredients()
        }
    }

    private func loadIngredientsFromJSON() -> [String: IngredientInfo]? {
        guard let url = Bundle.main.url(forResource: "ingredients", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: IngredientSeed].self, from: data) else {
            return nil
        }

        // 转换 IngredientSeed → IngredientInfo
        return decoded.mapValues { seed in
            IngredientInfo(
                name: seed.name,
                function: mapFunction(seed.function),
                safetyRating: seed.safetyRating,
                irritationRisk: mapIrritation(seed.irritationRisk),
                benefits: seed.benefits,
                warnings: seed.warnings
            )
        }
    }
}
```

### 6.2 成分字符串转对象映射

```swift
// ProductSeed → Product 转换
struct ProductSeed: Codable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let ingredients: [String]  // 字符串数组
    // ... 其他字段
}

extension ProductSeed {
    func toProduct(ingredientDB: IngredientDatabase) async -> Product {
        // 将字符串成分转换为 Ingredient 对象
        let ingredientObjects = await ingredients.asyncMap { name in
            await ingredientDB.lookup(name) ?? Ingredient.placeholder(name: name)
        }

        return Product(
            name: name,
            brand: brand,
            category: ProductCategory(rawValue: category) ?? .other,
            ingredients: ingredientObjects,
            // ...
        )
    }
}
```

---

## 七、注意事项和风险

### 7.1 法律和合规风险
- ⚠️ **必须**：确认数据源使用许可
- ⚠️ **避免**：无授权批量抓取
- ⚠️ **建议**：优先使用官方 API 或商务授权
- ⚠️ **记录**：保留 sourceUrl 和抓取时间戳，便于审计

### 7.2 数据质量风险
- 成分匹配率可能低于 80%（需人工补充）
- 不同数据源的分类标准不统一
- 评分系统差异（1-5 vs 1-10）
- 成分名称不一致（INCI vs 通用名）

### 7.3 技术风险
- JSON 文件过大影响性能（建议 < 1MB）
- 硬编码到 JSON 迁移可能引入 bug
- 枚举扩展需要重新编译

### 7.4 缓解措施
- 分批次小规模测试
- 建立数据版本控制
- 保留硬编码 fallback 机制
- 抽样质检 + 用户反馈迭代

---

## 八、成功指标

### 数据规模目标
- ✅ 成分数据库：100+ 成分
- ✅ 产品数据库：50+ 产品
- ✅ 成分匹配率：> 80%

### 质量目标
- ✅ 数据完整性：关键字段填充率 > 95%
- ✅ 准确性：抽样验证错误率 < 5%
- ✅ 标准化：符合 INCI 命名规范 > 90%

### 用户体验目标
- ✅ OCR 识别成功率提升 20%+
- ✅ AI 分析准确性提升 15%+
- ✅ 产品推荐相关性提升

---

## 附录

### A. 提示词模板库

见上文"四、使用 Claude in Chrome 抓取数据"部分

### B. 字段映射速查表

见上文"二、数据抓取方案"部分的映射表

### C. 数据源对比表

| 数据源 | 权威性 | 易用性 | 合规性 | 推荐度 |
|-------|-------|-------|-------|-------|
| INCI/CosIng | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ | 高 |
| Paula's Choice | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️ | 中高 |
| CosDNA | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | ⭐️⭐️ | 中 |
| iHerb | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | 高 |
| Sephora | ⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️ | 中高 |

---

**最后更新**: 2025-12-24
**版本**: 1.0
**维护者**: SkinLab Team
