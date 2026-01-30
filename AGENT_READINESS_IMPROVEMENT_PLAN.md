# SkinLab Agent Readiness Improvement Plan

Based on the Level 2 readiness report, this document outlines all improvements needed to reach higher maturity levels.

---

## 📊 Current Status: Level 2 (45/75 applicable criteria)

| Category | Score | Priority |
|----------|-------|----------|
| Style & Validation | 3/14 | 🔴 Critical |
| Build System | 3/11 | 🔴 Critical |
| Testing | 1/8 | 🔴 Critical |
| Documentation | 6/14 | 🟡 Medium |
| Dev Environment | 3/5 | 🟢 Good |
| Debugging & Observability | 5/11 | 🟡 Medium |
| Security | 4/10 | 🟡 Medium |

---

## Phase 1: Foundation (Week 1-2) 🔴

### 1.1 SwiftLint Setup
**Files to create:**
```
.swiftlint.yml
scripts/lint.sh
```

**Implementation:**
```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicit_return
excluded:
  - Pods
  - DerivedData
  - .build
line_length:
  warning: 120
  error: 150
cyclomatic_complexity:
  warning: 10
  error: 20
file_length:
  warning: 400
  error: 600
```

**Install:** `brew install swiftlint`

---

### 1.2 SwiftFormat Setup
**Files to create:**
```
.swiftformat
scripts/format.sh
```

**Implementation:**
```
# .swiftformat
--indent 4
--indentcase false
--trimwhitespace always
--importgrouping alphabetized
--semicolons never
--commas always
--disable redundantSelf
```

**Install:** `brew install swiftformat`

---

### 1.3 Pre-commit Hooks
**Files to create:**
```
.pre-commit-config.yaml
scripts/install-hooks.sh
```

**Implementation:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: swiftlint
        name: SwiftLint
        entry: swiftlint lint --strict
        language: system
        files: \.swift$
      - id: swiftformat
        name: SwiftFormat Check
        entry: swiftformat --lint .
        language: system
        files: \.swift$
      - id: secrets-check
        name: Secrets Check
        entry: scripts/check-secrets.sh
        language: script
        files: \.swift$|\.plist$|\.xcconfig$
```

---

### 1.4 Fix .gitignore
**Add missing entries:**
```gitignore
# IDE
.vscode/
.idea/
*.swp

# Environment
.env
.env.*
!.env.template

# SPM
Package.resolved
```

---

## Phase 2: CI/CD Pipeline (Week 2-3) 🔴

### 2.1 GitHub Actions Workflow
**File:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: SwiftLint
        run: |
          brew install swiftlint
          swiftlint lint --strict --reporter github-actions-logging

  build-and-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      - name: Build
        run: |
          xcodebuild build \
            -project SkinLab.xcodeproj \
            -scheme SkinLab \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
            CODE_SIGNING_ALLOWED=NO
      - name: Test
        run: |
          xcodebuild test \
            -project SkinLab.xcodeproj \
            -scheme SkinLab \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult
      - name: Coverage Report
        run: xcrun xccov view --report TestResults.xcresult
```

---

### 2.2 Branch Protection
**Configure via GitHub Settings or CLI:**
```bash
gh api repos/{owner}/SkinLab/rulesets -X POST -f name="main-protection" \
  -f target="branch" \
  -f enforcement="active" \
  --json 'conditions={"ref_name":{"include":["refs/heads/main"]}}' \
  --json 'rules=[
    {"type":"pull_request","parameters":{"required_approving_review_count":1}},
    {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,"required_status_checks":[{"context":"build-and-test"}]}}
  ]'
```

---

### 2.3 CODEOWNERS
**File:** `.github/CODEOWNERS`
```
# Default owner
* @raydocs

# Core features
/SkinLab/Features/Analysis/ @raydocs
/SkinLab/Core/Network/ @raydocs

# Security-sensitive
/SkinLab/Core/Storage/KeychainManager.swift @raydocs
Secrets.xcconfig.template @raydocs
```

---

## Phase 3: Testing Infrastructure (Week 3-4) 🔴

### 3.1 UI Tests Target
**Create:** `SkinLabUITests/` directory with:
- `SkinLabUITests.swift` - Base UI test class
- `AnalysisFlowTests.swift` - Core flow tests
- `OnboardingTests.swift` - Onboarding flow

### 3.2 Test Coverage Threshold
**Add to CI workflow:**
```yaml
- name: Check Coverage
  run: |
    COVERAGE=$(xcrun xccov view --report --json TestResults.xcresult | jq '.lineCoverage')
    if (( $(echo "$COVERAGE < 0.60" | bc -l) )); then
      echo "Coverage $COVERAGE is below 60% threshold"
      exit 1
    fi
```

### 3.3 Test Naming Convention
**Document in AGENTS.md:**
```markdown
## Test Naming Convention
- Format: `test_<methodName>_<scenario>_<expectedResult>()`
- Example: `test_analyzeImage_withValidImage_returnsAnalysis()`
```

---

## Phase 4: Documentation & Templates (Week 4-5) 🟡

