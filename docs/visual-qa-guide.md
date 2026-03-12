# Visual QA Guide

Detailed guide for using the `weweb-visual-qa` skill to test WeWeb custom components with Playwright MCP.

## Overview

WeWeb custom components can't be tested with standard unit test frameworks — they require the WeWeb runtime (wwLib, Vue 3 injection). Visual QA via Playwright MCP solves this by testing directly in the WeWeb editor.

## Setting Up the Dev Environment

### 1. Start the Dev Server

```bash
npm run serve --port=8080
```

Verify it's running:
```bash
curl -sk https://localhost:8080/ -o /dev/null -w "%{http_code}"
# Expected: 200
```

The dev server uses HTTPS with a self-signed certificate. This is normal.

### 2. Playwright MCP Plugin

Ensure the Playwright MCP plugin is configured in your Claude Code settings. It provides browser automation tools:
- `browser_navigate` — Navigate to URLs
- `browser_take_screenshot` — Capture the current page
- `browser_click` — Click elements
- `browser_snapshot` — Get accessibility tree
- `browser_resize` — Change viewport size
- `browser_console_messages` — Read console output
- `browser_press_key` — Send keyboard input
- `browser_run_code` — Execute JavaScript in page context

## Understanding WeWeb Editor Dev Mode

The WeWeb editor has a special "Dev" mode (`editor-dev.weweb.io`) that supports loading local components:

1. **Dev panel** — Accessible via the "Dev" button in the top nav bar
2. **Localhost section** — Shows components loaded from your local dev server
3. **Component registration** — Name + port must match your dev server
4. **Hot reload** — Changes to `wwElement.vue` auto-refresh in the editor

**Critical:** Always use `editor-dev.weweb.io`, never `editor.weweb.io`. The standard editor doesn't have the Dev panel.

## SSL Certificate Handling

Each new Playwright browser session starts fresh — it doesn't remember certificate exceptions.

### The `thisisunsafe` Technique

1. Navigate to `https://localhost:PORT/`
2. Chrome shows "Your connection is not private" (ERR_CERT_AUTHORITY_INVALID)
3. Type `thisisunsafe` character by character using `browser_press_key`
4. Chrome automatically accepts the certificate and loads the page

```javascript
// Using browser_press_key for each character:
// t, h, i, s, i, s, u, n, s, a, f, e
```

This must be done at the start of every Playwright session. The certificate acceptance persists for the session duration.

## Drag-Drop Technique

The WeWeb editor sidebar intercepts standard HTML5 drag events. To place a component on the canvas, use the manual mouse API:

```javascript
async (page) => {
  // Find the component in the Dev panel
  const source = page.locator('div').filter({ hasText: /^COMPONENT_NAME - PORT$/ }).nth(1);
  const sourceBox = await source.boundingBox();

  // Find the canvas iframe
  const iframe = page.locator('#ww-manager-iframe');
  const iframeBox = await iframe.boundingBox();

  // Calculate coordinates
  const startX = sourceBox.x + sourceBox.width / 2;
  const startY = sourceBox.y + sourceBox.height / 2;
  const endX = iframeBox.x + iframeBox.width / 2;
  const endY = iframeBox.y + iframeBox.height / 2;

  // Execute drag sequence
  await page.mouse.move(startX, startY);
  await page.mouse.down();
  await page.mouse.move(startX + 10, startY, { steps: 3 });  // Initial movement to trigger drag
  await page.mouse.move(endX, endY, { steps: 20 });           // Smooth drag to canvas
  await page.waitForTimeout(500);                               // Wait for drop zone detection
  await page.mouse.up();
}
```

**Key points:**
- The initial small move (10px) is needed to trigger the drag detection
- `steps: 20` creates a smooth movement that the editor can track
- The 500ms wait ensures the drop zone is ready before releasing

## Writing Effective Test Matrices

### Test Structure: Base + Component-Specific

Tests are split into two categories:

#### Base Tests (always run, same for every component)

| Category | Tests | Purpose |
|----------|-------|---------|
| **Rendering** | Default render, default props | Component loads without errors |
| **Responsiveness** | Desktop, Tablet, Mobile breakpoint buttons in WeWeb toolbar | Adapts to different viewports |
| **Console** | Idle, post-interaction, post-data | No JavaScript errors |

#### Component-Specific Tests (generated per component)

Before testing, the QA agent reads `ww-config.js` and `src/wwElement.vue` to generate tests tailored to the exact component being tested:

| Source Analysis | Generated Tests |
|-----------------|-----------------|
| Each `OnOff` property | Toggle on/off, verify visual change |
| Each `Color` property | Change color, verify it applies |
| Each `TextSelect` property | Switch between each option, verify |
| Each `Array` property | Bind 3 dummy datasets (empty, typical, stress) |
| Each `triggerEvent` | Perform the triggering action, verify feedback |
| Each toggleable feature section | Enable/disable, verify appearance |
| Each `@click`/`@mouseenter` in template | Perform interaction, verify response |
| Each `v-if`/`v-show` conditional | Trigger both states, verify |

This ensures no feature goes untested, and tests match exactly what the component does — not a generic checklist.

### Property Change Testing

To test property changes in the editor:
1. Click the **"Edit"** button in the top toolbar (next to "AI") to enter Edit mode
2. Click the component on the canvas to select it
3. Use the right sidebar to find the property
4. Modify the value
5. Take a screenshot to verify the update
6. Check console for errors

## Interpreting QA Reports

### Severity Levels

