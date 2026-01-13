# SkinLab iOS App - AI Agent Instructions

## Project Overview
SkinLab is an AI-powered skin analysis and skincare recommendation iOS app.
- **Core Philosophy**: Data-driven insights that users want to share
- **Target Users**: 18-35 year olds focused on skincare
- **Differentiation**: Effect verification engine + skin twin matching + anti-ad commitment

## Tech Stack
- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Clean Architecture
- **Storage**: SwiftData
- **AI**: Gemini 3.0 Flash Vision API
- **Image Processing**: Vision Framework

<!-- BEGIN FLOW-NEXT -->
## Flow-Next

This project uses Flow-Next for task tracking. Use `.flow/bin/flowctl` instead of markdown TODOs or TodoWrite.

**Quick commands:**
```bash
.flow/bin/flowctl list                # List all epics + tasks
.flow/bin/flowctl epics               # List all epics
.flow/bin/flowctl tasks --epic fn-N   # List tasks for epic
.flow/bin/flowctl ready --epic fn-N   # What's ready
.flow/bin/flowctl show fn-N.M         # View task
.flow/bin/flowctl start fn-N.M        # Claim task
.flow/bin/flowctl done fn-N.M --summary-file s.md --evidence-json e.json
```

**Rules:**
- Use `.flow/bin/flowctl` for ALL task tracking
- Do NOT create markdown TODOs or use TodoWrite
- Re-anchor (re-read spec + status) before every task

**More info:** `.flow/bin/flowctl --help` or read `.flow/usage.md`
<!-- END FLOW-NEXT -->
