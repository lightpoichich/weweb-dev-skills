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

### Browser Configuration (One-Time Setup)

For the best QA experience, configure the Playwright MCP plugin with a **persistent browser profile** and **1080p viewport**. This saves login sessions across Claude Code sessions (including Google Sign-In) and starts the browser at full workspace size.

Edit the Playwright plugin MCP config (find the path with `find ~/.claude/plugins -name ".mcp.json" -path "*/playwright/*"`):

```json
{
  "playwright": {
    "command": "npx",
    "args": [
      "@playwright/mcp@latest",
      "--user-data-dir", "~/.playwright-weweb",
      "--viewport-size", "1920x1080"
    ]
  }
}
```

- `--user-data-dir` keeps cookies/sessions alive — log in once (email/password or Google), and the session persists across sessions.
- `--viewport-size` starts the browser at 1920×1080 directly, no resize needed.
- The plugin cache path contains a hash that changes on plugin updates. If login stops working after an update, re-apply this config.

**Optional — auto-login credentials:** For fully automated login when the session expires, set environment variables:
```bash
export WEWEB_EMAIL="your@email.com"
export WEWEB_PASSWORD="your-password"
```
If set, the QA process fills the WeWeb login form automatically when needed. Without them, you'll be prompted to log in manually.

### Playwright Permissions

The QA process makes many Playwright tool calls (navigate, click, screenshot, resize...). Approving each one individually is impractical. The skill handles this automatically — see Step 0 below.

## QA Process (9 Steps)

### Step 0: Ensure Playwright Permissions

Before anything else, ensure the project's `.claude/settings.local.json` has a wildcard permission for all Playwright tools. This persists across sessions — you only need to set it once per project.

