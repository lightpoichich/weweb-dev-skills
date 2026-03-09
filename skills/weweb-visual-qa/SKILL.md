---
name: weweb-visual-qa
description: Visual QA for WeWeb custom components using Playwright MCP. Use after modifying wwElement.vue or ww-config.js to validate rendering, interactions, and responsiveness in the WeWeb editor.
allowed-tools: ["mcp__plugin_playwright_playwright__*"]
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

### Playwright Permissions

The QA process makes many Playwright tool calls (navigate, click, screenshot, resize...). To avoid approving each one individually:

**Option 1 (recommended):** When Claude Code prompts for the first Playwright tool, select **"Allow all tools from this MCP server"** to approve all Playwright actions for the session.

**Option 2:** This skill declares `allowed-tools: ["mcp__plugin_playwright_playwright__*"]` in its frontmatter, which pre-authorizes all Playwright tools when the skill is invoked. If your Claude Code configuration respects skill-level `allowed-tools`, no manual approval is needed.

**Option 3:** Run Claude Code with `--dangerously-skip-permissions` flag (not recommended for general use, but convenient for QA-only sessions).

## QA Process (8 Steps)

### Step 1: Start Dev Server
```bash
npm run serve --port=PORT
```
Verify: `curl -sk https://localhost:PORT/ -o /dev/null -w "%{http_code}"` (expect 200)

### Step 1b: Maximize Browser to Screen Size

Detect the user's screen resolution and resize the Playwright browser to fill the full screen. This gives maximum space in the WeWeb editor.

```bash
# macOS: detect screen resolution
system_profiler SPDisplaysDataType | grep Resolution
```

Then use `browser_resize(width, height)` with the detected resolution (e.g., `browser_resize(1920, 1080)`). This must be done before navigating to the editor.

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

### Step 6: Generate Component-Specific Test Plan

Before testing, the QA agent MUST analyze the component source code to generate a tailored test plan. Generic tests miss component-specific behavior — this step ensures every feature, interaction, and edge case is covered.

**IMPORTANT:** You must first click the **"Edit"** button in the top toolbar (next to "AI") to enter Edit mode. Only then will the settings/properties panel be accessible in the right sidebar when you select a component.

#### 6a. Read Source Files

Read both `ww-config.js` and `src/wwElement.vue` and extract:

| Source | What to Extract |
|--------|-----------------|
| **`ww-config.js` — properties** | All property names, types (`Text`, `Number`, `Color`, `Array`, `OnOff`, `TextSelect`...), default values, conditional visibility (`hidden` expressions) |
| **`ww-config.js` — triggerEvents** | All trigger events (click, hover, selection change...) — each one needs a test |
| **`ww-config.js` — sections/blocks** | Feature groups, conditional sections — each toggleable feature needs a test |
| **`wwElement.vue` — template** | Interactive elements (`@click`, `@mouseenter`, `@input`, `v-if`/`v-show` conditionals, `v-for` loops, slots, dropzones) |
| **`wwElement.vue` — script** | Computed props, watchers, emits, internal variables (`wwLib.wwVariable`), external library usage |
| **`wwElement.vue` — style** | Media queries, CSS custom properties, overflow handling, fixed dimensions |

#### 6b. Generate Test Scenarios

Based on the analysis, generate **component-specific test scenarios** organized by category:

**Property tests** — One test per property type:
- For each `OnOff` toggle: enable/disable and verify visual change
- For each `Color` prop: change color and verify it applies
- For each `TextSelect`: switch between each option and verify
- For each `Number` prop: test min, max, and typical values
- For each `Array` prop: test with dummy data (see Step 7)
- For each conditionally hidden property: toggle the parent and verify child appears/disappears

**Interaction tests** — One test per trigger event:
- For each `triggerEvent`: perform the action that fires it and verify the expected visual feedback
- Example: if `click:row` exists → click a row, verify selection highlight
- Example: if `change:sort` exists → click a column header, verify sort indicator

**Feature toggle tests** — One test per toggleable feature:
- For each `OnOff` property that controls a feature block (e.g., `showLegend`, `enablePagination`): toggle on, verify feature renders, toggle off, verify it disappears

**State tests** — Based on component logic:
- Empty state (no data)
- Loading state (if applicable)
- Error state (if applicable)
- Overflow state (too much content)

**Responsive tests** — Always included:
- Desktop, tablet, mobile via WeWeb breakpoint buttons

#### 6c. Write the Test Plan

Output the generated test plan as a numbered list before executing. Format:

```markdown
## Component-Specific Test Plan — COMPONENT_NAME

### Properties (N tests)
1. Toggle `showHeader` ON → header row visible
2. Toggle `showHeader` OFF → header row hidden
3. Change `primaryColor` to #ff0000 → theme updates
...

### Interactions (N tests)
10. Click on data row → `click:row` fires, row highlights
11. Hover on bar → tooltip appears with value
...

### Feature Toggles (N tests)
15. Enable `pagination` → page controls appear at bottom
16. Disable `pagination` → all rows visible, no controls
...

### Data & Edge Cases (N tests)
20. Empty array → "No data" message displayed
21. Typical dataset (10 items) → all rows render
22. Stress dataset (100 items) → pagination or scroll, no crash
...

### Responsive (3 tests)
25. Desktop breakpoint → full layout
26. Tablet breakpoint → adapted layout
27. Mobile breakpoint → stacked/scrollable layout

**Total: N tests**
```

