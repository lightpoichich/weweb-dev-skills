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

## QA Process (7 Steps)

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

### Step 6: Inject Dummy Data

Before running the test matrix, generate and bind realistic dummy data to stress-test the component. **The QA agent must read `ww-config.js` to understand which properties accept data**, then generate context-appropriate datasets.

#### Process

1. **Read `ww-config.js`** — Identify all `Array` properties, their item schemas, and any `Formula` mappings
2. **Analyze component purpose** — Use the component name, property labels, and structure to infer what kind of data it expects
3. **Generate 3 datasets** per Array property:

| Dataset | Purpose | Size | Characteristics |
|---------|---------|------|-----------------|
| **Minimal** | Empty/edge state | 0-1 items | Tests empty state handling, no-data message |
| **Typical** | Normal usage | 5-15 items | Realistic values, mixed lengths, accented chars |
| **Stress** | Volume + edge cases | 50-200 items | Long strings, special chars, extreme numbers, duplicates |

4. **Bind data via editor settings panel** — Click the component, open settings, paste data into the Array property
5. **Screenshot after each dataset** — Capture rendering with each data variant

#### Smart Data Generation Rules

Generate data that **makes sense for the component**:

| Component Type | Dummy Data Examples |
|----------------|---------------------|
| **Chart/Graph** | Sales figures with realistic ranges, dates, categories. Mix positive/negative values. Include outliers. |
| **Data Table** | User records with names (including accented: "Jean-Luc", "Müller"), emails, dates, statuses. Include long values that might overflow. |
| **Calendar** | Events spanning single days, multi-day, overlapping, all-day. Past + future dates. Recurring patterns. |
| **List/Gallery** | Items with varying title lengths (2 chars to 200 chars), missing optional fields, duplicate names. |
| **Form Select** | Options with short/long labels, special characters, numeric values, empty strings. |
| **Tree/Hierarchy** | Nested items with varying depth (1-5 levels), orphan nodes, circular reference attempts. |
| **Map/Geo** | Coordinates across different regions, edge cases (0,0), antipodal points, clustered pins. |

#### Edge Cases to Always Include

- **Empty string** values in text fields
- **null/undefined** for optional fields (tests optional chaining)
- **Very long strings** (200+ chars) to test text overflow/truncation
- **Special characters**: `<script>alert('xss')</script>`, `"quotes"`, `l'apostrophe`, emoji `🎉`
- **Numeric extremes**: 0, -1, 999999, 0.001, NaN-like strings
- **Duplicate IDs** to test uniqueness handling
- **Missing required fields** to test fallback behavior

#### Example: Chart Component Dummy Data

```javascript
// Minimal (empty state)
[]

// Typical (realistic sales data)
[
  { id: "q1", label: "Q1 2024", value: 42500, category: "Revenue" },
  { id: "q2", label: "Q2 2024", value: 38900, category: "Revenue" },
  { id: "q3", label: "Q3 2024", value: -5200, category: "Expenses" },
  { id: "q4", label: "Q4 2024", value: 51000, category: "Revenue" },
  { id: "q5", label: "Q1 2025", value: 0, category: "Pending" },
  { id: "q6", label: "Année précédente — récap.", value: 127400, category: "Revenue" }
]

// Stress (volume + edge cases)
// 100 items with: extreme values, long labels, special chars, missing fields, duplicates
```

### Step 7: Execute Test Matrix

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
| 10 | Dummy data: empty | Bind empty array `[]` + screenshot | Empty state / no-data message, no crash |
| 11 | Dummy data: typical | Bind realistic dataset (5-15 items) + screenshot | Renders correctly with real-world data |
| 12 | Dummy data: stress | Bind large dataset (50-200 items) + screenshot | No crash, acceptable performance, scroll/pagination |
| 13 | Dummy data: edge cases | Bind data with special chars, long strings, nulls | No XSS, no overflow, graceful fallbacks |
| 14 | Dummy data: console errors | `browser_console_messages(level="error")` after all data tests | 0 errors |
| 15 | Post-interaction errors | `browser_console_messages(level="error")` | 0 errors |

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

## Dummy Data in QA Report

When reporting results, include a dedicated section for dummy data testing:

```markdown
## Dummy Data Testing

### Data Generated For
- [Array property name]: [description of what was generated]

### Results
| Dataset | Items | Render | Console Errors | Notes |
|---------|-------|--------|----------------|-------|
| Empty | 0 | PASS/FAIL | 0 | ... |
| Typical | N | PASS/FAIL | 0 | ... |
| Stress | N | PASS/FAIL | 0 | ... |
| Edge cases | N | PASS/FAIL | 0 | ... |

### Edge Cases Tested
- [ ] Empty strings
- [ ] Special characters / XSS attempts
- [ ] Very long strings (200+ chars)
- [ ] Null/undefined optional fields
- [ ] Numeric extremes (0, negative, very large)
- [ ] Duplicate IDs
- [ ] Missing required fields
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
