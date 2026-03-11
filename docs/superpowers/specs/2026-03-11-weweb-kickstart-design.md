# Design Spec — `weweb-kickstart`

**Date:** 2026-03-11
**Status:** Approved
**Author:** Claude + Lucas

## Purpose

A conversational skill that takes a developer from an empty directory to a functional WeWeb component prototype, then transitions to the orchestrator for continued development.

## Problem

No existing skill covers the "empty directory → working project" workflow. Developers must manually read `getting-started.md`, run CLI commands, copy templates, and fill placeholders. This is error-prone and breaks the automated skill pipeline.

## Workflow

```
Empty directory
    ↓
[weweb-kickstart]
  Phase 1: Mini-brainstorm (up to 6 questions)
  Phase 2: Scaffolding (files + npm install)
  Phase 3: Verification (dev server + health check)
  Phase 4: Transition → weweb-orchestrator
    ↓
Working prototype + orchestrator takes over
```

## Trigger Conditions

**Triggers on:** "new component", "scaffold", "kickstart", "bootstrap", "créer un composant", "start a new WeWeb component", "initialize"

**Does NOT trigger if:** `package.json` or `ww-config.js` already exists in the current directory.

## Phase 1 — Mini-Brainstorm

Interactive questions, asked one at a time. If the user's answer to Q1 covers later questions, skip them.

| # | Question | Type | Required | Informs |
|---|----------|------|----------|---------|
| 1 | **Describe your component** — "What should it do? What form?" (e.g. "a horizontal bar chart showing sales by month") | Free text | Yes | Name, type, description, template structure, lib suggestions |
| 2 | **External library?** — Suggests relevant recipes inferred from Q1 + "other" + "none, vanilla" | Multiple choice | Yes | `package.json` deps, import, wrapper pattern |
| 3 | **Input data** — "What data does the component receive?" (e.g. "a list of products with name, price, image") | Free text | Yes | Array/Object props in `ww-config.js` |
| 4 | **User interactions** — "What clicks/actions should trigger something?" | Free text | No | `triggerEvents`, `@click` handlers |
| 5 | **Visual options** — "What settings should the no-coder be able to change?" | Free text | No | OnOff, Color, TextSelect props |
| 6 | **PROJECT_ID** — "Paste the WeWeb project UUID if you have it, otherwise we'll fill it in later" | Free text | No | `CLAUDE.md` placeholder or value |

### Inference Rules

- Component type is inferred from Q1 description (no explicit type selection)
- If Q1 is detailed enough to cover Q2-Q5, skip answered questions
- For vague answers on Q3-Q5, infer reasonable defaults based on component type and chosen library (e.g. ApexCharts chart → `data`, `chartType`, `showLegend`, `colors` are obvious)

## Phase 2 — Scaffolding

### Generated File Structure

```
component-name/
├── package.json          # Validated name (no ww/weweb), serve/build scripts
├── ww-config.js          # Typed properties, triggerEvents, organized sections
├── src/
│   └── wwElement.vue     # Functional template, lib imported, props wired
├── .gitignore            # node_modules, dist, .DS_Store
└── CLAUDE.md             # From template, placeholders filled (PROJECT_ID = placeholder if not provided)
```

### Component Name Validation

- Must NOT contain "ww" or "weweb" (WeWeb restriction)
- Derived from Q1 description, confirmed with user
- Used in `package.json` name field and component registration

### `ww-config.js` Generation

- Properties typed according to Q3-Q5 answers
- `triggerEvents` from Q4 answers
- Sections and blocks organized logically
- Sensible default values
- `wwEditor` blocks for editor hints
- Follows all patterns from `weweb-component-dev` skill reference

### `wwElement.vue` Generation

- Vue 3 Composition API (`<script setup>`)
- Template with proper `v-if`, `v-for` bindings
- Props consumed via `props.content.xxx` with optional chaining everywhere
- External lib imported and initialized (if applicable)
- Scoped styles on inner container (NEVER on root — WeWeb injects inline styles on root)
- Hardcoded fallback data so the component renders something even without bound data
- `wwEditor` conditional blocks where appropriate

