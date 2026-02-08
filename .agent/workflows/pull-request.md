---
description: Create PR and request GitHub Copilot review
---

# Pull Request Workflow

Follow these steps to create a PR with automated Copilot review.

> **⚠️ ALWAYS analyze Copilot comments before implementing!**  
> Not all suggestions should be fixed immediately. Categorize as:
> - ✅ **Implement**: Easy fixes, real bugs, clean code improvements  
> - ⏸️ **Defer**: Complex changes, MVP-priority items, Phase 3 territory

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
- **Base branch:** develop (or main)
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

## 8. ⚠️ IMPORTANT: Re-Request Copilot Review After Fixes
> **ALWAYS request Copilot review again after pushing fixes!**
> Copilot often finds additional issues on subsequent reviews.

After pushing fixes:
1. Use `request_copilot_review` tool again
2. Wait for new review
3. Repeat steps 6-8 until Copilot has no more comments

## 9. Merge When Ready
Once CI passes and review is approved, merge the PR.

---

## Async Review Workflow (Week N + Week N+1)

For continuing work while reviews are pending:

1. **Merge Week N PR** when core functionality works
2. **Create new branch** for Week N+1 from main
3. **If Copilot reviews old code**, create small fix PRs
4. **Keep Week N+1 rebased** on main to get fixes

```
main ──────●───────────●──────────●────────>
           │           │          │
           │ week3-fix │          │
           └───●───────┘          │
                                  │
feature/week4 ────────────────────┴──────>
                              (rebase)
```

---

## GitHub MCP Commands Reference

| Action | Tool |
|--------|------|
| Create PR | `create_pull_request` |
| Request review | `request_copilot_review` |
| Get PR diff | `pull_request_read` (method: get_diff) |
| Get comments | `pull_request_read` (method: get_review_comments) |
| Merge PR | `merge_pull_request` |
