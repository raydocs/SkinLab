# Claude in Chrome 数据抓取操作指南

## 快速开始

本指南提供使用 Claude in Chrome 抓取护肤品成分和产品数据的详细步骤和提示词模板。

---

## 一、准备工作

### 1.1 安装扩展
1. 确认已安装 **Claude in Chrome** 扩展
2. 登录 Claude 账号
3. 确认扩展权限已启用

### 1.2 准备数据收集表格

创建 Google Sheets 或本地 CSV，包含以下列：

**成分数据表：**
| name | aliases | function | safetyRating | irritationRisk | benefits | warnings | sourceUrl | extractedAt |
|------|---------|----------|--------------|----------------|----------|----------|-----------|-------------|

**产品数据表：**
| name | brand | category | ingredients | price | rating | reviewCount | imageUrl | productUrl | platform | extractedAt |
|------|-------|----------|-------------|-------|--------|-------------|----------|------------|----------|-------------|

---

## 二、成分数据抓取

### 2.1 从 Paula's Choice 抓取成分

#### 步骤 1：导航到成分页面
```
示例 URL：
https://www.paulaschoice.com/ingredient-dictionary/ingredient-niacinamide.html
https://www.paulaschoice.com/ingredient-dictionary/ingredient-retinol.html
```

#### 步骤 2：启动 Claude
1. 点击 Chrome 扩展图标
2. 点击 "Use this page"

#### 步骤 3：使用提示词模板

**基础提取模板：**
```
请从当前页面提取成分信息，严格按以下 JSON 格式输出：

{
  "name": "",
  "aliases": [],
  "function": "",
  "safetyRating": "",
  "irritationRisk": "",
  "benefits": [],
  "warnings": [],
  "sourceUrl": ""
}

提取规则：
1. name: 使用标准 INCI 名称
2. aliases: 提取所有同义词，转为小写
3. function: 选择最主要的功能类别（moisturizing/brightening/antiAging/acneFighting/soothing/exfoliating/sunProtection/preservative/fragrance/other）
4. safetyRating: 如果有评分，转换为 1-10 的数值
5. irritationRisk: 映射为 none/low/medium/high
6. benefits: 提取关键词列表，每项不超过 5 个单词
7. warnings: 只提取明确的禁忌/注意事项
8. sourceUrl: 填入当前页面 URL

如果字段缺失，使用空字符串或空数组，不要推测。
```

#### 步骤 4：验证输出

检查清单：
- [ ] JSON 格式正确（可用 JSONLint 验证）
- [ ] name 字段非空
- [ ] function 在允许的枚举值内
- [ ] sourceUrl 完整
- [ ] benefits/warnings 为数组格式

#### 示例输出：

```json
{
  "name": "Niacinamide",
  "aliases": ["vitamin b3", "nicotinamide"],
  "function": "brightening",
  "safetyRating": "9",
  "irritationRisk": "low",
  "benefits": ["brightening", "pore minimizing", "oil control", "barrier repair", "anti-inflammatory"],
  "warnings": [],
  "sourceUrl": "https://www.paulaschoice.com/ingredient-dictionary/ingredient-niacinamide.html"
}
```

### 2.2 从 INCI/CosIng 抓取官方数据

#### 步骤 1：搜索成分
```
URL: https://ec.europa.eu/growth/tools-databases/cosing/
搜索示例: "Hyaluronic Acid"
```

#### 步骤 2：使用官方数据提示词

```
请从当前 CosIng 页面提取官方成分信息：

{
  "name": "",           // INCI Name 字段
  "casNumber": "",      // CAS Number
  "einecs": "",         // EINECS/ELINCS
  "function": "",       // Functions 字段（选择主要功能）
  "restrictions": "",   // Restrictions 信息
  "sourceUrl": ""
}

注意：
- function 从列表中选择最主要的一个
- restrictions 如果有，完整提取
- 保持官方术语的原始英文
```

### 2.3 批量成分抓取工作流

```
批量处理流程（Top 100 成分）：

1. 准备 URL 列表
   - 创建 Excel/CSV：ingredient_urls.csv
   - 列：ingredientName, url

2. 分批处理（每批 10 个）
   - Batch 1: 保湿类成分（Hyaluronic Acid, Glycerin, etc.）
   - Batch 2: 美白类成分（Niacinamide, Vitamin C, etc.）
   - Batch 3: 抗老类成分（Retinol, Peptides, etc.）
   ...

3. 每批次操作
   a. 打开 URL
   b. 使用统一提示词
   c. 复制输出到表格
   d. 休息 2-3 分钟

4. 质检（每批抽样 2 个）
   - 人工核对原网页
   - 验证字段完整性

5. 合并到 ingredients_seed.json
```

---

## 三、产品数据抓取

### 3.1 从 iHerb 抓取产品

#### 步骤 1：导航到产品页面
```
示例 URL：
https://www.iherb.com/pr/cerave-moisturizing-cream-16-oz-453-g/70826
```

#### 步骤 2：使用产品提取模板

