# WeWeb Component Rules & Patterns

This is the **single source of truth** for all WeWeb component coding rules and patterns. Every skill that generates or modifies WeWeb component code MUST follow these patterns exactly.

## Critical Rules (Non-Negotiable)

1. **Optional chaining everywhere**: `props.content?.property` — content may be undefined initially
2. **`/* wwEditor:start */` / `/* wwEditor:end */`** blocks MUST be matched in BOTH `.vue` AND `ww-config.js` — required for ALL `bindingValidation` and `propertyHelp`. Mismatched tags = catastrophic failure
3. **Never access `document`/`window` directly** — use `wwLib.getFrontDocument()` / `wwLib.getFrontWindow()`
4. **Never hardcode width/height on root element** — must adapt to user-defined dimensions
5. **No build config files** (webpack, vite, babel, tsconfig) — `@weweb/cli` handles everything
6. **Package name MUST NOT include "ww" or "weweb"**
7. **Use specific versions** for production deps (not "latest")
8. **Always import external deps** — `import { addDays } from 'date-fns'`, never assume globals
9. **Think NoCode**: add ALL useful triggers and internal variables from a NoCode user perspective
10. **Production mode**: `wwEditor` blocks are stripped in production builds — ensure component works without editor state. Test both modes

## Project Structure

```
src/wwElement.vue   # Main Vue component (Vue 3 SFC, <script setup>)
ww-config.js        # Editor property definitions
package.json        # Only @weweb/cli as devDependency ("latest")
```

## Dev Commands

```bash
npm i                                                      # Install dependencies
npm run serve --port=[PORT]                                # Serve locally (add in WeWeb editor dev popup)
npx weweb build -- name=my-element type=wwobject           # Build for release
```

Note: the build command uses `npx weweb build` directly. The `--` with a space before `name=` is required (non-standard arg format). `type=wwobject` is mandatory.

## Props Structure

```javascript
props: {
  uid: { type: String, required: true },
  content: { type: Object, required: true },
  wwElementState: { type: Object, default: () => ({}) }, // Required for form container integration
  /* wwEditor:start */
  wwEditorState: { type: Object, required: true },
  /* wwEditor:end */
}
```

## Editor State Management

```javascript
/* wwEditor:start */
const isEditing = computed(() => props.wwEditorState.isEditing)
/* wwEditor:end */
```

## ww-config.js Structure

```javascript
export default {
  editor: {
    label: { en: 'Component Name' },
    icon: 'icon-name',
    // Group style properties in the editor sidebar
    customStylePropertiesOrder: [
      {
        label: 'Section Name',
        isCollapsible: true,
        properties: ['prop1', 'prop2'],
      },
    ],
  },
  properties: {
    // Property definitions (see Property Types below)
  },
  triggerEvents: [
    { name: 'click', label: { en: 'On click' }, event: { value: '' } },
  ],
}
```

## Property Types

### Common Property Attributes

```javascript
{
  label: { en: 'Label' },    // Always use { en: '...' } format
  type: 'Text',
  section: 'settings',       // 'settings' or 'style' — controls editor panel placement
  bindable: true,             // Accept dynamic data bindings
  responsive: true,           // Per-breakpoint values
  states: true,               // Per-state values (hover, focus, etc.)
  classes: true,              // Per-class values
  defaultValue: '',           // MANDATORY — every property needs a default
  /* wwEditor:start */
  bindingValidation: { type: 'string', tooltip: 'Description' },
  propertyHelp: { tooltip: 'Help text for the editor' },
  /* wwEditor:end */
}
```

### TextSelect (MUST use nested options format)

```javascript
mySelect: {
  label: { en: 'Option' },
  type: 'TextSelect',
  section: 'settings',
  options: {
    options: [  // Nested "options" is MANDATORY — flat object will NOT work
      { value: 'a', label: 'Label A' },
      { value: 'b', label: 'Label B' },
    ]
  },
  defaultValue: 'a',
  bindable: true,
  /* wwEditor:start */
  bindingValidation: { type: 'string', tooltip: 'a | b' },
  /* wwEditor:end */
}
```

### TextRadioGroup

```javascript
myRadio: {
  type: 'TextRadioGroup',
  options: {
    choices: [
      { value: 'left', title: 'Left', icon: 'align-left', default: true },
      { value: 'center', title: 'Center', icon: 'align-center' },
      { value: 'right', title: 'Right', icon: 'align-right' },
    ],
  },
}
```

### InfoBox (editor-only, no value)

