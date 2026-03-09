---
name: weweb-component-dev
description: Use when building, editing, or debugging WeWeb custom components (wwElement.vue, ww-config.js). Covers property definitions, reactivity, array items, dropzones, internal variables, form container integration, editor blocks, and CSS constraints. Triggers on any mention of WeWeb, ww-config, wwElement, wwLib, or NoCode component development.
---

# WeWeb Component Development

## Overview

Reference guide for building WeWeb custom components. WeWeb components are Vue 3 SFCs configured via `ww-config.js` for a NoCode editor. Every pattern here prevents real breakage in the editor or at runtime.

## Dev Commands

```bash
npm i                              # Install dependencies
npm run serve --port=[PORT]        # Serve locally (add in WeWeb editor dev popup)
npm run build --name=my-element    # Build for release
```

## Project Structure

```
src/wwElement.vue   # Main Vue component
ww-config.js        # Editor property definitions
package.json        # Only @weweb/cli as devDependency ("latest")
```

## Critical Rules (Non-Negotiable)

1. **Optional chaining everywhere**: `props.content?.property` — content may be undefined initially
2. **`/* wwEditor:start */` / `/* wwEditor:end */`** blocks MUST be matched in BOTH `.vue` AND `ww-config.js` — required for ALL `bindingValidation` and `propertyHelp`. Mismatched tags = catastrophic failure
3. **Never access `document`/`window` directly** — use `wwLib.getFrontDocument()` / `wwLib.getFrontWindow()`
4. **Never hardcode width/height on root element** — must adapt to user-defined dimensions
5. **No build config files** (webpack, vite, babel, tsconfig) — `@weweb/cli` handles everything
6. **Package name MUST NOT include "ww" or "weweb"**
7. **Use specific versions** for production deps (not "latest")
8. **Always import external deps** — `import { addDays } from 'date-fns'`, `import { get } from 'lodash'`, etc. Never assume globals
9. **Think NoCode**: add ALL useful triggers and internal variables from a NoCode user perspective
10. **Production mode**: `wwEditor` blocks are stripped in production builds — ensure component works without editor state. Test both modes

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
    // Property definitions
  },
  triggerEvents: [
    { name: 'click', label: { en: 'On click' }, event: { value: '' } },
  ],
}
```

## Property Types in ww-config.js

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
myToggle: { label: { en: 'Toggle' }, type: 'OnOff', bindable: true, defaultValue: false },
myText:   { label: { en: 'Text' }, type: 'Text', bindable: true, defaultValue: '' },
myNum:    { label: { en: 'Size' }, type: 'Number', options: { min: 0, max: 100, step: 1 }, bindable: true },
myColor:  { label: { en: 'Color' }, type: 'Color', bindable: true, defaultValue: '#000' },
myLen:    { label: { en: 'Width' }, type: 'Length', options: { noRange: true }, bindable: true },
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
      defaultValue: { id: 'new', name: 'New Item' },
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

**Formula properties for dynamic field mapping** (when array is bindable to external data):

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

**ObjectPropertyPath (legacy, keep for backward compat):**

```javascript
itemsDisplayPath: {
  label: { en: 'Display Property' },
  type: 'ObjectPropertyPath',
  section: 'settings',
  hidden: (content) => !content?.items?.length,
  defaultValue: 'name',
  bindable: true,
}
// Usage in component:
wwLib.wwUtils.resolveObjectPropertyPath(item, displayPath || 'name')
```

### Array Item Sub-Properties (inside options function)

When defining properties inside an array item's `options` function, use the `array` parameter for conditional visibility:

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
    // Conditional visibility using array?.item
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

**Key**: properties defined here don't need `section`. Visibility is controlled by `hidden` expressions evaluated when the `options` function runs. The `propertiesOrder` controls grouping and display order.

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

## Form Container Integration (Input/Select Components)

Any component acting as a form input MUST integrate with WeWeb's Form Container using the `_wwForm:useForm` injection pattern. This enables required validation, custom validation, form submission, and form reset.

### Step 1: Add `wwElementState` Prop

```javascript
props: {
  uid: { type: String, required: true },
  content: { type: Object, required: true },
  wwElementState: { type: Object, default: () => ({}) },
  /* wwEditor:start */
  wwEditorState: { type: Object, required: true },
  /* wwEditor:end */
},
```

### Step 2: Inject and Call `useForm` in setup()

```javascript
import { computed, inject } from 'vue'

// After creating useComponentVariable for the value...
const fieldName = computed(() => props.content?.fieldName || props.wwElementState?.name)
const validation = computed(() => props.content?.validation)
const customValidation = computed(() => props.content?.customValidation)
const initValue = computed(() => props.content?.initialValue ?? '')

// Inject form integration — fallback () => {} allows standalone use without form
const useForm = inject('_wwForm:useForm', () => {})
useForm(
  internalValue,  // the reactive ref from useComponentVariable
  { fieldName, validation, customValidation, initialValue: initValue },
  { elementState: props.wwElementState, emit, sidepanelFormPath: 'form', setValue: setInternalValue }
)

/* wwEditor:start */
const selectForm = inject('_wwForm:selectForm', () => {})
/* wwEditor:end */
```

### Step 3: Hidden Native Input for HTML Form Validation

```html
<!-- In template, inside root element -->
<input
  type="input"
  :name="content?.fieldName"
  :value="currentValue"
  :required="content?.required"
  tabindex="-1"
  class="fake-input"