### Known Library Recipes

The skill embeds integration patterns for common libraries:

| Category | Libraries | Generated Pattern |
|----------|-----------|-------------------|
| Charts | ApexCharts, Chart.js, ECharts | Import + wrapper ref/mounted + resize observer |
| Maps | Leaflet, Mapbox GL | Container div + init on mounted + cleanup on unmounted |
| Tables | AG Grid, TanStack Table | Wrapper + row data binding + event forwarding |
| Calendar | FullCalendar | Plugin imports + event handlers |
| Editor | TipTap, Quill | Editor instance + v-model bridge |

For unknown libraries: research via `context7` → read docs → generate adapted wrapper.

### Post-Generation

- Run `npm install` automatically

## Phase 3 — Verification

Quick check that the prototype compiles and serves:

1. `npm run serve --port=8080`
2. `curl -sk https://localhost:8080/ -o /dev/null -w "%{http_code}"` → expect 200
3. If build error → read error, fix, retry (max 2 attempts)

No full visual QA here — that's the orchestrator's job via `weweb-visual-qa`.

### Success Output

Display a recap:

```
Component ready:
- Name: component-name
- Lib: ApexCharts
- Props: 6 (data, chartType, showLegend, colors, height, showTooltip)
- Triggers: 2 (click:bar, change:selection)
- Dev server: https://localhost:8080/
- PROJECT_ID: to fill in CLAUDE.md later

Transitioning to orchestrator...
```

## Phase 4 — Transition to Orchestrator

The skill automatically invokes `weweb-orchestrator` with full context:

### Context Passed

```yaml
component_name: "component-name"
description: "Q1 answer"
library: "ApexCharts"
props_generated:
  - name: data, type: Array, description: "..."
  - name: chartType, type: TextSelect, description: "..."
  # ...
trigger_events:
  - name: click:bar, description: "..."
  # ...
port: 8080
project_id: "UUID or null"
status: "Scaffold complete, prototype functional, dev server running"
next_steps: "Refine features, visual QA when PROJECT_ID available, publish when ready"
```

The orchestrator (CTO) takes over and can:
- Ask the user which features to refine first
- Dispatch Dev agents to iterate on the component
- Launch visual QA when PROJECT_ID is available
- Chain to `weweb-publish` when ready

### One-Shot Behavior

`weweb-kickstart` never comes back. It's a one-shot skill. If the user triggers it on an existing project (files already present), it does NOT run — it suggests using `weweb-component-dev` or `weweb-orchestrator` instead.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| New skill (not adapting existing) | No existing skill has the right structure for interactive scaffolding |
| Questions asked one at a time | Avoids overwhelming the user; allows inference and skipping |
| Functional prototype, not empty skeleton | User sees something working immediately — motivating and validates the setup |
| PROJECT_ID optional | Not blocking for scaffolding; only needed for visual QA later |
| Transition to orchestrator (not standalone) | Avoids duplicating dev workflow; orchestrator already handles multi-phase dev |
| Hardcoded fallback data in template | Component renders on first serve even without editor data binding |
| Styles on inner container only | WeWeb inline style override on root is a known critical gotcha |
| Max 2 fix attempts in verification | Avoids infinite loops; if it can't compile in 2 tries, something fundamental is wrong |

## Dependencies

- `weweb-component-dev` skill — used as reference for correct ww-config patterns
- `weweb-orchestrator` skill — receives handoff after scaffolding
- `templates/CLAUDE.md.template` — base for generated CLAUDE.md
- `templates/ww-config-starter.js` — reference for professional ww-config patterns
- `context7` MCP — for researching unknown libraries

## File Location

Skill will be created at: `skills/weweb-kickstart/SKILL.md`
Doc will be created at: `docs/kickstart-guide.md`
