# Publishing Guide

Detailed guide for publishing WeWeb custom components via GitHub.

## How WeWeb Publishing Works

```
┌──────────┐     ┌──────────┐     ┌───────────────┐     ┌─────────────┐     ┌──────────┐
│  Local    │     │  GitHub  │     │  WeWeb Hook   │     │  Dashboard  │     │  Live    │
│  Dev      │────►│  Repo    │────►│  Auto Build   │────►│  Version    │────►│  Web-app │
│           │push │          │     │               │     │  Selection  │     │          │
└──────────┘     └──────────┘     └───────────────┘     └─────────────┘     └──────────┘
                                                         (manual step)
```

1. You develop locally with `npm run serve`
2. You push code to a GitHub repository
3. WeWeb detects the push and triggers an automatic build
4. In the WeWeb dashboard, you select which version is active
5. Your live web-app updates with the new component code

**Key insight:** There is no `weweb publish` CLI command. GitHub is the deployment mechanism, and the dashboard is the release gate.

## First-Time Setup

### 1. Prerequisites

```bash
# Verify gh CLI is authenticated
gh auth status

# Verify git is configured
git config user.name
git config user.email

# Verify build passes
npm run build --name=my-component
```

### 2. Create .gitignore

```bash
cat > .gitignore << 'EOF'
node_modules/
dist/
.DS_Store
*.log
.env
EOF
```

### 3. Initialize and Push

```bash
git init
git add -A
git commit -m "Initial commit: my-component WeWeb component"
gh repo create my-component --public --source=. --remote=origin --push
```

### 4. Connect in WeWeb Dashboard

1. Go to your WeWeb project dashboard
2. Navigate to **Custom Code** → **Components**
3. Click **Add Component** → **Source Code**
4. Paste: `https://github.com/YOUR_USERNAME/my-component`
5. Select branch: `main`
6. Wait for the initial build
7. Component appears in the editor — drag it onto any page

## Version Management

### Semantic Versioning (semver)

WeWeb components follow standard semver: `MAJOR.MINOR.PATCH`

| Bump | When | Command | Example |
|------|------|---------|---------|
| **Patch** | Bug fixes, CSS tweaks, typos | `npm version patch` | 1.2.0 → 1.2.1 |
| **Minor** | New properties, features, triggers | `npm version minor` | 1.2.0 → 1.3.0 |
| **Major** | Breaking changes, renamed props, restructured config | `npm version major` | 1.2.0 → 2.0.0 |

### Why `npm version` (Not Manual Edits)

`npm version` is atomic — it does three things in one command:
1. Updates `version` in `package.json`
2. Creates a git commit: `vX.Y.Z`
3. Creates a git tag: `vX.Y.Z`

Manual editing skips the tag, which means:
- No git tag for rollback reference
- Harder to track what version is deployed
- WeWeb may not differentiate builds correctly

### Release Workflow

```bash
# 1. Ensure clean working tree
git status

# 2. Build to verify everything works
npm run build --name=my-component

# 3. Bump version
npm version minor   # creates commit + tag

# 4. Push with tags
git push origin main --tags

# 5. Wait for WeWeb auto-build, then activate in dashboard
```

### Pre-Release Versions

For testing before official release:

```bash
npm version prerelease --preid=beta
# 1.2.0 → 1.2.1-beta.0

npm version prerelease --preid=beta
# 1.2.1-beta.0 → 1.2.1-beta.1
```

## Branch Strategies

### Solo Developer: Main Only

```
main ← everything goes here
```

Best for rapid iteration. Every push triggers a WeWeb build.

```bash
# Work → commit → push
git add -A && git commit -m "Add sorting feature"
npm version minor
git push origin main --tags
```

### Small Team: Main + Dev

```
main ← releases (tracked by WeWeb)
  └── dev ← daily work
```

```bash
# Setup
git checkout -b dev
git push -u origin dev

# Daily work on dev
git add -A && git commit -m "WIP: sorting feature"
git push origin dev

# Release
npm version minor
git push origin dev --tags
gh pr create --base main --head dev --title "Release v1.3.0"
gh pr merge --squash
```

### Team with Reviews: Main + Dev + Features

```
main ← releases
  └── dev ← integration
        ├── feature/sorting
        └── feature/mobile-fix
```

```bash
# Start feature
git checkout dev && git pull
git checkout -b feature/sorting
# ... work ...
git push -u origin feature/sorting
gh pr create --base dev --head feature/sorting

# After merge to dev, release
git checkout dev && git pull
npm version minor
git push origin dev --tags
gh pr create --base main --head dev --title "Release v1.3.0"
```

## Pre-Publish Checklist

Run before every publish:

- [ ] `npm run build --name=COMPONENT_NAME` — passes
- [ ] wwEditor blocks matched (`start` count = `end` count per file)
- [ ] No bare `props.content.` (all use optional chaining `?.`)
- [ ] Package name doesn't contain "ww" or "weweb"
- [ ] Version is a valid semver string
- [ ] Working tree is clean (`git status` shows nothing)
- [ ] All changes are committed and pushed

## Rollback

### Quick Rollback (Dashboard)

1. Go to WeWeb dashboard → **Custom Code** → **Components**
2. Select your component
3. Choose a previous version from the dropdown
4. Web-app immediately reverts

No code changes needed. The old version is still built and available.

### Code Rollback

If you need to fix and re-deploy:

```bash
# Option 1: Revert the last commit
git revert HEAD
npm version patch
git push origin main --tags

# Option 2: Reset to a specific tag
git log --oneline --tags
git checkout v1.2.0
# Create fix branch from here
git checkout -b hotfix/revert-broken-change
# Fix, commit, merge to main
```

## Troubleshooting

### Build Fails on WeWeb Side

- **Cause:** Dependencies not in `package.json`, or build config files present
- **Fix:** Ensure no `webpack.config.js`, `vite.config.js`, etc. Only `@weweb/cli` handles builds
- **Verify locally:** `npm run build --name=COMPONENT_NAME`

### Component Not Updating After Push

- **Cause:** Version wasn't bumped, so WeWeb may serve cached build
- **Fix:** Always `npm version` before pushing

### "Source Code" Option Not Available

- **Cause:** Your WeWeb plan may not support custom coded components
- **Fix:** Verify your WeWeb subscription includes custom component access

### Wrong Branch Tracked

- **Cause:** Dashboard is tracking a different branch than where you pushed
- **Fix:** In dashboard settings, verify the tracked branch matches your push target

### Push Rejected

- **Cause:** Remote has changes you don't have locally
- **Fix:** `git pull --rebase origin main` then push again

### Tag Already Exists

- **Cause:** You ran `npm version` twice without pushing
- **Fix:** Delete the local tag `git tag -d vX.Y.Z` and re-run `npm version`
