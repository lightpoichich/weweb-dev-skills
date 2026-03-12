# Kickstart Guide

Detailed guide for using the `weweb-kickstart` skill to bootstrap a new WeWeb custom component from an empty directory.

## Overview

The kickstart skill takes you from zero to a working WeWeb component prototype. It generates all the files you need (`package.json`, `ww-config.js`, `wwElement.vue`, `CLAUDE.md`, `.gitignore`), installs dependencies, verifies the dev server starts, and hands off to the orchestrator for continued development.

This is the **first** skill you use in a new component's lifecycle. It handles the cold-start problem — the blank directory — so you can focus on describing what you want rather than setting up boilerplate.

## When to Use This vs Other Skills

| Situation | Skill |
|-----------|-------|
| **Empty directory**, no existing files | `weweb-kickstart` |
| **Existing component**, need to add features or fix bugs | `weweb-component-dev` |
| **Existing component**, complex multi-phase work | `weweb-orchestrator` |
| **Existing component**, ready to publish to GitHub | `weweb-publish` |

**Guard clause:** If both `package.json` and `ww-config.js` already exist in the working directory, the kickstart skill will refuse to run and redirect you to `weweb-component-dev` or `weweb-orchestrator`.

## The 4 Phases

### Phase 1 — Mini-Brainstorm

The skill asks up to 6 questions to understand what you want to build. Only the first 3 are required — the rest are skipped if your initial description already covers them.

| Question | Required | Purpose |
|----------|----------|---------|
| **Q1: Describe your component** | Yes | Drives everything: name, type, template, library suggestions |
| **Q2: External library** | Yes | Determines dependencies and code recipe |
| **Q3: Input data** | Yes | Defines Array/Object properties in `ww-config.js` |
| **Q4: User interactions** | No | Defines trigger events and click handlers |
| **Q5: Visual options** | No | Defines OnOff, Color, TextSelect properties |
| **Q6: PROJECT_ID** | No | Links to your WeWeb project (can be added later) |
| **Q7: Dropzones** | No | Whether users can drag other elements into the component |

If you give a detailed answer to Q1 that covers libraries, data shape, and interactions, the skill skips the already-answered questions. It also infers reasonable defaults for common component types (charts get a `data` array and `chartType` select, tables get `rows` and `columns`, etc.).

The component name is derived automatically from your description (e.g., "bar chart" becomes `bar-chart`) and confirmed with you before proceeding.

### Phase 2 — Scaffolding

All files are generated in one pass, then `npm install` runs.

Before generating code, the skill reads the authoritative rules from `~/.claude/skills/weweb-component-dev/references/weweb-rules.md` and applies every pattern exactly: optional chaining on `props.content`, computed properties for all derived data, matched `wwEditor:start/end` blocks, scoped styles on inner containers (never on root), CSS variables for dynamic values, and hardcoded fallback data so the component renders even without bound data. This ensures kickstart output is identical in quality to code written with the component-dev skill directly.

If you chose an external library, the skill uses a tested recipe for that library (see Library Recipes below).

### Phase 3 — Verification

The dev server starts (`npm run serve --port=8080`) and a health check confirms it responds with HTTP 200. If the port is busy, the skill tries 8081, 8082, etc.

If the build fails, the skill reads the error, fixes the offending file, and retries — up to 2 attempts. If it still fails after that, it stops and asks you for help.

The dev server is left running for your next steps.

### Phase 4 — Handoff

You get a structured recap in French listing: component name, library, properties count, trigger events, dev server URL, and PROJECT_ID status.

The handoff includes instructions for continuing development by launching a new Claude Code conversation and requesting the orchestrator workflow.

## What Gets Generated

```
my-component/
  package.json          — Name, version 0.1.0, dependencies, @weweb/cli
  ww-config.js          — Editor properties, trigger events, wwEditor blocks
  src/
    wwElement.vue        — Functional prototype with template, script setup, scoped styles
  CLAUDE.md             — Project context for future Claude Code sessions
  .gitignore            — node_modules, dist, .DS_Store, logs, .env
```

### `package.json`

- `name`: validated component name (lowercase, hyphens, no "ww" or "weweb")
- `version`: always `"0.1.0"`
- `dependencies`: external library with a pinned version (not "latest"). Omitted entirely for vanilla components.
- `devDependencies`: always `"@weweb/cli": "latest"`
- `scripts`: `serve` and `build` via `ww-front-cli`

### `ww-config.js`

All properties derived from your brainstorm answers. Follows every pattern from `~/.claude/skills/weweb-component-dev/references/weweb-rules.md`:
- `TextSelect` with nested `options: { options: [...] }` format
- `Array` with `expandable: true`, `getItemLabel`, and typed sub-properties
- `bindingValidation` inside wwEditor blocks for bindable properties
- Properties organized into `section: 'settings'` and `section: 'style'`
- Trigger events with `name`, `label`, and `event: { value: '' }`

