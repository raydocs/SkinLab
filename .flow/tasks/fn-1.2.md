# fn-1.2 Conduct gap analysis and prioritization

## Description
Analyze feature matrix to identify gaps, assess impact/feasibility, and prioritize improvements.

**Process**:
1. Identify gaps where SkinLab lacks features present in 2+ competitors
2. For each gap, assess:
   - User impact (high/medium/low)
   - Business value (high/medium/low)
   - Technical complexity (1-5 scale, 5=hardest)
   - Code reuse potential (reference existing files)
3. Prioritize using framework:
   - P0: High user + business value, low complexity, strong strategic fit
   - P1: High value in any dimension, medium complexity
   - P2: Medium value, any complexity
   - P3: Lower priority or exploratory

**Deliverable**: Gap analysis document with prioritized list and rationale.

**Output**: Save to `.flow/specs/fn-1-gap-analysis.md`
## Acceptance
- [ ] Gap analysis document completed
- [ ] Minimum 10 gaps identified and scored
- [ ] Each gap includes: impact assessment, feasibility score (1-5), reuse references
- [ ] Each gap links back to matrix evidence (competitors where feature exists + citation references)
- [ ] Prioritization applied (P0-P3) with 1-2 sentence rationale
- [ ] Strategic fit justification for each gap ("让护肤效果看得见")
- [ ] Document saved to `.flow/specs/fn-1-gap-analysis.md`
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
