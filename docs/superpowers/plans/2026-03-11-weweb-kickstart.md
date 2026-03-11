# weweb-kickstart Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a conversational scaffolding skill that takes a developer from an empty directory to a functional WeWeb component prototype, then hands off to the orchestrator.

**Architecture:** Single SKILL.md file containing the full skill logic (brainstorm → scaffold → verify → handoff), plus a companion doc, installer update, and meta-test coverage. The skill is self-contained Markdown interpreted by Claude Code — no runtime code.

**Tech Stack:** Markdown (SKILL.md), Bash (install.sh, meta-test), WeWeb CLI patterns

**Spec:** `docs/superpowers/specs/2026-03-11-weweb-kickstart-design.md`

---

## Chunk 1: Meta-Test & Infrastructure

### Task 1: Add kickstart checks to meta-test

**Files:**
- Modify: `tests/run-meta-test.sh:140-151` (check 0.3 — skill count)

The existing check 0.3 loops over 4 hardcoded skills. Add `weweb-kickstart` to the list.

- [ ] **Step 1: Update skill list in check 0.3**

In `tests/run-meta-test.sh`, line 142, change the loop to include `weweb-kickstart`:

```bash
for skill in weweb-component-dev weweb-visual-qa weweb-orchestrator weweb-publish weweb-kickstart; do
```

And update the pass message on line 148:

```bash
pass 0 "0.3" "All 5 skills installed in ~/.claude/skills/"
```

- [ ] **Step 2: Add kickstart-specific coherence check**

After check C.5 (line 725), add a new check C.6 that validates the kickstart SKILL.md exists and has required frontmatter:

```bash
# C.6 — Kickstart skill has valid frontmatter
KICKSTART_SKILL="$SKILLS_DIR/weweb-kickstart/SKILL.md"
if [[ -f "$KICKSTART_SKILL" ]]; then
  KS_HAS_NAME=$(grep -c '^name: weweb-kickstart' "$KICKSTART_SKILL" 2>/dev/null || echo 0)
  KS_HAS_DESC=$(grep -c '^description:' "$KICKSTART_SKILL" 2>/dev/null || echo 0)
  KS_HAS_GUARD=$(grep -c 'package.json' "$KICKSTART_SKILL" 2>/dev/null || echo 0)
  if [[ "$KS_HAS_NAME" -gt 0 ]] && [[ "$KS_HAS_DESC" -gt 0 ]] && [[ "$KS_HAS_GUARD" -gt 0 ]]; then
    pass C "C.6" "Kickstart skill: valid frontmatter + guard clause"
  else
    fail C "C.6" "Kickstart skill: missing frontmatter or guard" "name=$KS_HAS_NAME desc=$KS_HAS_DESC guard=$KS_HAS_GUARD"
  fi
else
  fail C "C.6" "Kickstart SKILL.md not found" "$KICKSTART_SKILL"
fi
```

- [ ] **Step 3: Update total check count in phase header comment**

Update the script header comment (line 1-10 area) to reflect the new check count (42 instead of 41).

- [ ] **Step 4: Run meta-test to verify new checks fail**

Run: `./tests/run-meta-test.sh`

Expected: Check 0.3 fails (weweb-kickstart not installed), C.6 fails (SKILL.md not found). Other 41 checks pass.

- [ ] **Step 5: Commit**

```bash
git add tests/run-meta-test.sh
git commit -m "test: add kickstart skill checks to meta-test (42 checks)"
```

### Task 2: Update install.sh

**Files:**
- Modify: `install.sh:19` (SKILLS array)
- Modify: `install.sh:40-43` (usage help text)

- [ ] **Step 1: Add weweb-kickstart to SKILLS array**

Line 19:
```bash
SKILLS=("weweb-component-dev" "weweb-visual-qa" "weweb-orchestrator" "weweb-publish" "weweb-kickstart")
```

- [ ] **Step 2: Add to usage help text**

After line 43, add:
```
  weweb-kickstart       Scaffold new components from empty directory
```

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add weweb-kickstart to installer"
```

---

## Chunk 2: Core Skill File

### Task 3: Create the SKILL.md

**Files:**
- Create: `skills/weweb-kickstart/SKILL.md`

This is the main deliverable. The file must contain:

1. YAML frontmatter with name + description (from spec)
2. Guard clause (exit if `package.json` AND `ww-config.js` exist)
3. Phase 1: brainstorm questions (Q1-Q6)
4. Phase 2: scaffolding rules (file generation templates)
5. Phase 3: verification steps
6. Phase 4: handoff recap
7. Library recipes
8. Reference to `weweb-component-dev` for patterns

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/weweb-kickstart
```