### 4.1 Issue Templates
**File:** `.github/ISSUE_TEMPLATE/bug_report.md`
```markdown
---
name: Bug Report
about: Report a bug in SkinLab
labels: bug, triage
---

## Description
<!-- Clear description of the bug -->

## Steps to Reproduce
1.
2.
3.

## Expected Behavior

## Actual Behavior

## Environment
- iOS Version:
- Device:
- App Version:

## Screenshots/Logs
```

**File:** `.github/ISSUE_TEMPLATE/feature_request.md`
```markdown
---
name: Feature Request
about: Suggest a new feature
labels: enhancement
---

## Problem Statement

## Proposed Solution

## Alternatives Considered

## Additional Context
```

### 4.2 PR Template
**File:** `.github/pull_request_template.md`
```markdown
## Summary
<!-- What does this PR do? -->

## Changes
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Screenshots (if UI changes)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed
- [ ] No new warnings
- [ ] Documentation updated
```

### 4.3 Architecture Documentation
**File:** `docs/ARCHITECTURE.md`
- System overview diagram (Mermaid)
- Data flow diagrams
- Component relationships
- API integration points

---

## Phase 5: Observability & Security (Week 5-6) 🟡

### 5.1 Crash Reporting (Firebase Crashlytics)
**Integration:**
1. Add Firebase SDK via SPM
2. Configure in `AppDelegate`
3. Add `GoogleService-Info.plist` (gitignored)

### 5.2 Dependabot Configuration
**File:** `.github/dependabot.yml`
```yaml
version: 2
updates:
  - package-ecosystem: "swift"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

### 5.3 Code Scanning
**File:** `.github/workflows/codeql.yml`
```yaml
name: CodeQL Analysis

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0'

jobs:
  analyze:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: swift
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
```

---

## Phase 6: Advanced Tooling (Week 6-8) 🟢

### 6.1 Dead Code Detection
**Tool:** [Periphery](https://github.com/peripheryapp/periphery)
```bash
brew install peripheryapp/periphery/periphery
periphery scan --project SkinLab.xcodeproj --schemes SkinLab --targets SkinLab
```

### 6.2 Duplicate Code Detection
**Tool:** [CPD (PMD)](https://pmd.github.io/)
```bash
pmd cpd --minimum-tokens 50 --language swift --files SkinLab/
```

### 6.3 Tech Debt Tracking
**Add script:** `scripts/tech-debt-report.sh`
```bash
#!/bin/bash
echo "=== Tech Debt Report ==="
echo "TODOs: $(grep -r "TODO" SkinLab --include="*.swift" | wc -l)"
echo "FIXMEs: $(grep -r "FIXME" SkinLab --include="*.swift" | wc -l)"
echo "HACKs: $(grep -r "HACK" SkinLab --include="*.swift" | wc -l)"
grep -rn "TODO\|FIXME\|HACK" SkinLab --include="*.swift"
```

### 6.4 Feature Flag Cleanup
**Add script:** `scripts/stale-flags.sh`
```bash
#!/bin/bash
# Check for feature flags not used in code
for flag in $(grep -oP 'case \K\w+' SkinLab/App/AppConfiguration.swift); do
  count=$(grep -r "$flag" SkinLab --include="*.swift" | wc -l)
  if [ "$count" -lt 2 ]; then
    echo "Potentially stale flag: $flag (used $count times)"
  fi
done
```

---

## Implementation Priority Matrix

| Task | Impact | Effort | Priority |
|------|--------|--------|----------|
| SwiftLint + SwiftFormat | High | Low | P0 |
| GitHub Actions CI | High | Medium | P0 |
| Pre-commit hooks | Medium | Low | P0 |
| Branch protection | High | Low | P0 |
| Fix .gitignore | Low | Low | P0 |
| UI Tests | High | High | P1 |
| Coverage thresholds | Medium | Low | P1 |
| Issue/PR templates | Medium | Low | P1 |
| CODEOWNERS | Medium | Low | P1 |
| Dependabot | Medium | Low | P1 |
| Crashlytics | High | Medium | P1 |
| Architecture docs | Medium | Medium | P2 |
| CodeQL scanning | Medium | Low | P2 |
| Periphery/Dead code | Low | Medium | P3 |
| Duplicate detection | Low | Medium | P3 |

---

## Quick Start Commands

```bash
# Phase 1: Install tools
brew install swiftlint swiftformat pre-commit

# Initialize pre-commit
pre-commit install

# Run lint check
swiftlint lint

# Format code
swiftformat .

# Phase 2: Setup CI (after creating workflow files)
gh workflow run ci.yml

# Check branch protection
gh api repos/{owner}/SkinLab/rules/branches/main
```

---

## Success Metrics

| Level | Score Required | Target Date |
|-------|----------------|-------------|
| Level 3 | 55/75 (73%) | Week 3 |
| Level 4 | 65/75 (87%) | Week 6 |
| Level 5 | 70/75 (93%) | Week 8 |

---

## Notes

- All N/A criteria (monorepo, DAST, N+1, health checks) are correctly marked as not applicable for this iOS app
- Focus on automating quality gates before adding more features
- Consider using Fastlane for release automation in Phase 6+
