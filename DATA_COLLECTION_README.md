# SkinLab 数据收集与扩充指南

欢迎使用 SkinLab 数据收集系统！本指南将帮助你使用 **Claude in Chrome** 和其他 skills 快速扩充成分和产品数据库。

---

## 📚 文档导航

本项目包含以下数据收集相关文档：

1. **[DATA_SCRAPING_PLAN.md](./DATA_SCRAPING_PLAN.md)** - 完整的数据抓取方案
   - 当前数据状态分析
   - 数据源选择和评估
   - 字段映射表
   - 实施路线图

2. **[CHROME_SCRAPING_GUIDE.md](./CHROME_SCRAPING_GUIDE.md)** - Claude in Chrome 实操指南
   - 详细操作步骤
   - 提示词模板库
   - 批量抓取工作流
   - 时间估算和示例

3. **[data_validation.py](./data_validation.py)** - 数据验证和清洗脚本
   - JSON 格式验证
   - 数据清洗和标准化
   - 质量报告生成

---

## 🚀 快速开始（5 分钟入门）

### 第一步：了解需求

我们需要扩充两个数据库：

**成分数据库** (`SkinLab/Resources/Data/ingredients.json`)
- 当前规模：24 个成分
- 目标规模：100+ 个成分
- 关键字段：name, function, safetyRating, irritationRisk, benefits, warnings

**产品数据库** (`SkinLab/Resources/Data/products.json`)
- 当前规模：10 个产品
- 目标规模：50+ 个产品
- 关键字段：name, brand, category, ingredients, price, rating, reviewCount

### 第二步：选择数据源