### Step 7: Inject Dummy Data

Generate and bind realistic dummy data to stress-test the component. **Use the property analysis from Step 6a** — you already know the Array schemas.

#### Process

1. **Generate 3 datasets** per Array property:

| Dataset | Purpose | Size | Characteristics |
|---------|---------|------|-----------------|
| **Minimal** | Empty/edge state | 0-1 items | Tests empty state handling, no-data message |
| **Typical** | Normal usage | 5-15 items | Realistic values, mixed lengths, accented chars |
| **Stress** | Volume + edge cases | 50-200 items | Long strings, special chars, extreme numbers, duplicates |

2. **Bind data via editor settings panel** — Click the component, open settings, paste data into the Array property
3. **Screenshot after each dataset** — Capture rendering with each data variant

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

### Step 8: Execute Test Plan

Execute the test plan generated in Step 6, **not a fixed generic matrix**. The tests are split into two parts:

#### 8a. Base Tests (always run)

| # | Test | Method | Expected |
|---|------|--------|----------|
| 1 | Default render | `browser_take_screenshot` | Component visible, no errors |
| 2 | Console errors (idle) | `browser_console_messages(level="error")` | 0 errors |
| 3 | Responsive desktop | Click desktop breakpoint button in WeWeb toolbar + screenshot | No overflow |
| 4 | Responsive tablet | Click tablet breakpoint button in WeWeb toolbar + screenshot | Adapts correctly |
| 5 | Responsive mobile | Click mobile breakpoint button in WeWeb toolbar + screenshot | Mobile OK |

#### 8b. Component-Specific Tests (from Step 6c)

Execute every test from the generated plan:
- **Property tests** — Change each prop in the settings panel, screenshot, verify
- **Interaction tests** — Perform each user action, screenshot, verify visual feedback
- **Feature toggle tests** — Toggle on/off, screenshot each state
- **Data tests** — Bind each dummy dataset from Step 7, screenshot, verify

#### 8c. Final Console Check

| # | Test | Method | Expected |
|---|------|--------|----------|
| N-1 | Console errors (post-data) | `browser_console_messages(level="error")` after all data tests | 0 errors |
| N | Console errors (post-interaction) | `browser_console_messages(level="error")` after all interaction tests | 0 errors |

## Technical Details

- **Component rendering**: Inside iframe `#ww-manager-iframe`
- **Accessing component DOM**: Use `browser_evaluate` with frame context
- **Settings panel**: Click "Edit" button in top toolbar (next to "AI") to enter Edit mode, then click component in canvas to open its settings in the right sidebar
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
**Total tests:** N (5 base + N component-specific)

## Component Analysis Summary
- **Properties found:** N (list key ones)
- **Trigger events:** N (list all)
- **Toggleable features:** N (list all)
- **Array properties:** N (for dummy data)

## Base Test Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | Default render | PASS/FAIL | ... |
| 2 | Console errors (idle) | PASS/FAIL | ... |
| 3 | Responsive desktop | PASS/FAIL | ... |
| 4 | Responsive tablet | PASS/FAIL | ... |
| 5 | Responsive mobile | PASS/FAIL | ... |

## Component-Specific Test Results

### Property Tests
| # | Test | Result | Notes |
|---|------|--------|-------|
| 6 | Toggle `showHeader` ON/OFF | PASS/FAIL | ... |
| ... | ... | ... | ... |

### Interaction Tests
| # | Test | Result | Notes |
|---|------|--------|-------|
| N | Click row → `click:row` fires | PASS/FAIL | ... |
| ... | ... | ... | ... |

### Feature Toggle Tests
| # | Test | Result | Notes |
|---|------|--------|-------|
| N | Enable/disable `pagination` | PASS/FAIL | ... |
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
5. If all pass → ready for commit/publish (see `weweb-publish` skill for GitHub publishing workflow)

## Common Pitfalls

- **SSL cert not accepted**: Must type `thisisunsafe` on EACH new Playwright session
- **Wrong editor URL**: `editor.weweb.io` won't have Dev panel — use `editor-dev.weweb.io`
- **Drag-drop fails**: Sidebar panel intercepts standard events — must use manual `page.mouse` API
- **Component not in Localhost**: Check that port matches and server shows "Successfully connected"
- **Auth expired**: User must re-login manually in the Playwright browser

## Integration with Orchestrator

When dispatched by the CTO agent (via `weweb-orchestrator` skill):

1. **Receive context**: The CTO provides `PROJECT_ID`, `COMPONENT_NAME`, `PORT`, and a list of features to test
2. **Execute full QA process**: Follow Steps 1-8 above with the provided parameters
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
4. Read ww-config.js + wwElement.vue → generate component-specific test plan
5. Click "Edit" in toolbar, inject dummy data, execute all tests (base + specific)
6. Write report to docs/qa-report.md
7. Report back: PASS/FAIL + issue summary
```
