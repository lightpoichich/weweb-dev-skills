---
name: weweb-publish
description: Use when publishing a WeWeb component to GitHub, bumping versions, managing branches, or releasing updates. Triggers on publish, release, deploy, version bump, push to production, or GitHub repository setup for WeWeb components.
---

# WeWeb Component Publishing

## Overview

WeWeb uses GitHub as the source of truth for custom component versioning. The publication flow is:

```
GitHub repo → push to branch → WeWeb hook triggers build → Dashboard selects active version → Web-app updated
```

There is no CLI publish command. WeWeb watches your GitHub repo and automatically builds on push. You then select the active version in the WeWeb dashboard manually.

## When to Use

- First-time publish of a new WeWeb component
- Bumping version and pushing an update
- Setting up GitHub repo and branches for a component
- Managing branch strategies (solo vs team)
- User says "publish", "release", "deploy", "push to production", or "version bump"

## When NOT to Use

- Local development and testing (use `npm run serve`)
- Visual QA (use `weweb-visual-qa`)
- Component code changes without publishing intent
- WeWeb dashboard configuration (manual, cannot be automated)

## Source of Truth

The pre-publish checks below validate rules defined in `~/.claude/skills/weweb-component-dev/references/weweb-rules.md`. If you need to understand why a check matters, read that file.

## Prerequisites

Before publishing, verify:

1. **`gh` CLI authenticated** — `gh auth status` should show logged in
2. **`git` configured** — `git config user.name` and `git config user.email` set
3. **Build passes** — `npx weweb build -- name=COMPONENT_NAME type=wwobject` exits cleanly
4. **Clean working tree** — `git status` shows no uncommitted changes

## Pre-Publish Checklist

Run these 6 checks before ANY publish:

```bash
# 1. Build passes
npx weweb build -- name=COMPONENT_NAME type=wwobject

# 2. wwEditor blocks matched
grep -c "wwEditor:start" src/wwElement.vue ww-config.js
grep -c "wwEditor:end" src/wwElement.vue ww-config.js
# Counts must match per file

# 3. Optional chaining audit
grep -n "props\.content\." src/wwElement.vue | grep -v "props\.content\?\."
# Must return empty (no bare props.content. references)

# 4. Package name valid
grep '"name"' package.json
# Must NOT contain "ww" or "weweb"

# 5. Version is set
grep '"version"' package.json
# Must be a valid semver (e.g., "0.1.0", "1.2.3")

# 6. Clean working tree
git status --short
# Must be empty (all changes committed)
```

**If any check fails, fix before proceeding.**

## Auto-Detection: First Publish vs Update

Determine which flow to follow:

```bash
git remote get-url origin 2>/dev/null
```

- **Command fails or no remote** → Flow A (First-Time Publish)
- **Returns a GitHub URL** → Flow B (Update Existing Component)

## Flow A: First-Time Publish

### Step 1: Create .gitignore

```bash
cat > .gitignore << 'EOF'
node_modules/
dist/
.DS_Store
*.log
.env
EOF
```

### Step 2: Initialize Git

```bash
git init
git add -A
git commit -m "Initial commit: COMPONENT_NAME WeWeb component"
```

### Step 3: Create GitHub Repository

```bash
gh repo create COMPONENT_NAME --public --source=. --remote=origin --push
```

Options:
- `--public` for open-source components, `--private` for proprietary
- `--description "Brief description of the component"`

### Step 4: Verify Push

```bash
gh repo view --web
# Opens browser to verify repo exists with code
```

### Step 5: Set Up Branches (if team workflow)

See **Branch Workflow** section below. For solo development, `main` only is sufficient.

### Step 6: Connect to WeWeb Dashboard (MANUAL)

**This step cannot be automated — no public API exists.**

Instruct the user:

> 1. Go to your WeWeb project dashboard
> 2. Navigate to **Custom Code** → **Components**
> 3. Click **Add Component** → **Source Code**
> 4. Paste your GitHub repository URL: `https://github.com/USERNAME/COMPONENT_NAME`
> 5. Select the branch to track (usually `main`)
> 6. WeWeb will trigger an initial build
> 7. Once built, the component appears in the editor's component panel
> 8. Drag and drop it onto any page like a normal element

## Flow B: Update Existing Component

### Step 1: Determine Bump Type

Ask the user or infer from changes:

| Change Type | Bump | Example |
|-------------|------|---------|
| Bug fix, typo, CSS tweak | `patch` | 0.1.0 → 0.1.1 |
| New property, feature, trigger event | `minor` | 0.1.0 → 0.2.0 |
| Breaking change, restructured config, renamed props | `major` | 0.1.0 → 1.0.0 |

### Step 2: Bump Version

```bash
npm version patch   # or minor, or major
```

This command atomically:
- Updates `version` in `package.json`
- Creates a git commit with message `vX.Y.Z`
- Creates a git tag `vX.Y.Z`

### Step 3: Push with Tags

```bash
git push origin main --tags
```

### Step 4: Verify Build

```bash
gh repo view --web
# Check GitHub for the new commit and tag
```

### Step 5: Activate Version in WeWeb Dashboard (MANUAL)

**This step cannot be automated.**

Instruct the user:

