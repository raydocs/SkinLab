# fn-5-foq.5 编写单元测试

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Added comprehensive unit tests for ingredient conflict detection: 17 tests covering ConflictKnowledgeBase, ConflictSeverity, IngredientConflict model, and detectConflicts method via IngredientRiskAnalyzer.analyze(). Tests verify knowledge base has 15+ pairs, correct conflict detection for retinol+AHA and vitaminC+niacinamide, no false positives, and alias matching (Ascorbic Acid -> vitamin C, Salicylic Acid -> BHA, Lactic Acid -> AHA).
## Evidence
- Commits: 6e60344f429c87a9d7c8937a1b62d16f075033b1
- Tests: All 17 IngredientConflictTests pass: testConflictKnowledgeBase_hasAtLeast15ConflictPairs, testConflictKnowledgeBase_containsRetinolAHAConflict, testConflictKnowledgeBase_containsVitaminCNiacinamideConflict, testDetectConflicts_findsRetinolAHAConflict, testDetectConflicts_findsVitaminCNiacinamideConflict, testDetectConflicts_noConflictsWhenIngredientsDoNotConflict, testDetectConflicts_aliasMatching_ascorbicAcidMatchesVitaminC, testDetectConflicts_salicylicAcidMatchesBHA, testDetectConflicts_lacticAcidMatchesAHA
- PRs: