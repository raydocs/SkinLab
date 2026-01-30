# fn-17-vfs.3 MatchCache expiration cleanup

## Description
Make MatchCache expiration behavior consistent: use cacheExpiration constant in isExpired checks and remove expired entries when accessed.
## Acceptance
- cacheExpiration constant is used consistently
- Expired entries are invalidated on read paths
- Tests/linters pass
## Done summary
- align MatchCache expiration checks with cacheExpiration constant
- invalidate expired entries in recommendation and entry accessors
## Evidence
- Commits:
- Tests:
- PRs:
