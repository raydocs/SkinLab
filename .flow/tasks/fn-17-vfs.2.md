# fn-17-vfs.2 Unify GeminiService retry policy

## Description
Refactor GeminiService to use the shared RetryPolicy/withRetry utilities, including honoring Retry-After when present, to align with global retry limits.
## Acceptance
- GeminiService uses withRetry/RetryPolicy for network calls
- Retry-After is respected when available
- Tests/linters pass
## Done summary
- refactor GeminiService analysis and ingredient requests to use withRetry
- centralize response validation and error mapping with Retry-After support
## Evidence
- Commits:
- Tests:
- PRs:
