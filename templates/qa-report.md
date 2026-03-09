# Visual QA Report

## Component Info

| Field | Value |
|-------|-------|
| **Component** | [component name] |
| **Version** | [version from package.json] |
| **Date** | [YYYY-MM-DD] |
| **Tester** | [name or "automated"] |

## Test Environment

| Field | Value |
|-------|-------|
| **Dev Server Port** | [PORT] |
| **Dev Server URL** | https://localhost:[PORT] |
| **Editor URL** | https://editor-dev.weweb.io/[PROJECT_ID] |
| **Browser** | Chromium (Playwright) |
| **OS** | [macOS / Linux / Windows] |

---

## Test Matrix

| # | Test | Method | Expected Result | Status | Screenshot | Notes |
|---|------|--------|-----------------|--------|------------|-------|
| 1 | Component renders on canvas | Navigate + screenshot | Component visible, no blank area | | | |
| 2 | Default properties applied | Visual inspection | Default values from ww-config.js reflected | | | |
| 3 | Desktop viewport (1440x900) | browser_resize + screenshot | Proper layout, no overflow | | | |
| 4 | Tablet viewport (768x1024) | browser_resize + screenshot | Responsive layout adapts | | | |
| 5 | Mobile viewport (375x812) | browser_resize + screenshot | Mobile-friendly, no scroll | | | |
| 6 | Property: color changes | Modify color in editor | Updates immediately | | | |
| 7 | Property: text/labels | Modify text in editor | Labels update in real-time | | | |
| 8 | Property: toggle on/off | Toggle boolean property | Feature shows/hides instantly | | | |
| 9 | Property: numeric values | Change number property | Updates proportionally | | | |
| 10 | Property: array data | Modify array items | Re-renders correctly | | | |
| 11 | Click interaction | Click interactive element | Trigger fires correctly | | | |
| 12 | Hover interaction | Hover interactive element | Tooltip/feedback visible | | | |
| 13 | Dummy data: empty | Bind empty array [] | Empty state, no crash | | | |
| 14 | Dummy data: typical | Bind realistic dataset (5-15 items) | Renders correctly | | | |
| 15 | Dummy data: stress | Bind large dataset (50-200 items) | No crash, acceptable perf | | | |
| 16 | Dummy data: edge cases | Special chars, long strings, nulls | Graceful fallbacks, no XSS | | | |
| 17 | Console errors (idle) | browser_console_messages | No errors present | | | |
| 18 | Console errors (after interaction) | browser_console_messages | No new errors | | | |
| 19 | Console errors (after dummy data) | browser_console_messages | No errors | | | |
| 20 | Component inside iframe | Inspect #ww-manager-iframe | Renders correctly | | | |

---

## Dummy Data Testing

### Data Generated For

| Property | Component Purpose | Datasets Generated |
|----------|------------------|--------------------|
| [array property name] | [what the data represents] | Empty, Typical (N items), Stress (N items) |

### Results

| Dataset | Items | Renders | Console Errors | Performance | Notes |
|---------|-------|---------|----------------|-------------|-------|
| Empty | 0 | | | N/A | |
| Typical | | | | | |
| Stress | | | | | |
| Edge cases | | | | | |

### Edge Cases Tested

- [ ] Empty strings in text fields
- [ ] Special characters / XSS attempts (`<script>`, quotes, apostrophes)
- [ ] Very long strings (200+ chars)
- [ ] Null/undefined for optional fields
- [ ] Numeric extremes (0, negative, very large, decimals)
- [ ] Duplicate IDs
- [ ] Missing required fields
- [ ] Emoji and unicode characters

---

## Console Errors

### Errors Found

| # | Error Message | Source | Severity | Related To |
|---|---------------|--------|----------|------------|
| | | | | |

### Filtered (Benign)

List any console messages that were present but are known to be harmless (e.g., Vue devtools, HMR, third-party warnings):

-

---

## Issues Found

| # | Issue | Severity | Steps to Reproduce | Expected | Actual |
|---|-------|----------|---------------------|----------|--------|
| | | Critical / Major / Minor | | | |

### Severity Definitions

- **Critical:** Component crashes, does not render, or causes editor errors. Must fix before release.
- **Major:** Feature does not work as expected, visual regression, or broken interaction. Should fix before release.
- **Minor:** Cosmetic issue, minor layout inconsistency, or non-blocking UX concern. Can ship with known limitation.

---

## Screenshots

| Screenshot | Description | Viewport |
|------------|-------------|----------|
| | | |

---

## Recommendation

**Overall Status:** [ ] PASS / [ ] FAIL / [ ] CONDITIONAL PASS

**Summary:**

[1-3 sentences summarizing the QA results, key findings, and recommendation]

**Blockers (if any):**

-

**Follow-up items:**

-

---

## Iteration History

| Round | Date | Issues Found | Issues Fixed | Remaining |
|-------|------|-------------|-------------|-----------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