- [ ] **Step 2: Write the SKILL.md**

Write the full file to `skills/weweb-kickstart/SKILL.md`. Content below:

````markdown
---
name: weweb-kickstart
description: Use when starting a WeWeb component from scratch in an empty or new directory. Scaffolds the full project, generates a functional prototype, and hands off to the orchestrator. Triggers on new component, scaffold, kickstart, bootstrap, initialize. Does NOT apply if package.json and ww-config.js already exist.
---

# WeWeb Kickstart — From Zero to Prototype

## Guard Clause

**Before anything else**, check the current working directory:

- If BOTH `package.json` AND `ww-config.js` exist → **STOP**. This project is already scaffolded. Say: "Ce projet WeWeb existe déjà. Utilise le skill `weweb-component-dev` pour le développement ou `weweb-orchestrator` pour un workflow multi-agent."
- If only one or neither exists → proceed with kickstart.

## Overview

This skill takes a developer from an empty directory to a working WeWeb component prototype in 4 phases:

```
Phase 1: Mini-brainstorm (up to 6 questions)
Phase 2: Scaffolding (generate all files + npm install)
Phase 3: Verification (dev server + health check)
Phase 4: Handoff (recap + orchestrator instructions)
```

## Phase 1 — Mini-Brainstorm

Ask questions **one at a time**. If the user's answer to Q1 covers later questions, skip them.

### Q1 (Required): Describe Your Component

> Décris ton composant : qu'est-ce qu'il doit faire ? Quelle forme ? (ex: "un bar chart horizontal qui affiche des ventes par mois")

This answer informs everything: name, type, description, template structure, library suggestions. Infer the component type from the description — do not ask for it separately.

### Q2 (Required): External Library

Based on Q1, suggest relevant library recipes:

- If Q1 mentions charts → suggest: ApexCharts, Chart.js, ECharts, or vanilla
- If Q1 mentions maps → suggest: Leaflet, Mapbox GL, or vanilla
- If Q1 mentions tables → suggest: AG Grid, TanStack Table, or vanilla
- If Q1 mentions calendar → suggest: FullCalendar, or vanilla
- If Q1 mentions rich text → suggest: TipTap, Quill, or vanilla
- Always include "autre (précise)" and "aucune, vanilla"

> Quelle lib externe veux-tu utiliser ? [suggestions based on Q1] / autre / aucune (vanilla)

### Q3 (Required): Input Data

> Quelles données le composant reçoit ? (ex: "une liste de produits avec nom, prix, image")

This defines Array/Object properties in `ww-config.js`.

### Q4 (Optional): User Interactions

> Quels clics ou actions doivent déclencher quelque chose ? (ex: "clic sur une ligne → sélection")

Skip if Q1 already covered this. This defines `triggerEvents` and `@click`/`@mouseenter` handlers.

### Q5 (Optional): Visual Options

> Quels réglages le no-coder doit pouvoir changer ? (ex: "couleurs, afficher/masquer le header, taille")

Skip if Q1 already covered this. This defines OnOff, Color, TextSelect properties.

### Q6 (Optional): PROJECT_ID

