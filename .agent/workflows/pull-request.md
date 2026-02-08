---
description: Create PR and request GitHub Copilot review
---

# Pull Request Workflow

Follow these steps to create a PR with automated Copilot review.

## 1. Ensure Branch is Up to Date
// turbo
```bash
git fetch origin develop
git rebase origin/develop
```

## 2. Push Latest Changes
// turbo
```bash
git push origin HEAD
```

## 3. Create Pull Request
Use GitHub MCP to create the PR:
- **Base branch:** develop
- **Head branch:** current branch
- **Title:** Feature description
- **Body:** Summary of changes

## 4. Request Copilot Review
After PR is created, use `request_copilot_review` tool to request automated review.

## 5. Wait for CI
The `copilot-review.yml` workflow will:
- Check formatting (`dart format`)
- Analyze code (`flutter analyze`)
- Run tests (`flutter test`)

## 6. Review Copilot Suggestions
Use `pull_request_read` with method `get_review_comments` to fetch Copilot feedback.

## 7. Implement Approved Fixes
Review each suggestion and implement if approved.

## 8. Merge When Ready
Once CI passes and review is approved, merge the PR.

---

## GitHub MCP Commands Reference

| Action | Tool |
|--------|------|
| Create PR | `create_pull_request` |
| Request review | `request_copilot_review` |
| Get PR diff | `pull_request_read` (method: get_diff) |
| Get comments | `pull_request_read` (method: get_review_comments) |
| Merge PR | `merge_pull_request` |