| Severity | Meaning | Action |
|----------|---------|--------|
| **Critical** | Component crashes, doesn't render, or breaks the editor | Must fix before any release |
| **Major** | Feature doesn't work, visual regression, broken interaction | Should fix before release |
| **Minor** | Cosmetic issue, slight layout inconsistency | Can ship with known limitation |

### Common Issues

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Component doesn't render | Missing optional chaining, undefined content | Add `?.` to all `props.content` accesses |
| Console error on load | Unmatched wwEditor blocks | Audit start/end tags in both files |
| Property change has no effect | Using `ref()` instead of `computed()` | Convert to computed property |
| Broken at mobile viewport | Fixed dimensions on root | Remove width/height from root element |
| Interaction doesn't fire trigger | Event name mismatch | Match `emit` name to `triggerEvents` config |

## The Fix-Retest Cycle

```
Round 1: QA → Issues found → Fix → Re-QA
Round 2: QA → Issues found → Fix → Re-QA
Round 3: QA → Issues found → Fix → Re-QA (FINAL)
```

**After 3 rounds:** If issues persist, escalate. Common reasons:
- Fundamental architecture issue requiring redesign
- WeWeb platform limitation
- Missing dependency or API

### Best Practices

1. **Fix all BLOCKING issues first** — They prevent further testing
2. **Group related fixes** — Multiple related issues in one fix agent
3. **Verify the fix doesn't regress** — Full re-test, not just the specific issue
4. **Document known limitations** — If a MINOR issue won't be fixed, note it

## Field-Tested Techniques

### WeWeb Inline Style Override

WeWeb injects inline styles (`margin: 0px; padding: 0px; ...`) on every component's root `<div>`. This silently overrides any CSS class targeting the root, regardless of specificity.

**Rule:** Never style the root element via classes. Always target an inner child.

**QA check:** Use `browser_evaluate` to compare `getComputedStyle(root).paddingLeft` against expected values. If it shows `0px` when your CSS says `25px`, inline styles are overriding.

### Monaco Editor (Script Properties)

Script-type properties render as Monaco editors. Standard Playwright clicks will timeout because `.view-line` divs intercept pointer events.

**Solution:** Use `page.evaluate` to get Monaco editor coordinates, then `page.mouse.click` at center. Select all (`Meta+a`), delete, type new content with `{ delay: 20 }`, then click outside to trigger evaluation.

Multiple Script properties are indexed as `editors[0]`, `editors[1]`, etc. in DOM order matching `ww-config.js`.

**Note:** Script values are stored as `{code: "..."}` wrapper objects — components must parse `val.code`.

### HMR Timing

After editing `wwElement.vue`, HMR takes 1-3 seconds. Elements depending on DOM measurements (overlays, positioned buttons) may have stale positions during animation.

**QA workaround:** Always `waitForTimeout(2000)` after code changes before running evaluate or screenshot.

### Console Error Filtering

WeWeb editor generates noise. Ignore these:
- `[Vue warn]: Property "$attrsWithoutClick"` — editor internal
- `[Vue warn]: Missing required prop: "item"` — editor internal
- `No codicon found for CompletionItemKind` — Monaco internal
- Errors from `editor-dev-cdn.weweb.io`

Flag these (real component bugs):
- `TypeError: Cannot read properties of undefined`
- `SyntaxError: Unexpected token`
- `ReferenceError`
- Errors from `localhost:PORT`

### Post-Change Verification Sequence

After any code change, follow this order:
1. Wait 2s for HMR
2. `browser_evaluate`: check computed styles (catches inline override issues)
3. `browser_evaluate`: check element positions and visibility
4. `browser_take_screenshot`: visual confirmation
5. `browser_console_messages`: check for errors (filter noise)

Screenshots alone miss: elements behind the sidebar, `opacity: 0`, inline style overrides, wrong coordinates visually overlapping other content.

### Component Selection in Canvas

Don't click the root element — you'll select the parent (Section, Div) instead. Click a specific identifiable child inside the iframe. Verify selection by checking the right panel title matches your component name.

### Session Recovery

If the browser shows `about:blank`:
1. Navigate to `https://localhost:PORT/` → type `thisisunsafe`
2. Navigate to `https://editor-dev.weweb.io/PROJECT_ID`
3. Re-login if needed (session expired)
4. Re-configure all property values — they're lost on session expiry
5. Component code still loads from dev server automatically

### Snapshot Tips

- Iframe element refs have a `f12e` prefix. Main page refs are plain. Don't mix them.
- After any interaction, the snapshot is stale — always take a fresh one before clicking refs.
- WeWeb snapshots are large (50-80KB).

## Common Issues and Solutions

### "Component not found in Localhost"
- Verify dev server is running: `curl -sk https://localhost:PORT/`
- Check the port matches what you registered
- Try re-registering the component in the Dev panel

### "SSL certificate error persists"
- Must type `thisisunsafe` on every new Playwright session
- Ensure you're typing on the certificate warning page, not another page
- Each character must be sent individually via `browser_press_key`

### "Drag-drop doesn't place the component"
- Use the manual mouse API, not standard drag events
- Ensure the Dev panel is open and component is visible
- Check that the iframe (`#ww-manager-iframe`) is present
- Try increasing the `waitForTimeout` duration

### "Authentication expired"
- User must manually log in to WeWeb in the Playwright browser
- Session cookies persist for the session but may expire
- Navigate to `editor-dev.weweb.io` to trigger login redirect

### "Console errors from third-party scripts"
- Filter out known benign errors (Vue devtools, HMR warnings)
- Focus on errors originating from your component code
- Check the `Source` column in the error table
