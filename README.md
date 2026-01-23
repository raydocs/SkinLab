# SkinLab

AI-powered skin analysis and skincare recommendation iOS app.

## Overview

SkinLab helps users understand their skin health through AI-powered analysis and track skincare effectiveness over a 28-day verification cycle. The app focuses on data-driven insights that users want to share.

**Core Philosophy**: Make skincare effects visible ("让护肤效果看得见")

**Target Users**: 18-35 year olds focused on skincare

**Differentiation**:
- Effect verification engine with 28-day tracking cycles
- Skin twin matching for personalized recommendations
- Anti-ad commitment - evidence-based suggestions only

## Features (Completed)

### fn-2: Engagement (Daily Streaks & Achievement Badges)
- Daily streak tracking for check-ins with longest streak display
- Achievement badges and dashboard for milestones
- Milestone celebration animations (respects reduced motion)
- Streak freeze mechanic (1 per 30 days)
- Local notifications for streak reminders and at-risk warnings

### fn-3: Photo Standardization & Lifestyle Correlation
- Day 0 baseline creation to start tracking sessions from analysis
- Standardized photo capture guidance with real-time feedback
- Photo quality and reliability scoring at capture time
- Lifestyle inputs are optional and only saved when explicitly set
- Lifestyle correlation insights based on real score deltas

## Tech Stack

| Component | Technology |
|-----------|------------|
| Platform | iOS 17+ |
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Architecture | MVVM + Clean Architecture |
| Storage | SwiftData |
| AI | Gemini 3.0 Flash Vision API |
| Image Processing | Vision Framework |

## Getting Started

### Requirements

- Xcode 15.0+
- iOS 17.0+ deployment target
- Swift 5.9+
- OpenRouter API key (for AI analysis features via Gemini)

### Setup

1. Clone and open the project:
   ```bash
   git clone <repository-url>
   cd SkinLab
   open SkinLab.xcodeproj
   ```

2. Configure secrets:
   - Copy `Secrets.xcconfig.template` to `Secrets.xcconfig`
   - Set your `OPENROUTER_API_KEY` in the new file
   - Do NOT commit `Secrets.xcconfig` to version control

3. Build and run on simulator or device:
   ```bash
   xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

### Running Tests

```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
SkinLab/                    # App source code
├── App/                    # App entry point and configuration
├── Core/
│   ├── Network/            # API services (GeminiService)
│   ├── Storage/            # SwiftData models and persistence
│   └── Utils/              # Extensions and utilities
├── Features/
│   ├── Analysis/           # AI skin analysis feature
│   ├── Tracking/           # 28-day effect tracking
│   ├── Engagement/         # Streaks and achievements
│   ├── Community/          # Skin twin and sharing
│   ├── Products/           # Product recommendations
│   ├── Profile/            # User profile management
│   ├── Celebration/        # Achievement celebrations
│   └── Sharing/            # Social sharing services
├── Services/               # Shared business logic services
├── UI/
│   ├── Components/         # Reusable UI components
│   └── Theme/              # Design system and styling
└── Resources/              # Assets and data files

SkinLabTests/               # XCTest target for unit tests
.flow/                      # Flow-Next specs and tasks (see .flow/usage.md)
```

## Planning Artifacts

The `.flow/` directory contains project planning and task tracking:
- Epic specifications in `.flow/specs/`
- Task breakdowns in `.flow/tasks/`
- See `.flow/usage.md` for workflow details

Key planning documents:
- `fn-1`: Competitor analysis and improvement roadmap
- `fn-2`: Engagement features (streaks, badges)
- `fn-3`: Photo standardization and lifestyle correlation
- `fn-4`: Code quality and test coverage

## Contributing

See [CLAUDE.md](CLAUDE.md) for development guidelines and AI agent instructions.

Key conventions:
- Use Flow-Next (`.flow/bin/flowctl`) for task tracking
- Follow MVVM + Clean Architecture patterns
- Write unit tests for core services
- Keep views under 600 lines
