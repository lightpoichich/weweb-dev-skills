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
| 13 | Console errors (idle) | browser_console_messages | No errors present | | | |
| 14 | Console errors (after interaction) | browser_console_messages | No new errors | | | |
| 15 | Console errors (after prop change) | browser_console_messages | No errors | | | |
| 16 | Component inside iframe | Inspect #ww-manager-iframe | Renders correctly | | | |

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