> 1. Go to your WeWeb project dashboard
> 2. Navigate to **Custom Code** → **Components**
> 3. Find your component
> 4. The new version should appear after WeWeb's automatic build completes
> 5. Select the new version as active
> 6. Your web-app will update with the new component code

## Flow C: Branch Workflow

Choose a strategy based on team size:

### Simple (Solo Developer)

```
main ← all commits go here directly
```

- Push to `main` triggers WeWeb build
- Use `npm version` for releases
- Best for: solo projects, rapid iteration

### Standard (Small Team)

```
main ← releases only (via PR from dev)
  └── dev ← daily work
```

Setup:
```bash
git checkout -b dev
git push -u origin dev
```

Release process:
```bash
# On dev branch, bump version
npm version minor

# Push dev
git push origin dev --tags

# Create PR to main
gh pr create --base main --head dev --title "Release vX.Y.Z" --body "Release notes here"

# After review, merge
gh pr merge --squash
```

WeWeb tracks `main`, so the build triggers on merge.

### Full (Team with Reviews)

```
main ← releases only
  └── dev ← integration branch
        ├── feature/add-sorting
        ├── feature/fix-mobile
        └── feature/new-chart-type
```

Setup:
```bash
git checkout -b dev
git push -u origin dev
```

Feature workflow:
```bash
# Start feature
git checkout dev
git checkout -b feature/FEATURE_NAME

# Work, commit, push
git push -u origin feature/FEATURE_NAME

# PR to dev
gh pr create --base dev --head feature/FEATURE_NAME --title "Add FEATURE_NAME"

# After merge to dev, release to main
git checkout dev
git pull
npm version minor
git push origin dev --tags
gh pr create --base main --head dev --title "Release vX.Y.Z"
```

## Version Strategy Guide

| Scenario | Bump | Before → After |
|----------|------|----------------|
| Fixed a CSS alignment issue | `patch` | 1.2.0 → 1.2.1 |
| Added a new color property | `minor` | 1.2.0 → 1.3.0 |
| Added a new trigger event | `minor` | 1.2.0 → 1.3.0 |
| Renamed `items` prop to `data` | `major` | 1.2.0 → 2.0.0 |
| Changed array item schema | `major` | 1.2.0 → 2.0.0 |
| Performance optimization, no API change | `patch` | 1.2.0 → 1.2.1 |
| Added responsive breakpoints | `minor` | 1.2.0 → 1.3.0 |
| Initial release | — | 0.1.0 |

**Pre-1.0 convention:** Use `0.x.y` during active development. Bump to `1.0.0` when the component is stable and used in production.

## Dashboard Steps (Manual)

The WeWeb dashboard cannot be automated. These instructions are for the user:

### Adding a New Component
1. Open your WeWeb project dashboard
2. Go to **Custom Code** → **Components**
3. Click **Add Component** → **Source Code**
4. Paste the GitHub repo URL
5. Select the branch (usually `main`)
6. Wait for the initial build to complete
7. The component is now available in the editor

### Changing Active Version
1. Open your WeWeb project dashboard
2. Go to **Custom Code** → **Components**
3. Click on your component
4. Select the desired version from the version dropdown
5. The web-app updates immediately

### Rollback
1. In the dashboard, select a previous version
2. The web-app reverts to that version instantly
3. No code changes needed — just dashboard selection

## Integration with Other Skills

### After Visual QA Pass
When `weweb-visual-qa` reports all tests passing:
1. Run the Pre-Publish Checklist
2. Follow Flow A or B depending on auto-detection
3. Guide user through dashboard steps

### In Orchestrated Development
The `weweb-orchestrator` may include a publish phase:
1. CTO confirms all QA iterations pass
2. CTO invokes publish flow (this skill)
3. Version bump + push + dashboard instructions

## Common Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Push without building first | WeWeb build fails | Always run `npx weweb build -- name=... type=wwobject` before push |
| Forget to bump version | WeWeb may cache old version | Always `npm version` before push |
| Push to wrong branch | WeWeb tracks specific branch | Verify with `git branch --show-current` |
| Edit package.json version manually | No git tag created | Use `npm version` which creates tag + commit |
| Include `node_modules` in repo | Huge repo, build conflicts | Add to `.gitignore` before first commit |
| Use `--private` then share repo URL | Collaborators can't access | Use `--public` or add collaborators |
| Skip dashboard step | Component not updated in web-app | Always complete the manual dashboard step |
| Publish during active QA | Unstable version in production | Complete QA loop before publishing |

## Publish Agent Prompt Template

For use by the orchestrator or as a standalone agent:

```markdown
You are a Publish Agent for a WeWeb custom component.

## Project Context
- **Working directory:** [path to project]
- **Component:** [COMPONENT_NAME]
- **Current version:** [run `grep '"version"' package.json`]

## Task
[First-time publish / Version bump and update]

## Process
1. Run Pre-Publish Checklist (all 6 checks must pass)
2. Auto-detect: `git remote get-url origin` → Flow A or B
3. Execute the appropriate flow
4. Provide dashboard instructions to the user
5. Report: version published, repo URL, next steps

## Important
- Use `gh` CLI for all GitHub operations
- Use `npm version` for version bumps (not manual edits)
- Dashboard steps are MANUAL — provide clear instructions, do not attempt to automate
- Never force-push to main
```
