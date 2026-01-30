# Tech Debt Report

Generated: 2026-01-29 19:20:08

## Summary

| Marker | Count | Priority |
|--------|-------|----------|
| TODO | 0 | Low |
| FIXME | 0 | Medium |
| HACK | 0 | High |
| TEMP/TEMPORARY | 0 | High |
| Deprecated APIs | 0 | Medium |

**Total Tech Debt Items: 0**

---

## 🔧 FIXME Items (Medium Priority)

✅ No FIXME items found.

## ⚠️ HACK Items (High Priority)

✅ No HACK items found.

## 🚨 TEMP\|TEMPORARY Items (High Priority)

✅ No TEMP\|TEMPORARY items found.

## 📝 TODO Items (Low Priority)

✅ No TODO items found.

## 📅 Deprecated API Usage

✅ No deprecated API usage found.

## 💥 Force Unwrap Warnings

These force unwraps could cause crashes if the value is nil:

```
SkinLab/UI/Components/ProductPickerView.swift:15:        guard !query.isEmpty else { return products }
SkinLab/UI/Components/ProductPickerView.swift:114:                            if !products.isEmpty {
SkinLab/Core/Config/AppConfiguration.swift:148:        static var analyticsEnabled: Bool { !current.isDebug }
SkinLab/Core/Network/WeatherService.swift:191:        #if canImport(WeatherKit) && !targetEnvironment(simulator)
SkinLab/Core/Network/WeatherService.swift:202:        #if canImport(WeatherKit) && !targetEnvironment(simulator)
SkinLab/Core/Network/RetryPolicy.swift:379:            if !delay.isFinite || delay < 0 {
SkinLab/Core/Network/GeminiService.swift:12:        if let envKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !envKey.isEmpty {
SkinLab/Core/Network/GeminiService.swift:16:        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String, !plistKey.isEmpty {
SkinLab/Core/Network/GeminiService.swift:91:        guard !GeminiConfig.apiKey.isEmpty else {
SkinLab/Core/Network/GeminiService.swift:478:        guard !GeminiConfig.apiKey.isEmpty else {
SkinLab/Core/Network/GeminiService.swift:620:            if !profile.concerns.isEmpty {
SkinLab/Core/Network/GeminiService.swift:626:            if !profile.allergies.isEmpty {
SkinLab/Core/Network/GeminiService.swift:647:        if let history = request.historySnapshot, !history.severeIssues.isEmpty {
SkinLab/Core/Network/GeminiService.swift:657:            if !history.ingredientStats.isEmpty {
SkinLab/Core/Network/GeminiService.swift:659:                if !problematicIngredients.isEmpty {
SkinLab/Core/Network/GeminiService.swift:671:        if !request.preferences.isEmpty {
SkinLab/Core/Network/RoutineService.swift:69:            if !profile.concerns.isEmpty {
SkinLab/Core/Network/RoutineService.swift:73:            if !profile.allergies.isEmpty {
SkinLab/Core/Network/RoutineService.swift:81:            if !profile.activePrescriptions.isEmpty {
SkinLab/Core/Network/RoutineService.swift:94:            if !prefsList.isEmpty {
SkinLab/Core/Network/RoutineService.swift:126:            if !worsening.isEmpty {
SkinLab/Core/Network/RoutineService.swift:134:            if !improving.isEmpty {
SkinLab/Core/Network/RoutineService.swift:145:        if !negativeIngredients.isEmpty {
SkinLab/Core/Network/RoutineService.swift:302:        guard !GeminiConfig.apiKey.isEmpty else {
SkinLab/Core/Utils/ImageCache.swift:151:            guard !token.isCancelled else { return }
SkinLab/Core/Utils/ImageCache.swift:155:                guard !token.isCancelled else { return }
SkinLab/Core/Utils/ImageCache.swift:182:            guard !token.isCancelled else { return }
SkinLab/Core/Utils/IngredientRiskAnalyzer.swift:189:        !personalizedWarnings.isEmpty || !personalizedRecommendations.isEmpty || !allergyMatches.isEmpty || !userReactions.isEmpty || !conflicts.isEmpty
SkinLab/Core/Utils/IngredientRiskAnalyzer.swift:522:                if !irritants.isEmpty {
SkinLab/Core/Utils/IngredientRiskAnalyzer.swift:535:                if !comedogenic.isEmpty {
SkinLab/Core/Utils/IngredientRiskAnalyzer.swift:550:            if !matches.isEmpty {
SkinLab/Core/Utils/IngredientOCR.swift:89:        guard let observations = request.results, !observations.isEmpty else {
SkinLab/Core/Utils/IngredientOCR.swift:148:                    if !afterColon.isEmpty {
SkinLab/Core/Utils/IngredientOCR.swift:169:                if !lineContainsFooter {
SkinLab/Core/Utils/IngredientOCR.swift:179:        if !foundHeader {
SkinLab/Core/Utils/IngredientOCR.swift:226:                    if !trimmed.isEmpty {
SkinLab/Core/Utils/IngredientOCR.swift:241:                        if !trimmed.isEmpty {
SkinLab/Core/Utils/IngredientOCR.swift:258:        if !trimmed.isEmpty {
SkinLab/Core/Utils/IngredientOCR.swift:685:            guard !word.isEmpty else { return word }
SkinLab/Core/Utils/ShareCardRenderer.swift:110:            if !report.timeline.isEmpty {
SkinLab/Core/Utils/IngredientAIAnalyzer.swift:42:        if let cached = cache[cacheKey], !cached.isExpired {
SkinLab/Core/Utils/IngredientAIAnalyzer.swift:127:        cache = cache.filter { !$0.value.isExpired }
SkinLab/Core/Utils/LocationManager.swift:97:        if !isAuthorized {
SkinLab/Core/Utils/LocationManager.swift:106:                if !granted {
SkinLab/Core/Utils/CameraService.swift:96:            if !captureSession.outputs.contains(where: { $0 === photoOutput }),
SkinLab/Core/Utils/CameraService.swift:103:            if !captureSession.outputs.contains(where: { $0 === videoOutput }),
SkinLab/Core/Utils/CameraService.swift:271:        if !faceDetected {
SkinLab/Core/Utils/CameraService.swift:622:        guard !laplacianValues.isEmpty else { return .unknown }
SkinLab/Core/Utils/UserHistoryStore.swift:42:        guard !recent.isEmpty else { return nil }
SkinLab/Core/Utils/UserHistoryStore.swift:109:        guard !exposures.isEmpty else { return nil }
```

> Note: Some force unwraps may be intentional (IBOutlets, known-good data). Review individually.

---

## Recommendations

### High Priority (Address This Sprint)
- **HACK items**: These are known shortcuts that could cause issues
- **TEMP items**: Temporary code that should be removed or replaced

### Medium Priority (Address This Month)
- **FIXME items**: Known bugs or issues that need fixing
- **Deprecated APIs**: Will break in future iOS versions

### Low Priority (Backlog)
- **TODO items**: Future improvements and features

### Best Practices
1. Add ticket numbers to TODOs: `// TODO: [SKIN-123] Implement caching`
2. Include context: `// FIXME: This fails when user has no photos`
3. Set deadlines for TEMP code: `// TEMP: Remove after v2.0 launch`
4. Regularly review and clean up tech debt
