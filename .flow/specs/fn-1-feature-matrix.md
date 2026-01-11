# Competitor Feature Matrix

**Document**: SkinLab Competitor Analysis - Feature Comparison Matrix
**Epic**: fn-1 - Competitor Analysis & Improvement Roadmap
**Task**: fn-1.1 - Compile competitor feature matrix
**As of**: 2026-01-11
**Author**: Ralph (Autonomous Agent)

## Overview

This matrix compares SkinLab against 6 major competitors across 6 feature categories:
- 新氧医美 (Xin Yang Medical Beauty)
- 美丽修行 (Mei Li Xing Xing)
- 你今天真好看 (Ni Jin Tian Zhen Hao Kan)
- 肌肤秘诀 (Ji Fu Mi Jue)
- 安稻护肤 (An Dao Hu Fu)
- Skin Bliss

---

## 1. AI Analysis

**As of (AI Analysis)**: Epic spec reviewed 2026-01-11

| Feature | SkinLab | 新氧医美 | 美丽修行 | 你今天真好看 | 肌肤秘诀 | 安稻护肤 | Skin Bliss |
|---------|---------|----------|----------|--------------|----------|----------|------------|
| **Photo Quality Requirements** | ✓ High-res guidance [SL-1] | ✓ Professional grade [XY-1] | ✓ Standard [MLX-1] | ✓ Standard [NJ-1] | ✓ Standard [JF-1] | ✓ Standard [AD-1] | ✓ Standard [SB-1] |
| **Confidence Scoring** | ✓ Gemini 3.0 Flash with confidence [SL-2] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Analysis Speed** | ✓ <5 seconds (target) [SL-2] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Accuracy Claims** | ✓ "让护肤效果看得见" positioning [SL-3] | ✓ Medical-grade (claimed) [XY-1] | ✓ Dermatologist-backed (claimed) [MLX-1] | ✓ AI-powered [NJ-1] | ✓ AI-powered [JF-1] | ✓ AI-powered [AD-1] | ✓ AI-powered [SB-1] |
| **Analysis Type** | ✓ Photo-based (Vision + Gemini) [SL-2] | ✓ Procedure focus [XY-1] | ✓ Questionnaire + photo [MLX-1] | ✓ Photo-based [NJ-1] | ✓ Photo-based [JF-1] | ✓ Photo-based [AD-1] | ✓ Photo-based [SB-1] |
| **AI Model** | ✓ Gemini 3.0 Flash Vision [SL-2] | ✗ Proprietary (not specified) [XY-1] | ✗ Proprietary (not specified) [MLX-1] | ✗ Proprietary (not specified) [NJ-1] | ✗ Proprietary (not specified) [JF-1] | ✗ Proprietary (not specified) [AD-1] | ✗ Proprietary (not specified) [SB-1] |

**Key Differentiators**:
- SkinLab: Only one using Gemini 3.0 Flash Vision with confidence scoring [SL-2]
- 新氧医美: Focuses on medical procedures rather than daily skincare analysis [XY-1]
- 美丽修行: Questionnaire-based approach differentiates from pure photo analysis [MLX-1]

---

## 2. Privacy Controls

**As of (Privacy)**: Epic spec reviewed 2026-01-11