### `src/wwElement.vue`

A functional prototype — not a stub. The component renders something meaningful out of the box, with hardcoded fallback data. Uses Vue 3 Composition API (`<script setup>`), optional chaining on every `props.content` access, computed properties for all derived data, and the appropriate library recipe if applicable.

### `CLAUDE.md`

Filled from the `templates/CLAUDE.md.template` with your component name, description, and PROJECT_ID. This file gives future Claude Code sessions all the context they need.

## Library Recipes

The skill includes battle-tested recipes for common libraries. Each recipe follows the same pattern: `ref` for DOM elements, `onMounted` for initialization, `onUnmounted` for cleanup, `watch` for reactive updates, and `ResizeObserver` when the library needs to respond to container resizes.

### ApexCharts

- Uses `new ApexCharts(element, options)` with `render()` in `onMounted`
- Series and options updated separately via `updateSeries()` and `updateOptions()`
- `ResizeObserver` triggers `updateOptions({}, false, false)` for container resize
- `dataPointSelection` event wired to trigger emit

### Leaflet

- Uses `L.map(element).setView(center, zoom)` in `onMounted`
- `L.tileLayer` with OpenStreetMap by default
- `ResizeObserver` triggers `invalidateSize()` for container resize
- Imports `leaflet/dist/leaflet.css` for marker and control styles

### Chart.js

- Uses `new Chart(canvas, { type, data, options })` in `onMounted`
- Registers all chart types via `Chart.register(...registerables)`
- Updates via `chart.data = newData` + `chart.update()`
- `responsive: true` and `maintainAspectRatio: false` by default
- `onClick` handler wired to trigger emit

### TipTap

- Uses `useEditor` composable from `@tiptap/vue-3`
- `EditorContent` component in template
- `StarterKit` extension by default
- `onUpdate` callback wired to trigger emit with HTML content
- Editor destroyed in `onUnmounted`

### Unknown Library (Fallback)

For libraries not covered above, the skill:
1. Queries `context7` MCP for the library's Vue 3 integration docs
2. Falls back to `WebSearch` if context7 is unavailable
3. Generates a wrapper following the same `ref` / `onMounted` / `onUnmounted` / `watch` pattern

## Troubleshooting

### `npm install` Fails

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `ERESOLVE` peer dependency conflict | Conflicting version requirements | Try `npm install --legacy-peer-deps`, or pin a compatible version |
| `ENOENT` or `EACCES` | Permission or path issue | Verify you are in the correct directory and have write access |
| Network timeout | Corporate proxy, VPN, or offline | Check network connectivity, configure npm proxy if needed |
| `engine` mismatch | Wrong Node.js version | WeWeb CLI requires Node 16+. Check with `node -v` |

The skill retries once automatically. If the second attempt also fails, it stops and asks for your help.

### Build Errors

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Module not found` | Wrong import path or missing dependency | Verify the library name matches what was installed |
| `SyntaxError: Unexpected token` | Malformed template or script | Check for unclosed tags, missing commas, or typos |
| `Cannot find module '@weweb/cli'` | `npm install` did not complete | Run `npm install` again |
| Vue compilation error | Invalid template syntax | Check for unmatched `v-if`/`v-for`, duplicate attributes |

The skill attempts up to 2 automatic fixes by reading the error output and patching the offending file.

### Port Conflicts

If port 8080 is already in use (by another dev server, another component, or another process), the skill automatically tries 8081, then 8082, and so on. If you need to free a specific port:

```bash
# Find what's using the port
lsof -i :8080
# Kill it if needed
kill -9 <PID>
```

## FAQ

### What if I already have a project?

If `package.json` and `ww-config.js` already exist, the kickstart skill will not run. Use:
- **`weweb-component-dev`** — for adding features, fixing bugs, or consulting the WeWeb API reference
- **`weweb-orchestrator`** — for complex multi-phase work with automated Dev/QA cycles

### Can I re-run kickstart on an existing project?

No. The guard clause prevents it to avoid overwriting your existing code. If you need to start over, delete the existing files first (or work in a new directory).

### Do I need a WeWeb account to use kickstart?

Not for scaffolding and local development. You need a PROJECT_ID (from your WeWeb editor URL) only when you want to test in the WeWeb editor via the `weweb-visual-qa` skill. You can add it to `CLAUDE.md` later.

### What if my library is not in the recipes?

The skill handles unknown libraries by querying documentation sources and generating a wrapper following the same proven pattern. The result may need more manual tuning than a known recipe, but the structure will be correct.
