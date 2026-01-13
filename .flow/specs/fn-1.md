# Competitor Analysis & Improvement Roadmap

## Overview

Comprehensive analysis of SkinLab iOS app against 6 major competitors (新氧医美, 美丽修行, 你今天真好看, 肌肤秘诀, 安稻护肤, Skin Bliss) to identify competitive strengths, weaknesses, and actionable improvement opportunities.

**Primary Goal**: Inform product strategy and roadmap decisions with data-driven competitive intelligence.

**Success Criteria**: Deliverable report that identifies:
1. Top 5 competitive differentiation opportunities
2. Priority-ranked improvement recommendations
3. Feature gaps vs. competitors with implementation complexity estimates

## Scope

### In Scope
- Feature comparison matrix across 6 competitors
- Analysis of: AI skin analysis, privacy controls, effect tracking, recommendation algorithms, social/community features, ingredient intelligence
- Positioning strategy recommendations
- Prioritized improvement roadmap with complexity estimates

### Out of Scope
- Technical reverse-engineering of competitor algorithms
- Automated competitive intelligence infrastructure
- User surveys or primary market research
- Financial analysis (revenue, pricing models)
- Code implementation of identified features

## Approach

### Phase 1: Competitor Feature Matrix
Create detailed feature comparison matrix covering:
- **AI Analysis**: Photo quality requirements, confidence scoring, analysis speed, accuracy claims
- **Privacy**: Consent granularity, local-only mode, data export/delete, transparency
- **Effect Tracking**: Day-based checkpoints, before/after visualization, trend analysis, anomaly detection
- **Recommendations**: Algorithm transparency, evidence levels, personalization, ingredient database size
- **Social**: Community features, sharing capabilities, user-generated content
- **Engagement**: Gamification, streaks, badges, notifications

Data sources:
- App Store descriptions and screenshots
- Public reviews and feature mentions
- Competitor websites and marketing materials
- Existing research from docs-scout and practice-scout

### Phase 2: Gap Analysis & Prioritization

For each identified gap:
1. **Impact Assessment**: User value (high/medium/low), business value (high/medium/low)
2. **Feasibility**: Technical complexity (1-5 scale), existing code reuse potential
3. **Strategic Fit**: Alignment with "让护肤效果看得见" positioning

Prioritization framework:
- **P0**: High user + business value, low complexity, strong strategic fit
- **P1**: High value in any dimension, medium complexity
- **P2**: Medium value, any complexity
- **P3**: Lower priority or exploratory

### Phase 3: Recommendations Document

Deliverable structure:
1. **Executive Summary**: Key findings in 1 page
2. **Feature Matrix**: Detailed comparison table
3. **Competitive Positioning**: Where SkinLab wins vs. competitors
4. **Gap Analysis**: Missing features with impact ratings
5. **Improvement Roadmap**: Prioritized recommendations with:
   - Feature description
   - User impact
   - Implementation complexity (1-5)
   - Estimated effort (story points)
   - Reuse opportunities (existing code references)

### Scoring Conventions

- **Complexity**: 1 (trivial) to 5 (hard), relative to current SkinLab codebase
- **Effort**: Story points use Fibonacci 1/2/3/5/8 scale (1 = <0.5 day, 2 = ~1 day, 3 = ~2 days, 5 = ~3-5 days, 8 = ~1-2 weeks)
- **Sources**: Each competitor claim must cite a public source (App Store listing/screenshots, official site, or review excerpt) and include an "as-of" date (YYYY-MM-DD format)
- **Citation Format**: Consistent format per cell (e.g., "App Store: [URL] - [Section]" or "Review: [Platform] - [Date]")

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Language barriers for Chinese apps | Use existing research, focus on feature sets over nuanced details |
| Rapidly changing competitive landscape | Timestamp report, recommend quarterly updates |
| Subjective feature quality assessment | Use objective criteria (exists/doesn't exist, claims vs. implementation) |
| Regional feature differences | Note scope (e.g., China-only vs. global) in analysis |
| Data accuracy from public sources | Triangulate across multiple sources (app store, reviews, websites) |

## Acceptance Criteria

1. [ ] Feature matrix completed for all 6 competitors across 6 feature categories
2. [ ] Gap analysis document with impact/feasibility scores
3. [ ] Prioritized improvement roadmap (minimum 10 recommendations)
4. [ ] Executive summary (1 page maximum)
5. [ ] All findings grounded in existing research (context-scout, practice-scout, docs-scout)
6. [ ] Document saved to `.flow/specs/fn-1-competitor-analysis.md`

## Test Notes

This is a research epic. Validation includes:
- Verify all competitors are represented in feature matrix
- Check that each gap has impact + feasibility scores
- Ensure roadmap items reference existing code files for reuse
- Confirm document is readable by non-technical stakeholders

## References

### Existing Research
- **Context-scout findings**: PrivacyCenterView.swift:1-844, SkinMatcher.swift:1-117, ProductRecommendationEngine.swift:1-455
- **Practice-scout findings**: AI confidence scoring, evidence-based recommendations, privacy-first positioning, gamification patterns
- **Docs-scout findings**: iOS best practices, HIPAA compliance, Gemini 3 Vision API, skincare industry standards

### Key Code Files for Reuse Analysis
- `SkinLab/Features/Profile/Views/PrivacyCenterView.swift` - Privacy control implementation (844 lines)
- `SkinLab/Features/Tracking/Views/TrackingReportView.swift` - Effect verification UI
- `SkinLab/Features/Community/Services/SkinMatcher.swift` - Skin twin matching algorithm
- `SkinLab/Features/Community/Services/ProductRecommendationEngine.swift` - Evidence-based recommendations
- `SkinLab/Features/Products/Views/IngredientScannerView.swift` - OCR ingredient scanning

### Competitor Data Sources
- 新氧医美: 8.36M downloads (应用宝榜单), medical/cosmetic procedures focus
- 美丽修行: 2.28M downloads, questionnaire-based, "皮肤检测" positioning
- 你今天真好看: #1 iOS skin test apps, photo analysis focus
- 肌肤秘诀: #4 iOS skin apps, guidance/management focus
- 安稻护肤: #5 iOS skin apps, analysis + skincare plans
- Skin Bliss: 1M+ downloads (Google Play), overseas market, routine/ingredient management

### Quick Commands

After epic completion, verify with:
```bash
# View epic
.flow/bin/flowctl show fn-1

# View spec
.flow/bin/flowctl cat fn-1

# Validate structure
.flow/bin/flowctl validate --epic fn-1
```