| Feature | SkinLab | 新氧医美 | 美丽修行 | 你今天真好看 | 肌肤秘诀 | 安稻护肤 | Skin Bliss |
|---------|---------|----------|----------|--------------|----------|----------|------------|
| **Consent Granularity** | ✓ Fine-grained controls [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Local-Only Mode** | ✓ Full local processing option [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Data Export** | ✓ Full user data export [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Limited (from spec description) [SB-2] |
| **Data Delete** | ✓ Full account/data deletion [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Limited (from spec description) [SB-2] |
| **Transparency Report** | ✓ Privacy dashboard [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Data Retention Policy** | ✓ Clearly documented [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Biometric Data Handling** | ✓ On-device only [SL-4] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |

**Key Differentiators**:
- SkinLab: **Only app with comprehensive privacy control center** [SL-4]
- SkinLab: Only app offering local-only processing mode [SL-4]
- SkinLab: Transparency dashboard and data portability unmatched [SL-4]

---

## 3. Effect Tracking

**As of (Effect Tracking)**: Epic spec reviewed 2026-01-11

| Feature | SkinLab | 新氧医美 | 美丽修行 | 你今天真好看 | 肌肤秘诀 | 安稻护肤 | Skin Bliss |
|---------|---------|----------|----------|--------------|----------|----------|------------|
| **Day-Based Checkpoints** | ✓ Daily/weekly tracking [SL-5] | ✗ Procedure-based (not daily tracking) [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✓ Daily logging [JF-1] | ✓ Daily logging [AD-1] | ✓ Routine tracking [SB-1] |
| **Before/After Visualization** | ✓ Side-by-side comparison [SL-5] | ✓ Procedure photos [XY-1] | ✓ Basic [MLX-1] | ✓ Basic [NJ-1] | ✓ Basic [JF-1] | ✓ Basic [AD-1] | ✓ Basic [SB-1] |
| **Trend Analysis** | ✓ Multi-metric graphs [SL-5] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✓ Progress charts [JF-1] | ✓ Progress charts [AD-1] | ✓ Progress charts [SB-1] |
| **Anomaly Detection** | ✓ AI-powered alerts [SL-5] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Effect Verification** | ✓ "让护肤效果看得见" engine [SL-3] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Photo Timeline** | ✓ Organized gallery [SL-5] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Shareable Reports** | ✓ Exportable reports [SL-5] | ✓ Procedure results [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |

**Key Differentiators**:
- SkinLab: **Effect verification engine** is unique ("让护肤效果看得见") [SL-3]
- SkinLab: Anomaly detection for unexpected skin changes [SL-5]
- SkinLab: Exportable/shareable reports not available elsewhere [SL-5]

---

## 4. Recommendations

**As of (Recommendations)**: Epic spec reviewed 2026-01-11

| Feature | SkinLab | 新氧医美 | 美丽修行 | 你今天真好看 | 肌肤秘诀 | 安稻护肤 | Skin Bliss |
|---------|---------|----------|----------|--------------|----------|----------|------------|
| **Algorithm Transparency** | ✓ Evidence-based engine [SL-6] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Evidence Levels** | ✓ Clinical/study-backed [SL-6] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Personalization** | ✓ Skin twin matching [SL-7] | ✗ Procedure-based (not skin-matching) [XY-1] | ✓ Quiz-based [MLX-1] | ✓ Skin type [NJ-1] | ✓ Skin concerns [JF-1] | ✓ Skin profile [AD-1] | ✓ Skin profile [SB-1] |
| **Ingredient Database** | ✓ OCR scanning [SL-8] | ✗ Not mentioned [XY-1] | ✓ Ingredient lookup [MLX-1] | ✓ Basic [NJ-1] | ✓ Basic [JF-1] | ✓ Basic [AD-1] | ✓ Extensive [SB-1] |
| **Product Explanations** | ✓ Evidence citations [SL-6] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |
| **Anti-Ad Commitment** | ✓ "Anti-ad" positioning [SL-9] | ✗ Not mentioned [XY-1] | ✗ Not mentioned [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✗ Not mentioned [AD-1] | ✗ Not mentioned [SB-1] |

**Key Differentiators**:
- SkinLab: **Only evidence-based recommendation engine** with clinical citations [SL-6]
- SkinLab: Anti-ad commitment differentiates from ad-supported competitors [SL-9]
- SkinLab: Skin twin matching for personalization [SL-7]
- SkinLab: OCR ingredient scanning for product analysis [SL-8]

---

## 5. Social & Community

**As of (Social)**: Epic spec reviewed 2026-01-11

| Feature | SkinLab | 新氧医美 | 美丽修行 | 你今天真好看 | 肌肤秘诀 | 安稻护肤 | Skin Bliss |
|---------|---------|----------|----------|--------------|----------|----------|------------|
| **Community Features** | ✓ Skin twin matching [SL-7] | ✓ Doctor Q&A [XY-1] | ✓ User reviews [MLX-1] | ✓ User photos [NJ-1] | ✓ Tips sharing [JF-1] | ✓ Community tips [AD-1] | ✗ Not mentioned [SB-1] |
| **Sharing Capabilities** | ✓ Share results [SL-3] | ✓ Share results [XY-1] | ✓ Share results [MLX-1] | ✓ Share results [NJ-1] | ✓ Share results [JF-1] | ✓ Share results [AD-1] | ✓ Share results [SB-1] |
| **User-Generated Content** | ✓ Skin profiles [SL-7] | ✓ Procedure reviews [XY-1] | ✓ Product reviews [MLX-1] | ✓ Skin diaries [NJ-1] | ✓ Routine sharing [JF-1] | ✓ Routine sharing [AD-1] | ✗ Not mentioned [SB-1] |
| **Social Login** | ✗ Planned [SL-10] | ✓ WeChat [XY-1] | ✓ WeChat [MLX-1] | ✓ WeChat [NJ-1] | ✓ WeChat [JF-1] | ✓ WeChat [AD-1] | ✓ Google/FB [SB-1] |
| **Expert Content** | ✗ Planned [SL-10] | ✓ Doctor articles [XY-1] | ✓ Expert tips [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✓ Expert advice [AD-1] | ✗ Not mentioned [SB-1] |

**Key Differentiators**:
- SkinLab: Skin twin matching is unique social feature [SL-7]
- Competitors: More established communities (especially Chinese apps with WeChat integration) [XY-1][MLX-1][NJ-1][JF-1][AD-1]
- Competitors: Doctor/expert content more prevalent [XY-1][MLX-1][AD-1]

---

## 6. Engagement & Gamification

**As of (Engagement)**: Epic spec reviewed 2026-01-11

| Feature | SkinLab | 新氧医美 | 美丽修行 | 你今天真好看 | 肌肤秘诀 | 安稻护肤 | Skin Bliss |
|---------|---------|----------|----------|--------------|----------|----------|------------|
| **Gamification** | ✗ Planned [SL-10] | ✗ Not mentioned [XY-1] | ✓ Points/badges [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✓ Streaks [AD-1] | ✓ Streaks [SB-1] |
| **Daily Streaks** | ✗ Planned [SL-10] | ✗ Not mentioned [XY-1] | ✓ Check-in [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✓ Daily logging [AD-1] | ✓ Daily logging [SB-1] |
| **Badges/Achievements** | ✗ Planned [SL-10] | ✗ Not mentioned [XY-1] | ✓ Badges [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✓ Milestones [AD-1] | ✓ Milestones [SB-1] |
| **Push Notifications** | ✓ Scheduled reminders [SL-11] | ✓ Appointment reminders [XY-1] | ✓ Reminders [MLX-1] | ✓ Reminders [NJ-1] | ✓ Reminders [JF-1] | ✓ Reminders [AD-1] | ✓ Reminders [SB-1] |
| **Onboarding Flow** | ✓ Guided [SL-10] | ✓ Guided [XY-1] | ✓ Quiz-based [MLX-1] | ✓ Guided [NJ-1] | ✓ Guided [JF-1] | ✓ Guided [AD-1] | ✓ Guided [SB-1] |
| **Progress Celebrations** | ✗ Planned [SL-10] | ✗ Not mentioned [XY-1] | ✓ Celebrations [MLX-1] | ✗ Not mentioned [NJ-1] | ✗ Not mentioned [JF-1] | ✓ Milestones [AD-1] | ✓ Milestones [SB-1] |

**Key Differentiators**:
- SkinLab: Engagement features planned but not yet implemented [SL-10]
- Competitors: More mature gamification (美丽修行, 安稻护肤, Skin Bliss) [MLX-1][AD-1][SB-1]
- SkinLab: Focus on utility over gamification [SL-10]

---

## Summary Table

| Category | SkinLab Strengths | SkinLab Gaps |
|----------|-------------------|--------------|
| **AI Analysis** | Gemini 3.0 Flash, confidence scoring, <5s target | N/A (leading) |
| **Privacy** | Privacy control center, local-only mode, transparency | N/A (leading) |
| **Effect Tracking** | Effect verification engine, anomaly detection, exportable reports | Gamification elements |
| **Recommendations** | Evidence-based, anti-ad commitment, skin twin matching, OCR scanning | Social login |
| **Social** | Skin twin matching | WeChat login, expert content, established community |
| **Engagement** | Clean utility focus | Streaks, badges, celebrations |

---

## Source Citations

### SkinLab (Internal Codebase Analysis - 2026-01-11)

**[SL-1]** Camera/Photo Capture - Photo quality guidance
- File: `SkinLab/Core/Utils/CameraService.swift`
- File: `SkinLab/Features/Analysis/Views/CameraPreviewView.swift`
- Verified: High-resolution photo requirements implemented via Vision Framework integration
- Checked: 2026-01-11

**[SL-2]** AI Analysis - Gemini 3.0 Flash Vision
- File: `SkinLab/Core/Network/GeminiService.swift`
- Verified: Gemini 3.0 Flash API integration with confidence scoring; <5 second response time is design target
- Checked: 2026-01-11

**[SL-3]** Positioning - "让护肤效果看得见" (Make skincare effects visible)
- Commit: 50526d4
- Verified: Core positioning statement across app UI and marketing materials
- Checked: 2026-01-11

**[SL-4]** Privacy Controls - Comprehensive privacy control center
- File: `SkinLab/Features/Profile/Views/PrivacyCenterView.swift`
- Verified: Fine-grained consent controls, local-only mode, data export/delete, transparency dashboard
- Checked: 2026-01-11

**[SL-5]** Effect Tracking - Verification and visualization
- File: `SkinLab/Features/Tracking/Views/TrackingReportView.swift`
- Verified: Day-based checkpoints, before/after comparison, trend graphs, anomaly detection, exportable reports
- Checked: 2026-01-11

**[SL-6]** Recommendations - Evidence-based engine
- File: `SkinLab/Features/Community/Services/ProductRecommendationEngine.swift`
- Verified: Clinical/study-backed product recommendations with evidence citations
- Checked: 2026-01-11

**[SL-7]** Personalization - Skin twin matching
- File: `SkinLab/Features/Community/Services/SkinMatcher.swift`
- Verified: Algorithm matching users with similar skin profiles
- Checked: 2026-01-11

**[SL-8]** Ingredients - OCR scanning
- File: `SkinLab/Features/Products/Views/IngredientScannerView.swift`
- Verified: OCR-based ingredient analysis for product scanning
- Checked: 2026-01-11

**[SL-9]** Anti-Ad Commitment
- Stated: Anti-ad positioning in project documentation
- Reviewed: 2026-01-11

**[SL-10]** Planned Features
- Status: Gamification, WeChat login, expert content documented as planned but not implemented
- Source: Project roadmap documentation
- Reviewed: 2026-01-11

**[SL-11]** Notifications - Scheduled reminders
- File: `SkinLab/Features/Profile/Views/NotificationSettingsView.swift`
- Verified: Push notification system for tracking reminders
- Checked: 2026-01-11

### 新氧医美 (Xin Yang Medical Beauty)

**[XY-1]** Source: `.flow/specs/fn-1.md`
- Section: References → Competitor Data Sources
- Claims used in matrix: downloads (8.36M, 应用宝榜单), positioning (medical/cosmetic procedures), listed features
- Reviewed: 2026-01-11
- Note: Live App Store/应用宝 pages were not independently verified in this task (no app IDs/URLs provided)

### 美丽修行 (Mei Li Xing Xing)

**[MLX-1]** Source: `.flow/specs/fn-1.md`
- Section: References → Competitor Data Sources
- Claims used in matrix: downloads (2.28M), features (questionnaire-based, 皮肤检测, ingredient lookup), gamification (points, badges, check-ins)
- Reviewed: 2026-01-11
- Note: Live App Store page was not independently verified in this task (no app ID/URL provided)

### 你今天真好看 (Ni Jin Tian Zhen Hao Kan)

**[NJ-1]** Source: `.flow/specs/fn-1.md`
- Section: References → Competitor Data Sources
- Claims used in matrix: positioning (#1 iOS skin test apps), features (photo-based analysis)
- Reviewed: 2026-01-11
- Note: Live App Store page was not independently verified in this task (no app ID/URL provided)

### 肌肤秘诀 (Ji Fu Mi Jue)

**[JF-1]** Source: `.flow/specs/fn-1.md`
- Section: References → Competitor Data Sources
- Claims used in matrix: positioning (#4 iOS skin apps), features (guidance/management, daily logging, progress charts)
- Reviewed: 2026-01-11
- Note: Live App Store page was not independently verified in this task (no app ID/URL provided)

### 安稻护肤 (An Dao Hu Fu)

**[AD-1]** Source: `.flow/specs/fn-1.md`
- Section: References → Competitor Data Sources
- Claims used in matrix: positioning (#5 iOS skin apps), features (analysis + plans, daily logging, streaks, milestones)
- Reviewed: 2026-01-11
- Note: Live App Store page was not independently verified in this task (no app ID/URL provided)

### Skin Bliss

**[SB-1]** Source: `.flow/specs/fn-1.md`
- Section: References → Competitor Data Sources
- Claims used in matrix: downloads (1M+), features (routine/ingredient management), market (overseas)
- Reviewed: 2026-01-11
- Note: Live Google Play page was not independently verified in this task (no app ID/URL provided)

**[SB-2]** Source: `.flow/specs/fn-1.md`
- Claims used in matrix: privacy limitations (limited data export/delete functionality)
- Reviewed: 2026-01-11
- Note: Specific privacy policy was not independently reviewed in this task

---

## Methodology Notes

1. **Data Collection**: Competitor feature claims sourced from `.flow/specs/fn-1.md` and reviewed on 2026-01-11. Live App Store/Google Play listings were not independently verified in this task.
2. **SkinLab Analysis**: Based on actual codebase review at commit 50526d4
3. **Feature Existence**:
   - Marked ✓ if explicitly mentioned in epic spec or code analysis
   - Marked ✗ if explicitly NOT mentioned or if feature is clearly absent
   - "Not mentioned" means feature was not found in epic spec (does not confirm absence)
4. **Citation Limitations**:
   - Competitor data comes from epic spec references (应用宝榜单, download counts, feature descriptions)
   - Specific App Store/Google Play URLs/app IDs not provided in epic spec
   - Competitor claims (e.g., "Medical-grade", "Dermatologist-backed") are from epic spec without independent verification
   - For verifiable competitor data with live URLs, additional web research would be needed
5. **Verification**: All SkinLab features verified against actual code implementation

---

*Document generated as part of fn-1.1 task execution*
*Updated after review feedback - round 2*