```javascript
myInfo: {
  type: 'InfoBox',
  options: { variant: 'warning', content: 'Warning message here' },
  editorOnly: true,
  hidden: content => !content?.someCondition,
}
```

### Basic Types

```javascript
myToggle: { label: { en: 'Toggle' }, type: 'OnOff', section: 'settings', bindable: true, defaultValue: false },
myText:   { label: { en: 'Text' }, type: 'Text', section: 'settings', bindable: true, defaultValue: '' },
myNum:    { label: { en: 'Size' }, type: 'Number', section: 'settings', options: { min: 0, max: 100, step: 1 }, bindable: true, defaultValue: 50 },
myColor:  { label: { en: 'Color' }, type: 'Color', section: 'style', bindable: true, defaultValue: '#000' },
myLen:    { label: { en: 'Width' }, type: 'Length', section: 'style', options: { noRange: true }, bindable: true },
```

### SystemIcon (SVG-based icons)

`type: 'Icon'` is **deprecated** (legacy font-icon system). Use `type: 'SystemIcon'` for the modern SVG-based icon system (Lucide, Phosphor, etc.).

```javascript
// ww-config.js
myIcon: {
  label: { en: 'Icon' },
  type: 'SystemIcon',
  section: 'settings',
  defaultValue: 'lucide/check',
}
```

Icon naming format: `"library/iconName"` — e.g. `"lucide/check"`, `"phosphor-regular/heart"`

**Rendering:** `SystemIcon` returns a string (the icon name). To render the actual SVG, use `wwLib.useIcons()`:

```javascript
// In <script setup>
const { getIcon } = wwLib.useIcons();
const iconSvg = ref('');

watch(() => props.content?.myIcon, async (iconName) => {
  if (iconName) {
    try { iconSvg.value = await getIcon(iconName); }
    catch { iconSvg.value = ''; }
  }
}, { immediate: true });
```

```html
<!-- In template — v-html because getIcon returns SVG markup -->
<span class="icon-container" v-html="iconSvg"></span>
```

**For icons inside arrays** (multiple icons to resolve), use a reactive map:

```javascript
const iconSvgs = reactive({});
watch(() => items.value.map(i => i.icon), async (icons) => {
  for (const icon of icons) {
    if (icon && !iconSvgs[icon]) {
      try { iconSvgs[icon] = await getIcon(icon); }
      catch { iconSvgs[icon] = null; }
    }
  }
}, { immediate: true });
```

**SVG sizing:** Icons rendered via `v-html` inherit no size. Use `:deep(svg)` in scoped styles:

```scss
.icon-container {
  display: flex;
  align-items: center;
  :deep(svg) {
    width: 1em;
    height: 1em;
  }
}
```

### Array with Objects (Professional Standard)

```javascript
items: {
  label: { en: 'Items' },
  type: 'Array',
  section: 'settings',
  bindable: true,
  defaultValue: [{ id: 'item1', name: 'Sample' }],
  options: {
    expandable: true,
    getItemLabel(item) { return item.name || 'Item' },
    item: {
      type: 'Object',
      defaultValue: { id: 'new', name: 'New Item' },  // CRITICAL — without this, clicking "+ Add" crashes
      options: {
        item: {
          id:   { label: 'ID', type: 'Text' },
          name: { label: 'Name', type: 'Text' },
        }
      }
    }
  },
}
```

The `type: 'Object'` wrapper on the item is mandatory — without it, sub-fields won't render in the editor sidebar. The `defaultValue` on the item object is equally critical: without it, clicking "+ Add" in the editor creates an `undefined` item that crashes the component.

### Formula Properties (Dynamic Field Mapping)

When array is bindable to external data, add a Formula property to let users map fields:

```javascript
itemsNameFormula: {
  label: { en: 'Name Field' },
  type: 'Formula',
  section: 'settings',
  options: content => ({
    template: Array.isArray(content.items) && content.items.length > 0 ? content.items[0] : null,
  }),
  defaultValue: { type: 'f', code: "context.mapping?.['name']" },
  hidden: (content, sidepanelContent, boundProps) =>
    !Array.isArray(content.items) || !content.items?.length || !boundProps.items,
}
```

### ObjectPropertyPath (Legacy)

```javascript
itemsDisplayPath: {
  label: { en: 'Display Property' },
  type: 'ObjectPropertyPath',
  section: 'settings',
  hidden: (content) => !content?.items?.length,
  defaultValue: 'name',
  bindable: true,
}
// Usage: wwLib.wwUtils.resolveObjectPropertyPath(item, displayPath || 'name')
```

### Array Item Sub-Properties