**推荐的成分数据源：**
1. ⭐️⭐️⭐️⭐️⭐️ [INCI/CosIng](https://ec.europa.eu/growth/tools-databases/cosing/) - 欧盟官方，权威
2. ⭐️⭐️⭐️⭐️ [Paula's Choice](https://www.paulaschoice.com/ingredient-dictionary) - 易懂，适合用户展示

**推荐的产品数据源：**
1. ⭐️⭐️⭐️⭐️⭐️ [iHerb](https://www.iherb.com/) - 成分表完整，价格透明
2. ⭐️⭐️⭐️⭐️ [Sephora](https://www.sephora.com/) - 高端品牌，评价丰富

### 第三步：抓取你的第一个成分

1. 打开 Paula's Choice 成分页面：
   ```
   https://www.paulaschoice.com/ingredient-dictionary/ingredient-niacinamide.html
   ```

2. 启动 Claude in Chrome 扩展

3. 使用这个提示词：
   ```
   请从当前页面提取成分信息，按以下 JSON 格式输出：

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

   规则：
   1. name: 标准 INCI 名称
   2. function: 从 moisturizing/brightening/antiAging/acneFighting/soothing/exfoliating/sunProtection/preservative/fragrance/other 中选择
   3. irritationRisk: 映射为 none/low/medium/high
   4. benefits: 提取关键词列表
   5. 缺失字段用空字符串或空数组
   ```

4. 复制输出，保存到 Google Sheets 或本地文件

### 第四步：验证数据

运行验证脚本：
```bash
python3 data_validation.py \
  --input ingredients_raw.json \
  --output ingredients_clean.json \
  --type ingredient
```

---

## 📋 完整工作流程

### 阶段 1: 成分数据收集（预计 3-5 天）

#### 任务清单

- [ ] **准备工作**（1 小时）
  - [ ] 创建 Google Sheet: `ingredients_collection`
  - [ ] 准备 Top 100 成分 URL 列表
  - [ ] 设置数据质量检查清单

- [ ] **批量抓取**（2-3 天，每天 2 小时）
  - [ ] Batch 1: 保湿类成分（20 个）
  - [ ] Batch 2: 美白类成分（20 个）
  - [ ] Batch 3: 抗老类成分（20 个）
  - [ ] Batch 4: 祛痘类成分（20 个）
  - [ ] Batch 5: 其他功能成分（20 个）

- [ ] **数据清洗**（1 天）
  - [ ] 运行验证脚本
  - [ ] 修正错误
  - [ ] 补充缺失字段
  - [ ] 去重和标准化

- [ ] **质量检查**（半天）
  - [ ] 抽样 10% 人工核对
  - [ ] 生成质量报告
  - [ ] 最终审核

#### 详细步骤

见 [CHROME_SCRAPING_GUIDE.md](./CHROME_SCRAPING_GUIDE.md) 第二节

---

### 阶段 2: 产品数据收集（预计 3-5 天）

#### 任务清单

- [ ] **准备工作**（1 小时）
  - [ ] 创建 Google Sheet: `products_collection`
  - [ ] 选择 50 个目标产品（每类至少 5 个）
  - [ ] 准备产品 URL 列表

- [ ] **批量抓取**（2-3 天，每天 2 小时）
  - [ ] Cleanser: 5 个产品
  - [ ] Toner: 5 个产品
  - [ ] Serum: 10 个产品
  - [ ] Moisturizer: 10 个产品
  - [ ] Sunscreen: 5 个产品
  - [ ] Mask: 5 个产品
  - [ ] 其他: 10 个产品

- [ ] **成分匹配**（1 天）
  - [ ] 拆分成分表
  - [ ] 与成分词典匹配
  - [ ] 处理未匹配成分（补充或标记）

- [ ] **数据清洗**（1 天）
  - [ ] 运行验证脚本
  - [ ] 价格档位映射
  - [ ] 分类标准化

- [ ] **质量检查**（半天）
  - [ ] 验证成分表完整性
  - [ ] 核对价格和评分
  - [ ] 最终审核

#### 详细步骤

见 [CHROME_SCRAPING_GUIDE.md](./CHROME_SCRAPING_GUIDE.md) 第三节

---

## 🛠️ 工具和资源

### Claude in Chrome 提示词模板

**成分基础提取：**
```
提取成分信息，JSON 格式，字段：name, aliases, function, safetyRating, irritationRisk, benefits, warnings, sourceUrl
```

**产品基础提取：**
```
提取产品信息，JSON 格式，字段：name, brand, category, ingredients(完整), price, rating, reviewCount, imageUrl, productUrl, platform
```

更多模板见 [CHROME_SCRAPING_GUIDE.md](./CHROME_SCRAPING_GUIDE.md)

### 数据验证脚本

```bash
# 验证成分数据
python3 data_validation.py \
  --input ingredients_seed.json \
  --output ingredients.json \
  --type ingredient

# 验证产品数据
python3 data_validation.py \
  --input products_seed.json \
  --output products.json \
  --type product

# 严格模式（有错误时不输出）
python3 data_validation.py \
  --input data.json \
  --output clean.json \
  --type ingredient \
  --strict
```

### 数据源快捷链接

**成分数据源：**
- [CosIng 成分数据库](https://ec.europa.eu/growth/tools-databases/cosing/)
- [Paula's Choice 成分词典](https://www.paulaschoice.com/ingredient-dictionary)
- [PubChem](https://pubchem.ncbi.nlm.nih.gov/)

**产品数据源：**
- [iHerb 护肤品分类](https://www.iherb.com/c/skin-care)
- [Sephora 护肤品](https://www.sephora.com/shop/skin-care)

---

## 📊 进度跟踪

### 成分数据收集进度

| 功能分类 | 目标 | 已完成 | 进度 |
|---------|-----|-------|------|
| Moisturizing | 20 | 0 | ░░░░░░░░░░ 0% |
| Brightening | 20 | 0 | ░░░░░░░░░░ 0% |
| Anti-aging | 20 | 0 | ░░░░░░░░░░ 0% |
| Acne Fighting | 20 | 0 | ░░░░░░░░░░ 0% |
| Other | 20 | 0 | ░░░░░░░░░░ 0% |
| **总计** | **100** | **0** | **0%** |

### 产品数据收集进度

| 产品分类 | 目标 | 已完成 | 进度 |
|---------|-----|-------|------|
| Cleanser | 5 | 0 | ░░░░░░░░░░ 0% |
| Toner | 5 | 0 | ░░░░░░░░░░ 0% |
| Serum | 10 | 0 | ░░░░░░░░░░ 0% |
| Moisturizer | 10 | 0 | ░░░░░░░░░░ 0% |
| Sunscreen | 5 | 0 | ░░░░░░░░░░ 0% |
| Mask | 5 | 0 | ░░░░░░░░░░ 0% |
| Other | 10 | 0 | ░░░░░░░░░░ 0% |
| **总计** | **50** | **0** | **0%** |

_更新时间: 2025-12-24_

---

## ✅ 数据质量标准

### 成分数据质量要求

- ✅ 必需字段完整率 > 95%
  - name, function, safetyRating, irritationRisk, benefits
- ✅ safetyRating 在 1-10 范围内
- ✅ function 符合枚举值
- ✅ irritationRisk 符合枚举值（none/low/medium/high）
- ✅ benefits 至少 1 项
- ✅ sourceUrl 完整且可访问

### 产品数据质量要求

- ✅ 必需字段完整率 > 95%
  - id, name, brand, category, ingredients
- ✅ 成分表完整（至少 5 个成分）
- ✅ 成分匹配率 > 80%
- ✅ category 符合枚举值
- ✅ priceRange 符合枚举值
- ✅ averageRating 在 0-5 范围内
- ✅ productUrl 完整且可访问

---

## 🚨 常见问题和解决方案

### Q1: Claude in Chrome 输出的成分表被截断了怎么办？

**解决方案**：使用分段提取
```
请分两步提取成分表：
第一步：提取前 20 个成分
第二步：提取剩余成分（从第 21 个开始）
最后合并成完整字符串
```

### Q2: 数据源的分类和我们的枚举值不匹配怎么办？

**解决方案**：验证脚本会自动映射常见值，如：
- "face wash" → "cleanser"
- "anti-aging" → "antiAging"
- "solvent" → "other"

如果无法自动映射，手动修正或添加映射规则到 `data_validation.py`

### Q3: 有些成分在词典中找不到怎么办？

**解决方案**：
1. 从 PubChem 或 CAS 查找同义词
2. 使用占位数据（function: "other", safetyRating: 5）
3. 标记为待补充，后续人工完善

### Q4: 抓取数据是否合法？

**重要**：
- ⚠️ 必须确认目标网站 ToS 允许
- ⚠️ 尊重 robots.txt
- ⚠️ 避免高频请求
- ⚠️ 优先使用官方 API 或商务授权

见 [DATA_SCRAPING_PLAN.md](./DATA_SCRAPING_PLAN.md) 第七节

---

## 📈 成功指标

完成数据收集后，我们期望达到：

### 数据规模
- ✅ 成分数据库：100+ 成分（当前 24）
- ✅ 产品数据库：50+ 产品（当前 10）

### 数据质量
- ✅ 关键字段完整率 > 95%
- ✅ 数据准确性：抽样验证错误率 < 5%
- ✅ 成分标准化：符合 INCI 命名 > 90%

### 用户体验
- ✅ OCR 识别成功率提升 20%+
- ✅ AI 分析准确性提升 15%+
- ✅ 产品推荐相关性显著提升

---

## 🔄 数据更新和维护

### 定期更新计划

**每月：**
- 补充 10-20 个新成分
- 更新 5-10 个产品信息
- 修正用户反馈的错误

**每季度：**
- 全面质检
- 更新评分和评价数量
- 清理过期产品

**每年：**
- 数据库重构和优化
- 扩展新的产品类别
- 引入新的数据源

### 贡献指南

欢迎贡献数据！请遵循以下流程：

1. Fork 项目
2. 创建数据分支：`git checkout -b data/add-ingredients`
3. 按照模板添加数据
4. 运行验证脚本确保质量
5. 提交 Pull Request

---

## 📞 需要帮助？

如果遇到问题，请参考：

1. **详细文档**：
   - [DATA_SCRAPING_PLAN.md](./DATA_SCRAPING_PLAN.md) - 完整方案
   - [CHROME_SCRAPING_GUIDE.md](./CHROME_SCRAPING_GUIDE.md) - 操作指南

2. **技术支持**：
   - 查看 [AGENTS.md](./AGENTS.md) 了解项目架构
   - 查看现有数据文件示例

3. **反馈和建议**：
   - 提交 GitHub Issue
   - 联系项目维护者

---

## 🎯 下一步行动

准备好开始了吗？

1. ✅ 阅读 [DATA_SCRAPING_PLAN.md](./DATA_SCRAPING_PLAN.md) 了解完整方案
2. ✅ 阅读 [CHROME_SCRAPING_GUIDE.md](./CHROME_SCRAPING_GUIDE.md) 学习操作步骤
3. ✅ 创建 Google Sheet 准备数据收集
4. ✅ 抓取你的第一个成分/产品
5. ✅ 运行 `data_validation.py` 验证数据
6. ✅ 开始批量收集！

---

**祝你数据收集顺利！** 🎉

_最后更新: 2025-12-24_