1. Read `.claude/settings.local.json` (create the file and `.claude/` directory if they don't exist)
2. Check if `"mcp__plugin_playwright_playwright__*"` is already in `permissions.allow`
3. If not present, add it to the `allow` array. If the file is new, create it with:
```json
{
  "permissions": {
    "allow": [
      "mcp__plugin_playwright_playwright__*"
    ]
  }
}
```
4. If existing individual Playwright permissions are present (e.g., `mcp__plugin_playwright_playwright__browser_navigate`), they can be left as-is — the wildcard covers them all.

This eliminates all Playwright permission prompts for the rest of the project.

### Step 1: Start Dev Server
```bash
npm run serve --port=PORT
```
Verify: `curl -sk https://localhost:PORT/ -o /dev/null -w "%{http_code}"` (expect 200)

### Step 1b: Verify Browser Viewport

If the Playwright MCP is configured with `--viewport-size 1920x1080` (see Prerequisites), the browser already has the right size — skip this step.

Otherwise, resize the browser to at least 1920×1080 for comfortable WeWeb editor use:

```bash
# macOS: detect actual screen resolution (optional, for full-screen)
system_profiler SPDisplaysDataType | grep Resolution
```

Then `browser_resize(width, height)` — use the detected resolution or default to `browser_resize(1920, 1080)`. This must be done before navigating to the editor.

### Step 2: Accept SSL Certificate in Playwright Browser
1. `browser_navigate("https://localhost:PORT/")` — will fail with ERR_CERT_AUTHORITY_INVALID
2. Chrome "Your connection is not private" interstitial page will show
3. Type `thisisunsafe` using `browser_press_key` for each character: t-h-i-s-i-s-u-n-s-a-f-e
4. Page auto-navigates to dev server showing "Server and SSL OK"

### Step 3: Navigate to Dev Editor & Authenticate

```
browser_navigate("https://editor-dev.weweb.io/PROJECT_ID")
```
**IMPORTANT:** Use `editor-dev.weweb.io` (NOT `editor.weweb.io`). Only the dev editor supports local component loading.

#### 3a. Check if Login is Required

After navigation, take a `browser_snapshot()` and check the current URL:
- If the URL contains the project editor path → **logged in, proceed to Step 4**
- If redirected to a login/auth page (URL contains `auth`, `login`, or `sign-in`) → **continue to 3b**

With a persistent browser profile (`--user-data-dir`), login is usually still active from a previous session. If the session has expired, continue below.

#### 3b. Automated Login (if credentials available)

Check if `WEWEB_EMAIL` and `WEWEB_PASSWORD` environment variables are set:

```bash
echo "${WEWEB_EMAIL:+set}" "${WEWEB_PASSWORD:+set}"
```

**If credentials are available:**
1. `browser_snapshot()` to identify the login form fields
2. Find and fill the email input field using `browser_click` on the field + `browser_type` with `WEWEB_EMAIL`
3. Find and fill the password input field the same way
4. Click the login/submit button
5. `browser_wait_for("navigation")` — wait for redirect back to the editor
6. `browser_snapshot()` to verify the editor has loaded

**If credentials are NOT available (manual fallback):**

Pause and inform the user:
> "Veuillez vous connecter à WeWeb dans la fenêtre Playwright, puis dites-moi quand c'est fait."

Wait for user confirmation, then `browser_snapshot()` to verify the editor is loaded before continuing.

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

#### Post-Change Verification Sequence

After any code change (HMR takes 1-3s), **always follow this order** before taking screenshots:

```
1. Wait for HMR to settle (2s minimum)
2. browser_evaluate: Check computed styles (catches inline override issues)
3. browser_evaluate: Check element positions and visibility
4. browser_take_screenshot: Visual confirmation
5. browser_console_messages: Check for errors (filter WeWeb noise — see 8c)
```

**Don't skip evaluate checks.** Screenshots alone can miss:
- Elements positioned behind the sidebar panel
- Elements with `opacity: 0` or `display: none`
- CSS rules silently overridden by WeWeb inline styles
- Elements at wrong coordinates but visually overlapping other content

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

**Console Error Filtering — WeWeb editor generates noise that must be ignored:**

| Ignore (editor internals) | Flag (real component bugs) |
|---------------------------|---------------------------|
| `[Vue warn]: Property "$attrsWithoutClick"` | `TypeError: Cannot read properties of undefined` |
| `[Vue warn]: Missing required prop: "item"` | `SyntaxError: Unexpected token` |
| `No codicon found for CompletionItemKind` | `ReferenceError: xxx is not defined` |
| Any URL containing `editor-dev-cdn.weweb.io` | Any error from `localhost:PORT` or component source |

## Technical Details

### Iframe & DOM Access

- **Component rendering**: Inside iframe `#ww-manager-iframe` (frame name: `ww-manager-iframe`)
- **Accessing component DOM**: Two approaches:
  ```js
  // Approach 1: via browser_evaluate on parent page
  const iframe = document.querySelector('#ww-manager-iframe');
  const iframeDoc = iframe?.contentDocument;
  const el = iframeDoc.querySelector('.my-component');
  return window.getComputedStyle(el).paddingLeft;

  // Approach 2: via contentFrame locator
  page.locator('#ww-manager-iframe').contentFrame().locator('.my-class')
  ```
- **Iframe element refs** in snapshots have a `f12e` prefix (e.g. `f12e84`). Main page refs are plain (e.g. `e2722`). Don't mix them.
- **Snapshot staleness**: After any interaction (click, type, navigate), always take a fresh snapshot before using refs.

### Component Selection

- **Don't click the root element** in the canvas — you'll often select the parent (Section, Div) instead
- **Click a specific identifiable child** inside the iframe (e.g. `.apexcharts-canvas`, a button with a unique class)
- After clicking, verify selection by checking the right panel title matches your component name

### Settings Panel

- Click "Edit" button in top toolbar (next to "AI") to enter Edit mode, then click component in canvas to open its settings in the right sidebar
- Right panel shows three tabs as a `radiogroup`: **Style**, **Settings**, **Workflows** — click `radio "Settings"` for component properties
- Properties may require scrolling. Playwright auto-scrolls to elements when clicking refs.
- **Component cannot run standalone**: Needs WeWeb runtime (wwLib, Vue 3)
- **Snapshot for selectors**: `browser_snapshot()` returns accessibility tree with refs. WeWeb editor snapshots are large (50-80KB).

### WeWeb Inline Style Override (CRITICAL)

WeWeb injects inline styles on the **root element** of every component:
```
style="margin: 0px; padding: 0px; z-index: unset; align-self: unset; display: block; ..."
```

**Consequence:** Any CSS targeting the root `<div>` (`padding`, `margin`, etc.) will be silently overridden by inline styles, regardless of specificity.

**QA verification pattern:**
```js
// In browser_evaluate — detect inline style override
const iframe = document.querySelector('#ww-manager-iframe');
const iframeDoc = iframe?.contentDocument;
const root = iframeDoc.querySelector('.my-component-root');
const inlineStyle = root.getAttribute('style');       // Shows WeWeb overrides
const computed = window.getComputedStyle(root).paddingLeft; // "0px" even if CSS says 25px
return { inlineStyle, computed };
```

If a CSS rule appears broken, check if it targets the root element. **Fix: always style an inner child, never the root.**

### Monaco Editor Interaction (Script Properties)

WeWeb `Script`-type properties render as Monaco editor widgets. Standard Playwright clicks will **timeout** because `.view-line` divs intercept pointer events.

**Working pattern:**
```js
// browser_run_code
async (page) => {
  // Step 1: Find Monaco editor coordinates via evaluate
  const rect = await page.evaluate(() => {
    const editors = document.querySelectorAll('.monaco-editor');
    const r = editors[0].getBoundingClientRect(); // [0] = first Script property
    return { left: r.left, top: r.top, width: r.width, height: r.height };
  });

  // Step 2: Click at center coordinates
  await page.mouse.click(rect.left + rect.width / 2, rect.top + rect.height / 2);

  // Step 3: Select all + delete + type new content
  await page.keyboard.press('Meta+a');
  await page.keyboard.press('Backspace');
  await page.keyboard.type('{"bar":{"horizontal":true}}', { delay: 20 });

  // Step 4: Click outside to trigger evaluation
  await page.mouse.click(rect.left + rect.width + 50, rect.top);
}
```

If multiple Script properties exist, index `editors[0]`, `editors[1]`, etc. in DOM order (matches `ww-config.js` order).

**Note:** Script property values are stored as `{code: "..."}` wrapper objects, NOT evaluated values. Components must handle this wrapper (parse `val.code` if it's a string).

### CSS Verification via Evaluate

For pixel-precise checks, don't rely solely on screenshots:

```js
// Comprehensive verification pattern
() => {
  const iframe = document.querySelector('#ww-manager-iframe');
  const iframeDoc = iframe?.contentDocument;
  const wrapper = iframeDoc.querySelector('.component-wrapper');

  // Check computed styles
  const computed = window.getComputedStyle(wrapper);

  // Check element positions
  const buttons = iframeDoc.querySelectorAll('.my-button');
  const positions = Array.from(buttons).map((btn, i) => ({
    index: i,
    rect: btn.getBoundingClientRect(),
    opacity: window.getComputedStyle(btn).opacity,
    display: window.getComputedStyle(btn).display,
  }));

  // Check inline style interference
  const inlineStyle = wrapper.getAttribute('style');

  return { padding: computed.paddingLeft, positions, inlineStyle };
}
```

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
- **Auth expired**: With `--user-data-dir` configured, sessions persist across runs. If expired, the skill auto-fills login if `WEWEB_EMAIL`/`WEWEB_PASSWORD` are set, otherwise prompts for manual login
- **CSS not applying on root element**: WeWeb injects inline styles on root `<div>` — never style root, always target inner children (see Technical Details > Inline Style Override)
- **Monaco editor click timeout**: Script property editors intercept pointer events — use `page.mouse.click` at computed coordinates (see Technical Details > Monaco Editor)
- **Stale DOM after HMR**: After code changes, wait 2s minimum before measuring. Chart libraries may re-animate. Use `waitForTimeout(2000)` before evaluate/screenshot.
- **Left sidebar hides component**: Components at x=0 may be behind the sidebar. Collapse sidebar or screenshot just the iframe element.

### Session Recovery

If the Playwright browser shows `about:blank` or the session is lost:
1. Navigate to `https://localhost:PORT/` — SSL page
2. Type `thisisunsafe` to bypass certificate
3. Navigate to `https://editor-dev.weweb.io/PROJECT_ID`
4. Check if login is needed (see Step 3a/3b) — with `--user-data-dir`, sessions usually persist
5. **Re-configure all settings** — property values set via the settings panel are lost on session expiry. The component code still loads from dev server, but runtime property values need to be re-set.
6. Verify dev server is still running: `curl -sk https://localhost:PORT/ -o /dev/null -w "%{http_code}"` (expect 200)

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
