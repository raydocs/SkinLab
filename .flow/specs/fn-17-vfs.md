# fn-17-vfs Optimization cleanup from full scan

## Overview
Implement prioritized improvements from the full scan (cache correctness, retry consistency, cache hygiene, and OCR efficiency).

## Scope
- WeatherService cache invalidation tied to user location changes
- GeminiService retry unification with RetryPolicy/withRetry
- MatchCache expiration cleanup and cacheExpiration usage
- IngredientOCR CIContext reuse

## Approach
1) Track last weather location + invalidate cache on significant location change.
2) Route GeminiService network calls through withRetry to align with RetryPolicy and Retry-After.
3) Align MatchCache expiration checks with cacheExpiration and clean expired entries consistently.
4) Reuse CIContext for OCR preprocessing.

## Quick commands
<!-- Required: at least one smoke command for the repo -->
- `make test`

## Acceptance
- [ ] Weather cache invalidation respects location changes
- [ ] GeminiService retry uses RetryPolicy/withRetry
- [ ] MatchCache expiration cleanup is consistent
- [ ] OCR preprocessing reuses CIContext
- [ ] Tests/linters pass

## References
- SkinLab/Core/Network/WeatherService.swift
- SkinLab/Core/Network/GeminiService.swift
- SkinLab/Core/Network/RetryPolicy.swift
- SkinLab/Features/Community/Services/MatchCache.swift
- SkinLab/Core/Utils/IngredientOCR.swift