```
请从当前 iHerb 产品页面提取以下信息，输出 JSON 格式：

{
  "name": "",
  "brand": "",
  "category": "",
  "ingredients": "",
  "price": 0,
  "rating": 0,
  "reviewCount": 0,
  "imageUrl": "",
  "productUrl": "",
  "platform": "iHerb"
}

提取规则：
1. name: 产品全名（不要截断）
2. brand: 品牌名
3. category: 从以下选择（cleanser/toner/serum/moisturizer/sunscreen/mask/exfoliant/eyeCream/other）
4. ingredients: **完整成分表**，保留原始格式，用逗号分隔
5. price: 仅数值（美元），不要货币符号
6. rating: 评分（0-5，保留一位小数）
7. reviewCount: 评价数量（整数）
8. imageUrl: 主图 URL
9. productUrl: 当前页面 URL

**重要**：ingredients 字段必须包含完整成分表，不要省略或截断。
```

#### 步骤 3：成分表验证

检查清单：
- [ ] ingredients 字段完整（至少 5 个成分）
- [ ] 成分用逗号分隔
- [ ] 没有截断（检查最后一个成分是否完整）
- [ ] 价格为有效数值
- [ ] 评分在 0-5 范围内

#### 示例输出：

```json
{
  "name": "CeraVe Moisturizing Cream",
  "brand": "CeraVe",
  "category": "moisturizer",
  "ingredients": "Water, Glycerin, Cetearyl Alcohol, Caprylic/Capric Triglyceride, Cetyl Alcohol, Dimethicone, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Behentrimonium Methosulfate, Sodium Lauroyl Lactylate, Sodium Hyaluronate, Cholesterol, Phenoxyethanol, Disodium EDTA, Dipotassium Phosphate, Tocopherol, Phytosphingosine, Xanthan Gum, Polysorbate 20, Ethylhexylglycerin",
  "price": 16.99,
  "rating": 4.7,
  "reviewCount": 3421,
  "imageUrl": "https://s3.images-iherb.com/cve/cve00001/y/1.jpg",
  "productUrl": "https://www.iherb.com/pr/cerave-moisturizing-cream-16-oz-453-g/70826",
  "platform": "iHerb"
}
```

### 3.2 从 Sephora 抓取产品

#### 步骤 1：导航到产品页面
```
示例 URL：
https://www.sephora.com/product/the-ordinary-niacinamide-10-zinc-1-P427417
```

#### 步骤 2：使用 Sephora 提示词

```
请从当前 Sephora 产品页面提取信息（JSON 格式）：

{
  "name": "",
  "brand": "",
  "category": "",
  "ingredients": "",
  "price": 0,
  "rating": 0,
  "reviewCount": 0,
  "imageUrl": "",
  "productUrl": "",
  "platform": "Sephora"
}

注意：
1. Sephora 的成分表通常在 "Ingredients" 或 "What it is formulated WITHOUT" 附近
2. 价格可能有促销价，使用当前显示价格
3. category 推断（查看 "Product type" 或面包屑导航）
```

### 3.3 批量产品抓取工作流

```
批量处理流程（50 个产品）：

1. 选择产品类别
   - Cleanser: 5 个
   - Toner: 5 个
   - Serum: 10 个
   - Moisturizer: 10 个
   - Sunscreen: 5 个
   - Mask: 5 个
   - 其他: 10 个

2. 每个类别操作
   a. 在 iHerb/Sephora 搜索类别
   b. 选择评分高、评价多的产品（rating > 4.0, reviews > 100）
   c. 记录 URL
   d. 使用提示词提取

3. 数据验证
   - 检查成分表完整性
   - 核对价格合理性
   - 验证分类正确性

4. 保存到 products_seed.json
```

---

## 四、高级技巧

### 4.1 处理复杂成分表

**问题**：成分表太长，Claude 可能截断

**解决方案**：分段提取
```
请分两步提取成分表：

第一步，提取前 20 个成分：
[等待输出]

第二步，提取剩余成分（从第 21 个开始）：
[等待输出]

最后，合并成完整的逗号分隔字符串。
```

### 4.2 处理多语言页面

**问题**：页面包含中文/日文/韩文

**提示词调整**：
```
注意：当前页面包含多语言信息。

提取规则：
1. name: 优先使用英文名称，如无英文则使用原语言
2. ingredients: 如果同时有英文和中文成分表，优先提取**英文**成分表
3. benefits/warnings: 可以提取中文，但使用简洁的关键词
```

### 4.3 批量数据合并

使用 Claude Desktop 或 Claude Code 合并多个 JSON：

```
我有 10 个成分数据的 JSON 对象，请帮我合并成一个标准的 ingredients.json 格式：

{
  "ingredient-key-1": { ... },
  "ingredient-key-2": { ... },
  ...
}

规则：
1. key 使用小写成分名（去除空格和特殊字符）
2. 去重（如果 name 相同，保留第一个）
3. 验证所有字段完整性

原始数据：
[粘贴 10 个 JSON 对象]
```

---

## 五、质检和验证

### 5.1 抽样验证清单

每批次抽取 10% 样本，执行以下检查：

