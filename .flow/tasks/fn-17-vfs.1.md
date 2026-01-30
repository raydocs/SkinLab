# fn-17-vfs.1 Weather cache invalidation by location

## Description
Update WeatherService caching so location changes invalidate cached weather. Track last fetch location and clear cache when distance exceeds threshold or location is unavailable.
## Acceptance
- Cache invalidates on significant location change
- Existing weather cache still used when location stable and cache fresh
- Tests/linters pass
## Done summary
- add location-aware cache invalidation in WeatherService
- fetch location before serving cache and clear when distance exceeds threshold
## Evidence
- Commits:
- Tests:
- PRs:
