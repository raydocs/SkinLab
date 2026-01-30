# fn-17-vfs.4 Reuse CIContext in IngredientOCR

## Description
Reuse a shared CIContext in IngredientOCR preprocessing to avoid repeated context creation overhead.
## Acceptance
- IngredientOCR uses shared CIContext
- Behavior unchanged for preprocessing output
- Tests/linters pass
## Done summary
- reuse a shared CIContext inside IngredientOCRService preprocessing
## Evidence
- Commits:
- Tests:
- PRs:
