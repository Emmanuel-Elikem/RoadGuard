---
description: Main development workflow for new features
---

# Development Workflow

Follow these steps when developing a new feature.

## 1. Sync with Develop Branch
// turbo
```bash
git checkout develop
git pull origin develop
```

## 2. Create Feature Branch
```bash
git checkout -b feature/<feature-name>
```

## 3. Implement the Feature
- Follow patterns in `.github/agents/RoadGuard-Coding-Standards.md`
- Use theme values from `lib/core/theme/`
- Handle errors with try-catch and Result types
- Ensure offline-first (save to Hive before Firebase)

## 4. Run Analysis and Tests
// turbo
```bash
flutter analyze
flutter test
```

## 5. Commit Changes
```bash
git add .
git commit -m "feat: <description>"
git push origin feature/<feature-name>
```

## 6. Create Pull Request
Use the `/pull-request` workflow to create a PR with Copilot review.

---

## Quick Commands

| Action | Command |
|--------|---------|
| Format code | `dart format .` |
| Analyze | `flutter analyze` |
| Run tests | `flutter test` |
| Build APK | `flutter build apk --debug` |
| Hot reload | Via MCP: `hot_reload` |