When defining properties inside an array item, use the `array` parameter for conditional visibility:

```javascript
options: (content, sidePanelContent, boundProperties, wwProps, array) => ({
  singleLine: true,
  item: {
    name: { label: 'Name', type: 'Text', bindable: true },
    type: {
      label: 'Type',
      type: 'TextSelect',
      options: { options: [{ value: 'a', label: 'A' }, { value: 'b', label: 'B' }] },
    },
    specificProp: {
      label: 'Specific',
      type: 'OnOff',
      hidden: array?.item?.type === 'b',
      bindable: true,
    },
  },
  propertiesOrder: [
    'name',
    'type',
    { label: 'Config', isCollapsible: true, properties: ['specificProp'] },
  ],
}),
```

Properties inside `options` don't need `section`. Visibility is controlled by `hidden`. The `propertiesOrder` controls grouping.

## Reactivity (CRITICAL)

**NEVER use ref() or reactive() for props-derived data. ALWAYS use computed().**

```javascript
// WRONG - breaks reactivity
const items = ref([])
watch(() => props.content?.data, (v) => { items.value = v || [] })

// CORRECT
const items = computed(() => props.content?.data || [])

// CORRECT - complex processing
const processed = computed(() => {
  return (props.content?.data || []).map(item => ({
    ...item,
    color: props.content?.defaultColor || '#000',
  }))
})
```

**Watch ALL props that affect rendering for library reinitialization:**

```javascript
watch(() => [
  props.content?.theme,
  props.content?.size,
  props.content?.layout,
  // EVERY prop that should trigger visual updates — missing props = broken UX
], () => {
  setTimeout(() => containerRef.value && reinitialize(), 50)
}, { deep: true })
```

## Defensive Array Normalization

When array items come from user input or data bindings, they may be malformed (missing fields, nulls, partial data). Always normalize in a computed to prevent crashes:

```javascript
const options = computed(() => {
  const raw = props.content?.options ?? defaults;
  return raw.map((opt, i) => ({
    label: opt?.label ?? `Option ${i + 1}`,
    icon: opt?.icon ?? '',
    value: opt?.value ?? `option-${i}`,
  }));
});
```

This is especially important for arrays with `bindable: true` — bound data from external sources often has missing or null fields. Without normalization, the component crashes when users click "+ Add" in the editor (new items have only `defaultValue` fields) or when bound data doesn't match the expected shape.

## Internal Variables (MANDATORY for interactive/select/input components)

```javascript
const { value: internalValue, setValue: setInternalValue } =
  wwLib.wwVariable.useComponentVariable({
    uid: props.uid,
    name: 'value',
    type: 'string',
    defaultValue: '',
  })

// MANDATORY: Reset on initialValue change
watch(() => props.content?.initialValue, (v) => {
  if (v !== undefined) setInternalValue(v)
}, { immediate: true })

// Emit trigger on change — AVOID INFINITE LOOPS (check before setting)
const handleChange = (newVal) => {
  if (internalValue.value !== newVal) {
    setInternalValue(newVal)
    emit('trigger-event', { name: 'value-change', event: { value: newVal } })
  }
}
```

## Trigger Events

```javascript
// ww-config.js
triggerEvents: [
  { name: 'click', label: { en: 'On click' }, event: { value: '' } },
]

// Component
emit('trigger-event', { name: 'click', event: { value: data } })
```

## CSS Variables for Dynamic Styling

```vue
<template>
  <div class="wrapper" :style="dynamicStyles">...</div>
</template>

<script>
const dynamicStyles = computed(() => ({
  '--speed': props.content?.speed || 1,
  '--color': props.content?.color || '#fff',
}))
</script>

<style scoped lang="scss">
.wrapper {
  animation-duration: calc(10s / var(--speed));
  color: var(--color);
}
</style>
```

## Root Element Styling (CRITICAL)

WeWeb overrides inline styles on the root element (`margin: 0px; padding: 0px; ...`). Never style the root `<div>` directly. Always target an inner child:

```vue
<template>
  <div class="my-component">
    <div class="my-component__inner">
      <!-- All content here -->
    </div>
  </div>
</template>

<style scoped lang="scss">
.my-component {
  // NEVER style the root — WeWeb overrides it
  &__inner {
    padding: 16px;
    // All styles here
  }
}
</style>
```

## Performance

- Use `transform` and `opacity` for animations (GPU accelerated)
- Add `will-change` for animated elements
- Use `v-show` instead of `v-if` for frequently toggled elements
- Cleanup in lifecycle hooks (`onBeforeUnmount`)
