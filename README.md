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

## Features

### AI Skin Analysis
- Photo-based skin condition analysis using Gemini 3.0 Flash Vision API
- Standardized photo capture with real-time guidance
- Multi-dimensional scoring (hydration, clarity, texture, etc.)
- Reliability scoring based on photo quality and lighting conditions

### 28-Day Effect Tracking
- Structured tracking cycles with Day 0/7/14/21/28 check-ins
- Before/after visualization with timeline view
- Score trend analysis and progress reports
- Lifestyle correlation insights (sleep, stress, water intake)

### Engagement System (Partial)
- Daily streak tracking with visual counter
- Achievement badges for milestones
- Streak freeze mechanic (1 per 30 days)
- Celebration animations for achievements

### Community Features
- Skin twin matching based on similar skin profiles
- Anonymous sharing of progress and insights

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
- Gemini API key (for AI analysis features)

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd SkinLab
   ```

2. Open the project in Xcode:
   ```bash
   open SkinLab.xcodeproj
   ```

3. Configure your Gemini API key in the appropriate configuration file.

4. Build and run on simulator or device:
   ```bash
   xcodebuild -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

### Running Tests

```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
SkinLab/
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
├── Resources/              # Assets and data files
└── Tests/                  # Unit and integration tests
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
