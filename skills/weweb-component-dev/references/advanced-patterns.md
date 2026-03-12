# WeWeb Advanced Patterns

Read this file when implementing form containers, dropzones, or formula resolution. These patterns are less common but critical when needed.

## Form Container Integration

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
- When placed inside a form container, form properties auto-appear in the editor
- The hidden `<input>` enables native HTML form validation (`required`)
- `selectForm` enables the "Select form" CTA button in the editor InfoBox

## Dropzones (wwLayout)

Dropzones let NoCode users drag other elements inside your component.

### ww-config.js

```javascript
// Hidden array property — users manage content visually, not via settings
dropzoneContent: { hidden: true, defaultValue: [] }

// For repeatable content with data binding:
dropzoneItems: { hidden: true, bindable: 'repeatable', defaultValue: [] }
```

### Template

```vue
<!-- direction: "row" or "column" -->
<wwLayout path="dropzoneContent" direction="row" class="dropzone" />
```

### Required CSS

Dropzones need visual affordance in the editor — min-size for usability, dashed border for discoverability:

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

## Formula Resolution

Use `resolveMappingFormula` to resolve user-configured field mappings on bound data:

```javascript
const { resolveMappingFormula } = wwLib.wwFormula.useFormula()

const processed = computed(() => {
  return (props.content?.items || []).map(item => {
    const name = resolveMappingFormula(props.content?.itemsNameFormula, item) ?? item.name
    return { ...item, name }
  })
})
```
