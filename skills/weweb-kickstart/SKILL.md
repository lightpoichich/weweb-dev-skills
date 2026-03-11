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
