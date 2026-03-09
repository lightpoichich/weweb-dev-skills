---
name: weweb-visual-qa
description: Visual QA for WeWeb custom components using Playwright MCP. Use after modifying wwElement.vue or ww-config.js to validate rendering, interactions, and responsiveness in the WeWeb editor.
---

# WeWeb Visual QA with Playwright MCP

## When to Trigger

- After modifying `src/wwElement.vue` or `ww-config.js`
- After adding new features (drag handles, delete buttons, dropzones, etc.)
- Before publishing a new version of a coded component
- When debugging visual issues reported by users

## Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `PORT` | Local dev server port | `8080` |
| `PROJECT_ID` | WeWeb project UUID (from editor URL) | `b413e1c2-...` |
| `COMPONENT_NAME` | Component name as registered in WeWeb | `my-custom-chart` |

These parameters must be known before running QA. They appear as placeholders throughout this document.

## Prerequisites

- Dev server running: `npm run serve --port=PORT`
- WeWeb project ID known (found in editor URL: `editor-dev.weweb.io/PROJECT_ID`)
- User logged into WeWeb in the Playwright browser session

## QA Process (6 Steps)

### Step 1: Start Dev Server
```bash
npm run serve --port=PORT
```
Verify: `curl -sk https://localhost:PORT/ -o /dev/null -w "%{http_code}"` (expect 200)

### Step 2: Accept SSL Certificate in Playwright Browser
1. `browser_navigate("https://localhost:PORT/")` — will fail with ERR_CERT_AUTHORITY_INVALID
2. Chrome "Your connection is not private" interstitial page will show
3. Type `thisisunsafe` using `browser_press_key` for each character: t-h-i-s-i-s-u-n-s-a-f-e
4. Page auto-navigates to dev server showing "Server and SSL OK"

### Step 3: Navigate to Dev Editor
```
browser_navigate("https://editor-dev.weweb.io/PROJECT_ID")
```
**IMPORTANT:** Use `editor-dev.weweb.io` (NOT `editor.weweb.io`). Only the dev editor supports local component loading.

If redirected to login page, user must authenticate manually.

### Step 4: Register Local Component
1. Click "Dev" button in top nav bar
2. Click "Add local element" button
3. Select "Custom" from Element dropdown
4. Enter component name: `COMPONENT_NAME` (from `package.json` `name` field)
5. Port should auto-fill — verify it shows `PORT` and status reads "Successfully connected to server."
6. Click "Save"
7. Editor reloads with toast: "Component [name] loaded for development."

### Step 5: Add Component to Page
1. Click "Dev" in top nav to open Dev panel
2. Find component in "Localhost" section
3. Click on the component — message "Drag and drop the element in the page" appears
4. **Use manual mouse API for drag-drop** (sidebar intercepts standard drag events):

```javascript
// browser_run_code
async (page) => {
  const source = page.locator('div').filter({ hasText: /^COMPONENT_NAME - PORT$/ }).nth(1);
  const sourceBox = await source.boundingBox();
  const iframe = page.locator('#ww-manager-iframe');
  const iframeBox = await iframe.boundingBox();

  const startX = sourceBox.x + sourceBox.width / 2;
  const startY = sourceBox.y + sourceBox.height / 2;
  const endX = iframeBox.x + iframeBox.width / 2;
  const endY = iframeBox.y + iframeBox.height / 2;

  await page.mouse.move(startX, startY);
  await page.mouse.down();
  await page.mouse.move(startX + 10, startY, { steps: 3 });
  await page.mouse.move(endX, endY, { steps: 20 });
  await page.waitForTimeout(500);
  await page.mouse.up();
}
```
5. Verify component renders in the canvas

### Step 6: Execute Test Matrix