> Si tu as déjà un PROJECT_ID WeWeb (l'UUID dans l'URL de l'éditeur), colle-le ici. Sinon, on mettra un placeholder — tu pourras le renseigner plus tard dans CLAUDE.md.

### Inference Rules

- If the user gives a detailed Q1 that covers libraries, data, interactions, and options, skip the answered questions entirely
- For vague or missing answers on Q3-Q5, infer reasonable defaults based on component type and library:
  - Charts → `data` (Array), `chartType` (TextSelect), `showLegend` (OnOff), `colors` (Color)
  - Tables → `rows` (Array), `columns` (Array), `showHeader` (OnOff), `striped` (OnOff)
  - Maps → `markers` (Array), `center` (Object), `zoom` (Number), `mapStyle` (TextSelect)
  - Calendar → `events` (Array), `view` (TextSelect), `firstDayOfWeek` (Number)

### Derive Component Name

From Q1, derive a component name:
- Extract the key concept (e.g., "bar chart" → `bar-chart`, "data table" → `data-table`)
- Validate: lowercase, hyphens only, NO "ww" or "weweb"
- Confirm with user: "Je propose le nom `bar-chart` — ça te va ?"

## Phase 2 — Scaffolding

Generate ALL files in one pass, then run `npm install`.

### File 1: `package.json`

```json
{
  "name": "COMPONENT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "serve": "ww-front-cli serve",
    "build": "ww-front-cli build"
  },
  "dependencies": {
    "EXTERNAL_LIB": "^SPECIFIC_VERSION"
  },
  "devDependencies": {
    "@weweb/cli": "latest"
  }
}
```

Rules:
- `name`: validated component name (no ww/weweb, lowercase, hyphens)
- `version`: always `"0.1.0"`
- `dependencies`: external lib with a **specific version** (not "latest") — check npm for current stable version. Omit `dependencies` block entirely if vanilla.
- `devDependencies`: always `"@weweb/cli": "latest"`
- `scripts`: always `serve` and `build` as shown

### File 2: `ww-config.js`

Generate following ALL patterns from the `weweb-component-dev` skill:

- `editor.label` with `{ en: 'Component Name' }` format
- Properties typed from brainstorm answers (Q3-Q5)
- Every property MUST have: `label: { en: '...' }`, `type`, `section`, `defaultValue`
- Bindable properties MUST have `bindingValidation` inside `/* wwEditor:start/end */`
- `TextSelect` MUST use nested format: `options: { options: [...] }`
- `Array` MUST have `expandable: true`, `getItemLabel`, and `item` with typed sub-properties
- `triggerEvents` from Q4 — each with `name`, `label: { en: '...' }`, `event: { value: '' }`
- Matched `/* wwEditor:start */` / `/* wwEditor:end */` blocks
- Organize into `section: 'settings'` and `section: 'style'`

### File 3: `src/wwElement.vue`

Generate a **functional prototype** following ALL WeWeb conventions:

```vue
<template>
  <div class="COMPONENT_NAME">
    <div class="COMPONENT_NAME__inner">
      <!-- Functional template here -->
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
// import ExternalLib from 'external-lib'; // if applicable

const props = defineProps({
  content: { type: Object, required: true },
  uid: { type: String, required: true },
  /* wwEditor:start */
  wwEditorState: { type: Object },
  /* wwEditor:end */
});

const emit = defineEmits(['trigger-event']);

// Props with optional chaining + fallback defaults
const data = computed(() => props.content?.data ?? [/* hardcoded fallback */]);
const showTitle = computed(() => props.content?.showTitle ?? true);

// External lib initialization (if applicable)
// Use ref for DOM element, onMounted for init, onUnmounted for cleanup

// Trigger event handlers
function handleClick(item) {
  emit('trigger-event', {
    name: 'click:item',
    event: { value: item },
  });
}
</script>

<style lang="scss" scoped>
.COMPONENT_NAME {
  // NEVER style the root — WeWeb overrides inline styles on root
  &__inner {
    padding: var(--padding, 16px);
    // Component styles here
  }
}
</style>
```

Critical rules:
- **Optional chaining** (`?.`) for ALL `props.content` references
- **Computed** (not `ref`) for all props-derived data
- **Matched wwEditor blocks** in template and script
- **Scoped styles on inner container** — never on root `<div>`
- **CSS variables** for dynamic values (colors, sizes)
- **Hardcoded fallback data** — component renders something even without bound data
- **No direct document/window** — use `wwLib.getFrontDocument()` / `wwLib.getFrontWindow()`
- **Trigger emits** use format: `emit('trigger-event', { name: '...', event: { value: ... } })`

If using an external library, follow the appropriate recipe (see Library Recipes below).

### File 4: `.gitignore`

```
node_modules/
dist/
.DS_Store
*.log
.env
```

### File 5: `CLAUDE.md`

Use the template from `templates/CLAUDE.md.template` with placeholders filled:
- `{{COMPONENT_NAME}}` → validated component name
- `{{COMPONENT_DESCRIPTION}}` → from Q1 answer
- `{{PROJECT_ID}}` → from Q6 answer, or `YOUR_PROJECT_ID` if not provided

### Post-Generation

1. Run `npm install`
2. If `npm install` fails: display the error, ask the user to resolve (e.g., Node version, network), then retry once
3. If retry fails: stop and explain what went wrong

## Phase 3 — Verification

After scaffolding, verify the prototype compiles:

1. Start dev server: `npm run serve --port=8080`
   - If port 8080 is busy, try 8081, 8082, etc.
2. Health check: `curl -sk https://localhost:PORT/ -o /dev/null -w "%{http_code}"`
   - Expect: 200
3. If build error:
   - Read the terminal output
   - Identify the error (import path, syntax, missing dep)
   - Fix the offending file
   - Restart serve
   - Max 2 fix attempts. If still failing after 2, display the error and ask the user for help.

**Leave the dev server running** — the user will need it for the next phase.

## Phase 4 — Handoff

Display a structured recap in French:

```
## Composant prêt !

**Nom:** COMPONENT_NAME
**Lib:** LIBRARY_NAME (or "vanilla")
**Props:** N (list key ones)
**Triggers:** N (list all)
**Dev server:** https://localhost:PORT/
**PROJECT_ID:** VALUE or "à renseigner dans CLAUDE.md"

### Prochaines étapes

Pour continuer le développement, lance une nouvelle conversation Claude Code
dans ce répertoire et demande :

> "Continue le développement de ce composant avec l'orchestrateur"

Cela déclenchera le skill `weweb-orchestrator` qui pilotera les phases
Dev/QA/Publish. Le CLAUDE.md contient tout le contexte nécessaire.

Si tu veux juste itérer manuellement, tu peux aussi utiliser le skill
`weweb-component-dev` comme référence.
```

## Library Recipes

### ApexCharts

```vue
<template>
  <div class="COMPONENT_NAME">
    <div class="COMPONENT_NAME__inner">
      <div ref="chartRef" class="COMPONENT_NAME__chart"></div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import ApexCharts from 'apexcharts';

const props = defineProps({
  content: { type: Object, required: true },
  uid: { type: String, required: true },
  /* wwEditor:start */
  wwEditorState: { type: Object },
  /* wwEditor:end */
});

const emit = defineEmits(['trigger-event']);

const chartRef = ref(null);
let chartInstance = null;
let resizeObserver = null;

const series = computed(() => props.content?.data ?? [{ name: 'Sample', data: [30, 40, 35, 50, 49] }]);
const chartType = computed(() => props.content?.chartType ?? 'bar');

const chartOptions = computed(() => ({
  chart: {
    type: chartType.value,
    events: {
      dataPointSelection: (event, chartContext, config) => {
        emit('trigger-event', {
          name: 'click:datapoint',
          event: { value: config },
        });
      },
    },
  },
}));

onMounted(() => {
  if (chartRef.value) {
    chartInstance = new ApexCharts(chartRef.value, {
      ...chartOptions.value,
      series: series.value,
    });
    chartInstance.render();

    // ResizeObserver for container resizes in WeWeb editor
    resizeObserver = new ResizeObserver(() => {
      chartInstance?.updateOptions({}, false, false); // triggers resize
    });
    resizeObserver.observe(chartRef.value);
  }
});

// Series and options must be updated separately in ApexCharts
watch(series, (newSeries) => {
  chartInstance?.updateSeries(newSeries);
}, { deep: true });

watch(chartOptions, (newOpts) => {
  chartInstance?.updateOptions(newOpts, false, false);
}, { deep: true });

onUnmounted(() => {
  resizeObserver?.disconnect();
  chartInstance?.destroy();
});
</script>
```

### Leaflet

```vue
<template>
  <div class="COMPONENT_NAME">
    <div class="COMPONENT_NAME__inner">
      <div ref="mapRef" class="COMPONENT_NAME__map"></div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const props = defineProps({
  content: { type: Object, required: true },
  uid: { type: String, required: true },
  /* wwEditor:start */
  wwEditorState: { type: Object },
  /* wwEditor:end */
});

const emit = defineEmits(['trigger-event']);

const mapRef = ref(null);
let mapInstance = null;
let resizeObserver = null;

const center = computed(() => props.content?.center ?? [48.8566, 2.3522]);
const zoom = computed(() => props.content?.zoom ?? 13);

onMounted(() => {
  if (mapRef.value) {
    mapInstance = L.map(mapRef.value).setView(center.value, zoom.value);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(mapInstance);

    resizeObserver = new ResizeObserver(() => {
      mapInstance?.invalidateSize();
    });
    resizeObserver.observe(mapRef.value);
  }
});

onUnmounted(() => {
  resizeObserver?.disconnect();
  mapInstance?.remove();
});
</script>
```

### Chart.js

```vue
<template>
  <div class="COMPONENT_NAME">
    <div class="COMPONENT_NAME__inner">
      <canvas ref="canvasRef"></canvas>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue';
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

const props = defineProps({
  content: { type: Object, required: true },
  uid: { type: String, required: true },
  /* wwEditor:start */
  wwEditorState: { type: Object },
  /* wwEditor:end */
});

const emit = defineEmits(['trigger-event']);

const canvasRef = ref(null);
let chartInstance = null;

const chartType = computed(() => props.content?.chartType ?? 'bar');
const chartData = computed(() => props.content?.data ?? {
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
  datasets: [{ label: 'Sample', data: [30, 40, 35, 50, 49] }],
});
const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  onClick: (event, elements) => {
    if (elements.length > 0) {
      emit('trigger-event', {
        name: 'click:datapoint',
        event: { value: elements[0] },
      });
    }
  },
}));

onMounted(() => {
  if (canvasRef.value) {
    chartInstance = new Chart(canvasRef.value, {
      type: chartType.value,
      data: chartData.value,
      options: chartOptions.value,
    });
  }
});

watch([chartData, chartOptions], () => {
  if (chartInstance) {
    chartInstance.data = chartData.value;
    chartInstance.options = chartOptions.value;
    chartInstance.update();
  }
}, { deep: true });

onUnmounted(() => {
  chartInstance?.destroy();
});
</script>
```

### TipTap

```vue
<template>
  <div class="COMPONENT_NAME">
    <div class="COMPONENT_NAME__inner">
      <EditorContent :editor="editor" />
    </div>
  </div>
</template>

<script setup>
import { computed, watch, onUnmounted } from 'vue';
import { useEditor, EditorContent } from '@tiptap/vue-3';
import StarterKit from '@tiptap/starter-kit';

const props = defineProps({
  content: { type: Object, required: true },
  uid: { type: String, required: true },
  /* wwEditor:start */
  wwEditorState: { type: Object },
  /* wwEditor:end */
});

const emit = defineEmits(['trigger-event']);

const initialContent = computed(() => props.content?.initialContent ?? '<p>Start typing...</p>');

const editor = useEditor({
  content: initialContent.value,
  extensions: [StarterKit],
  onUpdate: ({ editor: ed }) => {
    emit('trigger-event', {
      name: 'change:content',
      event: { value: ed.getHTML() },
    });
  },
});

onUnmounted(() => {
  editor.value?.destroy();
});
</script>
```

### Unknown Library (Fallback)

For libraries not listed above:

1. Use `context7` MCP to fetch the library's documentation: `resolve-library-id` then `query-docs` with topic "Vue 3 integration"
2. If `context7` is unavailable, use `WebSearch` to find "LIBRARY_NAME Vue 3 integration example"
3. Generate the wrapper following the same pattern: `ref` for DOM element, `onMounted` for init, `onUnmounted` for cleanup, `watch` for reactive updates

## Reference

This skill generates code that must comply with ALL rules in the `weweb-component-dev` skill. When in doubt, consult that skill for:
- Property type definitions and correct formats
- Reactivity patterns (computed vs ref)
- Array property structure (expandable, getItemLabel, Formula mapping)
- Form container integration
- Dropzone patterns
- Internal variable registration
````

- [ ] **Step 3: Verify the file was created correctly**

```bash
head -5 skills/weweb-kickstart/SKILL.md
```

Expected: YAML frontmatter with `name: weweb-kickstart`

- [ ] **Step 4: Install the skill via symlink**

```bash
./install.sh
```

Expected: All 5 skills installed, including `weweb-kickstart (symlinked)`.

- [ ] **Step 5: Run meta-test**

Run: `./tests/run-meta-test.sh`

Expected: 42/42 checks pass (including new 0.3 with 5 skills and C.6 kickstart check).

- [ ] **Step 6: Commit**

```bash
git add skills/weweb-kickstart/SKILL.md
git commit -m "feat: add weweb-kickstart skill — scaffold WeWeb components from empty directory"
```

---

## Chunk 3: Documentation & Peripheral Updates

### Task 4: Create kickstart-guide.md

**Files:**
- Create: `docs/kickstart-guide.md`

- [ ] **Step 1: Write the companion doc**

Write `docs/kickstart-guide.md` covering:
- What the skill does (overview)
- When to use it vs other skills
- The 4 phases explained for humans
- What gets generated (file structure, with explanations)
- Library recipes supported
- Troubleshooting (npm install fails, build errors, port conflicts)
- FAQ: "What if I already have a project?" → use component-dev or orchestrator

Keep it concise — the SKILL.md has all the details, this is the human-readable guide.

- [ ] **Step 2: Commit**

```bash
git add docs/kickstart-guide.md
git commit -m "docs: add kickstart guide"
```

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md:10-22` (Project Structure section)

- [ ] **Step 1: Add weweb-kickstart to the project structure listing**

After the line `  weweb-publish/        — GitHub publishing and version management`, add:
```
  weweb-kickstart/      — Scaffold new components from empty directory
```

- [ ] **Step 2: Update "41 checks" references to "42 checks"**

Two occurrences in CLAUDE.md:
- Line 20: `run-meta-test.sh      — Automated validation (41 checks, CI-friendly)` → `(42 checks, CI-friendly)`
- Line 48: `./tests/run-meta-test.sh — validates 41 checks across all skills` → `validates 42 checks across all skills`

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add weweb-kickstart to CLAUDE.md project structure"
```

### Task 6: Update README.md

**Files:**
- Modify: `README.md:3` (intro line — "Four" → "Five")
- Modify: `README.md:16-21` (Skills Overview table — add row)
- Modify: `README.md:25-30` (Quick Install section — update skill list in text)
- Modify: `README.md:39-43` (Manual Install section — add cp command)
- Modify: `README.md:55-65` (Usage Examples / Starting a New Component — update to reference kickstart)
- Modify: `README.md:100` (meta-test check count 41 → 42)
- Modify: `README.md:119-129` (Project Structure tree — add kickstart)
- Modify: `README.md:153-157` (Documentation section — add kickstart guide link)

- [ ] **Step 1: Update intro, skills table, install sections, and project structure**

Key changes:
- Line 3: "Four specialized skills" → "Five specialized skills"
- Add row to Skills Overview table:
  ```
  | `weweb-kickstart` | Scaffold new components from scratch: brainstorm, generate functional prototype, verify, hand off to orchestrator | New component, scaffold, kickstart, empty directory |
  ```
- Add to Manual Install:
  ```bash
  cp -r skills/weweb-kickstart ~/.claude/skills/
  ```
- Update Starting a New Component to recommend kickstart first
- Update meta-test count: "41-check" → "42-check"
- Add `weweb-kickstart/` to project structure tree
- Add `[Kickstart Guide](docs/kickstart-guide.md)` to the `## Documentation` section

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add weweb-kickstart to README"
```

### Task 7: Update getting-started.md

**Files:**
- Modify: `docs/getting-started.md:21-25` (skill list)
- Modify: `docs/getting-started.md:27-50` (Step 2 — manual create → kickstart)

- [ ] **Step 1: Add kickstart to installed skills list**

After `weweb-publish`, add:
```
- `weweb-kickstart` — Scaffold new components from an empty directory
```

- [ ] **Step 2: Update Step 2 to recommend kickstart**

Replace the manual project creation steps with:

```markdown
## 2. Create a New Component Project

### Recommended: Use the Kickstart Skill

Start Claude Code in an empty directory and say:

> "Scaffold a new WeWeb component"

Claude will use the `weweb-kickstart` skill to:
- Ask about your component (description, library, data, interactions)
- Generate all project files with a functional prototype
- Verify the dev server runs
- Hand off to the orchestrator for continued development

### Manual Alternative

If you prefer to set up manually:
```

Then keep the existing manual steps below.

- [ ] **Step 3: Commit**

```bash
git add docs/getting-started.md
git commit -m "docs: recommend kickstart in getting-started guide"
```

### Task 8: Final verification

- [ ] **Step 1: Run meta-test**

Run: `./tests/run-meta-test.sh --verbose`

Expected: 42/42 checks pass.

- [ ] **Step 2: Verify skill triggers**

Check that the frontmatter `description` in `skills/weweb-kickstart/SKILL.md` starts with "Use when starting a WeWeb component from scratch".

- [ ] **Step 3: Review all changed files**

Run: `git log --oneline -10` to see all commits for this implementation.

Run: `git diff HEAD~7..HEAD --stat` to see all files changed.

Verify no file was missed from the spec's Implementation Checklist:
- [x] `skills/weweb-kickstart/SKILL.md` — created
- [x] `docs/kickstart-guide.md` — created
- [x] `install.sh` — updated
- [x] `CLAUDE.md` — updated
- [x] `README.md` — updated
- [x] `tests/run-meta-test.sh` — updated
- [x] `docs/getting-started.md` — updated