**成分数据：**
- [ ] name 是标准 INCI 名称
- [ ] function 在允许的枚举值内
- [ ] safetyRating 在 1-10 范围
- [ ] irritationRisk 为 none/low/medium/high
- [ ] benefits 为数组格式
- [ ] sourceUrl 可访问

**产品数据：**
- [ ] ingredients 完整（手动核对原网页）
- [ ] 成分数量 > 5
- [ ] price 合理（< $500）
- [ ] rating 在 0-5 范围
- [ ] category 映射正确
- [ ] productUrl 可访问

### 5.2 常见错误和修正

| 错误 | 原因 | 修正方法 |
|------|------|---------|
| 成分表截断 | Claude 输出长度限制 | 使用分段提取 |
| function 不在枚举内 | 数据源使用其他术语 | 手动映射或使用 "other" |
| safetyRating 为文本 | 数据源无数值评分 | 人工评估或使用默认值 5 |
| aliases 为空 | 页面无同义词信息 | 从其他来源补充 |
| price 包含货币符号 | 提取规则未生效 | 手动去除符号 |

---

## 六、数据导出和保存

### 6.1 导出为 JSON

从 Google Sheets 导出：
```
1. 文件 → 下载 → CSV
2. 使用 Claude Code 或脚本转换为 JSON：

请将以下 CSV 转换为 ingredients.json 格式：

[粘贴 CSV 内容]

输出格式：
{
  "ingredient-key": {
    "name": "...",
    "function": "...",
    ...
  }
}
```

### 6.2 保存到项目

```bash
# 将生成的 JSON 保存到项目
cp ingredients_seed.json SkinLab/Resources/Data/ingredients.json
cp products_seed.json SkinLab/Resources/Data/products.json

# 验证 JSON 格式
python3 -m json.tool ingredients.json
python3 -m json.tool products.json
```

---

## 七、时间估算

### 单个成分
- 打开页面：10 秒
- Claude 处理：20 秒
- 复制验证：10 秒
- **总计**：~40 秒/个

### 单个产品
- 打开页面：10 秒
- Claude 处理：30 秒（成分表长）
- 验证成分完整性：20 秒
- **总计**：~60 秒/个

### 批量估算
- **100 个成分**：~1.5 小时（含休息和质检）
- **50 个产品**：~1.5 小时（含休息和质检）
- **质检和修正**：~1 小时
- **总计**：~4 小时

---

## 八、注意事项

### 8.1 合规提醒
⚠️ 在抓取前务必确认：
1. 目标网站 ToS 允许内容提取
2. 数据使用符合版权要求
3. 尊重网站 robots.txt
4. 避免高频请求（每批次休息 5-10 分钟）

### 8.2 数据隐私
- 不要提取用户评论中的个人信息
- 产品 URL 可以保留（公开信息）
- 记录 sourceUrl 便于追溯

### 8.3 质量优先
- 宁可慢一点，也要保证准确性
- 有疑问的数据标记为待验证
- 保留原始抓取数据备份

---

## 九、快速参考

### 常用提示词速查

**成分基础提取：**
```
提取成分信息，JSON 格式，字段：name, aliases, function, safetyRating, irritationRisk, benefits, warnings, sourceUrl
```

**产品基础提取：**
```
提取产品信息，JSON 格式，字段：name, brand, category, ingredients(完整), price, rating, reviewCount, imageUrl, productUrl, platform
```

**分段提取成分表：**
```
成分表太长，分两步：1) 前20个成分 2) 剩余成分
```

**多语言处理：**
```
优先英文，成分表用英文，关键词可用中文
```

---

## 十、示例工作流（完整演示）

### 抓取 10 个成分的完整流程

```
9:00 - 准备
  - 创建 Google Sheet: ingredients_batch1
  - 准备 URL 列表（10 个成分）

9:05 - 开始抓取
  Batch 1 (成分 1-5):
    - Niacinamide
    - Hyaluronic Acid
    - Retinol
    - Vitamin C
    - Glycerin

  每个成分：
    1. 打开 Paula's Choice 页面
    2. 启动 Claude in Chrome
    3. 使用基础提取模板
    4. 复制到 Sheet
    5. 标记 "extracted"

9:25 - 休息 5 分钟

9:30 - 继续抓取
  Batch 2 (成分 6-10):
    - Ceramide
    - Centella Asiatica
    - Salicylic Acid
    - Peptides
    - Squalane

9:50 - 质检
  - 抽样 2 个成分（Niacinamide, Retinol）
  - 核对原网页
  - 验证字段完整性

10:00 - 数据清洗
  - 统一 function 格式
  - safetyRating 转为数值
  - 去除重复 aliases

10:10 - 导出 JSON
  - 下载 CSV
  - 转换为 ingredients.json 格式
  - 验证 JSON 格式

10:15 - 保存
  - 备份到 ingredients_seed_batch1.json
  - 合并到主 ingredients.json

总耗时：1 小时 15 分钟（10 个成分）
```

---

**最后更新**: 2025-12-24
**版本**: 1.0
