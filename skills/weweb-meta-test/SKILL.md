---
name: weweb-meta-test
description: Run the meta-test to validate that all WeWeb dev skills produce correct, consistent code. Use to detect regressions after modifying skills, verify inter-skill coherence, or validate the full component development pipeline.
---

# WeWeb Dev Skills — Meta-Test

## Overview

This skill runs a meta-test that validates all 4 WeWeb dev skills by generating a real component and checking that every pattern, format, and convention is correctly applied. It detects:
- Broken patterns in skills (e.g., wrong TextSelect format)
- Inconsistencies between skills (e.g., component-dev teaches one format, visual-qa expects another)
- Regressions after skill modifications

## When to Trigger

- After modifying any skill in `skills/*/SKILL.md`
- After modifying templates in `templates/`
- When explicitly asked to "run the meta-test" or "validate skills"
- As a sanity check before releasing skill updates

## The Test Component: Progress Tracker

A component specifically designed to exercise **every feature** documented in the skills:

| Feature | Implementation |
|---|---|
| Text property | `title` |
| OnOff toggle | `showLabels` |
| Number property | `currentStep` |
| Color property | `activeColor` |
| TextSelect (nested) | `layout` (horizontal/vertical/compact) |
| Array + objects | `steps` [{id, label, description}] |
| Formula mapping | `stepsLabelFormula` |
| Internal variable | `currentStep` via wwLib |
| Trigger events | `step-click`, `step-complete`, `value-change` |
| CSS variables | `--active-color`, `--step-size` |
| Responsive | Horizontal desktop → vertical mobile |
| wwEditor blocks | Matched in both files |

## Process (6 Phases)

### Phase 0: Environment Check

Verify prerequisites:

```bash
# Node.js >= 18
node -v

# npm available
npm -v

# Skills installed
ls ~/.claude/skills/weweb-{component-dev,visual-qa,orchestrator,publish}
```

### Phase 1: Scaffolding Validation (tests `weweb-component-dev`)

Run the automated script against golden reference files:

```bash
cd /path/to/weweb-dev-skills
./tests/run-meta-test.sh --verbose
```

The script validates 16 checks including:
- package.json structure and naming
- ww-config.js syntax and patterns
- wwEditor block matching
- Optional chaining audit
- TextSelect nested format
- Array expandable + getItemLabel
- Trigger events count
- computed() vs ref() usage

### Phase 2: Code Quality (tests skill patterns)

8 semantic checks:
- bindingValidation on all bindable props
- defaultValue on all visible props
- section on all visible props
- Internal variable pattern (uid, name, type, defaultValue)
- Emit trigger pattern correctness
- CSS variables usage
- No ref()/reactive() for derived data
- Labels in `{ en: '...' }` format

### Phase 3: QA Dry Run (tests `weweb-visual-qa` without browser)

Validates that the component is testable by the QA skill:
- All properties extractable for test plan
- All trigger events in config are emitted in Vue
- Responsive patterns present
- Array schema extractable for dummy data generation
- Edge case datasets possible

### Phase 4: QA Live (optional — requires Playwright + WeWeb)

**This phase is ONLY available in interactive mode.**

If the user wants to run live QA:

1. Ask for the WeWeb PROJECT_ID:
   ```
   Pour la Phase 4 (QA live), j'ai besoin du PROJECT_ID de votre projet WeWeb.
   C'est l'UUID dans l'URL de l'éditeur : editor-dev.weweb.io/PROJECT_ID

   Vous pouvez aussi skipper cette phase en répondant "skip".
   ```

2. If PROJECT_ID provided:
   - Create a temp project directory with the golden reference files
   - Run `npm install` and `npm run serve --port=8099`
   - Follow the `weweb-visual-qa` skill process (Steps 1-8)
   - Use the Progress Tracker as the test component
   - Generate component-specific test plan from the spec
   - Inject dummy data (3 datasets for the `steps` array):
     - **Empty**: `[]`
     - **Typical**: 5 steps with realistic labels and descriptions
     - **Stress**: 50 steps with long strings, special chars, emoji, null descriptions
   - Execute all tests
   - Write QA report

3. If user says "skip": proceed to Phase 5.

### Phase 5: Publish Dry Run (tests `weweb-publish`)

Validates the publish flow without pushing:
- Pre-publish checklist (6 checks) passes
- git init + commit works
- npm version patch works
- .gitignore entries correct

### Phase 6: Report

Generate a markdown report:

```markdown
# Meta-Test Report — WeWeb Dev Skills
**Date:** YYYY-MM-DD | **Status:** PASS/FAIL | **Duration:** Xm Ys

## Results by Phase
| Phase | Checks | Passed | Status |
|-------|--------|--------|--------|
| 0. Environment | 3 | 3/3 | PASS |
| 1. Scaffolding | 16 | 16/16 | PASS |
| 2. Code Quality | 8 | 8/8 | PASS |
| 3. QA Dry Run | 5 | 5/5 | PASS |
| 4. QA Live | skipped | — | — |
| 5. Publish Dry Run | 4 | 4/4 | PASS |
| C. Coherence | 5 | 5/5 | PASS |
```

## Inter-Skill Coherence Checks

The most important validation — ensures skills are consistent with each other:

| Check | Skills |
|---|---|
| TextSelect nested format in code = format in skill | component-dev ↔ code |
| Array expandable format in code = format in skill | component-dev ↔ code |
| Emit trigger format in code = what QA looks for | component-dev ↔ visual-qa |
| CTO review checklist passes on generated code | orchestrator ↔ code |
| Pre-publish checklist passes on generated code | publish ↔ code |

## Pass/Fail Criteria

- **PASS**: Phases 0-3, 5, and C all green
- **FAIL**: Any Phase 1 check fails (component doesn't build = fundamental problem)
- **CONDITIONAL PASS**: 1-2 Phase 2 checks fail (minor drift)

## Quick Run

```bash
# From project root
./tests/run-meta-test.sh

# With details
./tests/run-meta-test.sh --verbose

# Keep temp files for inspection
./tests/run-meta-test.sh --keep
```

## Regression Testing

To verify a skill change doesn't break anything:

1. Make your change to `skills/*/SKILL.md`
2. Run `./tests/run-meta-test.sh`
3. If it fails, the golden reference files in `tests/fixtures/` need updating too
4. If the golden reference is correct and the test fails, the skill change introduced a regression

### Intentional Regression Test

To verify the meta-test catches regressions:

```bash
# 1. Break the TextSelect format in the golden reference
sed -i '' 's/options: {//' tests/fixtures/ww-config.js

# 2. Run meta-test — should FAIL on check 1.11
./tests/run-meta-test.sh

# 3. Restore
git checkout tests/fixtures/ww-config.js
```

## File Structure

```
tests/
├── run-meta-test.sh              # Automated runner (CI-friendly)
├── fixtures/
│   ├── progress-tracker-spec.md  # Component specification
│   ├── package.json              # Golden reference
│   ├── ww-config.js              # Golden reference
│   └── src/
│       └── wwElement.vue         # Golden reference
└── reports/
    └── .gitkeep                  # Reports (gitignored)
```