| # | Test | Method | Expected |
|---|------|--------|----------|
| 1 | Default render | `browser_take_screenshot` | Component visible, no errors |
| 2 | Console errors | `browser_console_messages(level="error")` | 0 errors |
| 3 | Responsive 1280px | `browser_resize(1280, 720)` + screenshot | No overflow |
| 4 | Responsive 768px | `browser_resize(768, 1024)` + screenshot | Adapts correctly |
| 5 | Responsive 375px | `browser_resize(375, 667)` + screenshot | Mobile OK |
| 6 | Click interaction | Click on interactive element + screenshot | Expected feedback |
| 7 | Hover tooltip | Hover on element + screenshot | Tooltip visible |
| 8 | Feature toggle | Enable feature via settings + screenshot | Feature renders |
| 9 | Property change | Change prop via settings + screenshot | Updates in realtime |
| 10 | Post-interaction errors | `browser_console_messages(level="error")` | 0 errors |

## Technical Details

- **Component rendering**: Inside iframe `#ww-manager-iframe`
- **Accessing component DOM**: Use `browser_evaluate` with frame context
- **Settings panel**: Click component in canvas, then use right sidebar
- **Snapshot for selectors**: `browser_snapshot()` returns accessibility tree with refs
- **Component cannot run standalone**: Needs WeWeb runtime (wwLib, Vue 3)

## QA Report Format

```markdown
# Visual QA Report — COMPONENT_NAME

**Date:** YYYY-MM-DD
**Component:** COMPONENT_NAME
**Port:** PORT
**Project:** PROJECT_ID
**Status:** PASS / FAIL

## Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | Default render | PASS/FAIL | ... |
| 2 | Console errors | PASS/FAIL | ... |
| ... | ... | ... | ... |

## Issues Found

### BLOCKING
- (none or list)

### IMPORTANT
- (none or list)

### LOW
- (none or list)

### INFO
- (none or list)

## Screenshots
- (paths to saved screenshots)
```

## Iteration Loop

1. Run QA (this skill)
2. If issues found → create bug report with screenshots
3. Fix agent implements fixes
4. Re-run QA (max 3 iterations)
5. If all pass → ready for commit/publish

## Common Pitfalls

- **SSL cert not accepted**: Must type `thisisunsafe` on EACH new Playwright session
- **Wrong editor URL**: `editor.weweb.io` won't have Dev panel — use `editor-dev.weweb.io`
- **Drag-drop fails**: Sidebar panel intercepts standard events — must use manual `page.mouse` API
- **Component not in Localhost**: Check that port matches and server shows "Successfully connected"
- **Auth expired**: User must re-login manually in the Playwright browser

## Integration with Orchestrator

When dispatched by the CTO agent (via `weweb-orchestrator` skill):

1. **Receive context**: The CTO provides `PROJECT_ID`, `COMPONENT_NAME`, `PORT`, and a list of features to test
2. **Execute full QA process**: Follow Steps 1-6 above with the provided parameters
3. **Write structured report**: Save to `docs/qa-report.md` using the QA Report Format above
4. **Classify issues by severity**:
   - **BLOCKING** — crashes, doesn't render, editor errors
   - **IMPORTANT** — broken feature, visual regression
   - **LOW** — cosmetic, minor layout
   - **INFO** — suggestion, enhancement idea
5. **Return to CTO**: Report back with summary: pass/fail, number of issues by severity, blocking items
6. **Fix loop**: CTO may dispatch fix agents and re-trigger QA (max 3 iterations total)

### QA Agent Prompt Template (for CTO to use)

```
You are a QA Agent testing a WeWeb custom component.

**Component:** COMPONENT_NAME
**Port:** PORT
**Project:** PROJECT_ID
**Features to test:** [list from CTO]

Follow the weweb-visual-qa skill process:
1. Accept SSL cert at https://localhost:PORT/
2. Navigate to https://editor-dev.weweb.io/PROJECT_ID
3. Register and add the component
4. Execute the full test matrix
5. Write report to docs/qa-report.md
6. Report back: PASS/FAIL + issue summary
```