/>
```

```scss
.fake-input {
  background: rgba(0, 0, 0, 0);
  border: 0;
  bottom: -1px;
  font-size: 0;
  height: 1px;
  left: 0;
  outline: none;
  padding: 0;
  position: absolute;
  right: 0;
  width: 100%;
}
```

### Step 4: Form Properties in ww-config.js

```javascript
required: {
  label: { en: 'Required' },
  type: 'OnOff',
  section: 'settings',
  defaultValue: false,
  bindable: true,
  /* wwEditor:start */
  bindingValidation: {
    type: 'boolean',
    tooltip: 'A boolean value: true or false',
  },
  propertyHelp: {
    tooltip: 'Make the field required for form validation.',
  },
  /* wwEditor:end */
},
/* wwEditor:start */
form: {
  editorOnly: true,
  hidden: true,
  defaultValue: false,
},
formInfobox: {
  type: 'InfoBox',
  section: 'settings',
  options: (_, sidePanelContent) => ({
    variant: sidePanelContent.form?.name ? 'success' : 'warning',
    icon: 'pencil',
    title: sidePanelContent.form?.name || 'Unnamed form',
    content: !sidePanelContent.form?.name && 'Give your form a meaningful name.',
    cta: {
      label: 'Select form',
      action: 'selectForm',
    },
  }),
  hidden: (_, sidePanelContent) => !sidePanelContent.form?.uid,
},
/* wwEditor:end */
fieldName: {
  label: { en: 'Field name' },
  section: 'settings',
  type: 'Text',
  defaultValue: '',
  bindable: true,
  /* wwEditor:start */
  bindingValidation: {
    type: 'string',
    tooltip: 'The field name for form submission.',
  },
  /* wwEditor:end */
  hidden: (_, sidePanelContent) => !sidePanelContent.form?.uid,
},
customValidation: {
  label: { en: 'Custom validation' },
  section: 'settings',
  type: 'OnOff',
  defaultValue: false,
  bindable: true,
  /* wwEditor:start */
  bindingValidation: {
    type: 'boolean',
    tooltip: 'Enable custom validation rules.',
  },
  /* wwEditor:end */
  hidden: (_, sidePanelContent) => !sidePanelContent.form?.uid,
},
validation: {
  label: { en: 'Validation' },
  section: 'settings',
  type: 'Formula',
  defaultValue: '',
  bindable: false,
  hidden: (content, sidePanelContent) =>
    !sidePanelContent.form?.uid || !content?.customValidation,
},
```

### Step 5: Add `initValueChange` Trigger Event

```javascript
// In ww-config.js triggerEvents array
{
  name: 'initValueChange',
  label: { en: 'On init value change' },
  event: { value: '' },
}
```

### Step 6: Return `selectForm` from setup (editor-only)

```javascript
return {
  // ... other returns
  /* wwEditor:start */
  selectForm,
  /* wwEditor:end */
}
```

### How It Works
- `useForm` is injected from the parent `ww-form-container` via Vue provide/inject
- The fallback `() => {}` ensures the component works standalone (no form container)
- When placed inside a form container, form properties (`fieldName`, `customValidation`, `validation`) auto-appear in the editor
- The hidden `<input>` element enables native HTML form validation (`required`)
- `selectForm` enables the "Select form" CTA button in the editor InfoBox

## Trigger Events

```javascript
// ww-config.js
triggerEvents: [
  { name: 'click', label: { en: 'On click' }, event: { value: '' } },
]

// Component
emit('trigger-event', { name: 'click', event: { value: data } })
```

## Formula Resolution

```javascript
const { resolveMappingFormula } = wwLib.wwFormula.useFormula()

const processed = computed(() => {
  return (props.content?.items || []).map(item => {
    const name = resolveMappingFormula(props.content?.itemsNameFormula, item) ?? item.name
    return { ...item, name }
  })
})
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

## Performance

- Use `transform` and `opacity` for animations (GPU accelerated)
- Add `will-change` for animated elements
- Use `v-show` instead of `v-if` for frequently toggled elements
- Cleanup in lifecycle hooks (`onBeforeUnmount`)

## Dropzones (wwLayout)

```javascript
// ww-config.js - hidden array property
dropzoneContent: { hidden: true, defaultValue: [] }

// For repeatable content with data binding:
dropzoneItems: { hidden: true, bindable: 'repeatable', defaultValue: [] }
```

```vue
<!-- Template — direction: "row" or "column" -->
<wwLayout path="dropzoneContent" direction="row" class="dropzone" />
```

**Dropzone CSS requirements**: min-width + min-height for usability, dashed border, hover effects in wwEditor block.

```scss
.dropzone {
  min-height: 40px;
  display: flex;
  align-items: center;
  border: 2px dashed #d0d0d0;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.dropzone:empty::after {
  content: 'Drop content here';
  color: #999;
  font-size: 14px;
  font-style: italic;
  pointer-events: none;
}

/* wwEditor:start */
.dropzone:hover {
  border-color: #007aff;
  background: rgba(0, 122, 255, 0.05);
}
/* wwEditor:end */

.dropzone:not(:empty) {
  border-style: solid;
  border-color: transparent;
  background: transparent;
}
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `ref()` for content-derived data | Use `computed()` |
| Missing `?.` on content access | Always optional chain |
| Unmatched `wwEditor:start/end` | Every start needs matching end |
| TextSelect with flat options object | Use nested `options.options: [{ value, label }]` |
| Direct `document` access | `wwLib.getFrontDocument()` |
| Fixed root element dimensions | Let root adapt fluidly |
| Missing triggers/internal variables | Think from NoCode user perspective |
| Array without `expandable` + `getItemLabel` | Always include for professional UX |
| Missing imports for external utils | Always `import { fn } from 'lib'` explicitly |
| Not testing production mode | wwEditor blocks stripped — test without editor state |
| Infinite loops in value watchers | Check `if (old !== new)` before setting |
| Missing `wwElementState` prop | Required for form container integration |
| Form input without `useForm` injection | Always inject `_wwForm:useForm` for input components |
