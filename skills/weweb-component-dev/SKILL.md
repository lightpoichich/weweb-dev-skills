---
name: weweb-component-dev
description: Use when editing, building, or debugging existing WeWeb custom components (wwElement.vue, ww-config.js). The authoritative reference for property definitions, reactivity, array items, dropzones, internal variables, form container integration, editor blocks, and CSS constraints. Do NOT use for scaffolding new components (use weweb-kickstart), publishing (use weweb-publish), or orchestrated multi-step development (use weweb-orchestrator).
---

# WeWeb Component Development

## Overview

Reference guide for building WeWeb custom components. WeWeb components are Vue 3 SFCs configured via `ww-config.js` for a NoCode editor. Every pattern here prevents real breakage in the editor or at runtime.

## Architecture: This Skill as Source of Truth

This skill owns the authoritative coding rules for all WeWeb component development. Other skills (kickstart, orchestrator, publish) reference these rules instead of duplicating them.

```
references/
├── weweb-rules.md          ← Core rules, property types, reactivity, triggers, CSS
└── advanced-patterns.md    ← Form container, dropzones, formula resolution
```

**When generating or modifying WeWeb component code**, always read `references/weweb-rules.md` first. For form inputs or dropzone containers, also read `references/advanced-patterns.md`.

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

1. **Optional chaining everywhere**: `props.content?.property`
2. **Matched `/* wwEditor:start/end */` blocks** in BOTH `.vue` AND `ww-config.js`
3. **Never `document`/`window` directly** — use `wwLib.getFrontDocument()` / `wwLib.getFrontWindow()`
4. **Never hardcode root dimensions** — must adapt to user-defined sizes
5. **No build config files** — `@weweb/cli` handles everything
6. **Package name without "ww"/"weweb"**
7. **Specific versions** for production deps (not "latest")
8. **Explicit imports** — never assume globals
9. **Think NoCode** — all useful triggers and internal variables
10. **Test production mode** — wwEditor blocks stripped at build

For full explanations with code examples, read `references/weweb-rules.md`.

## Quick Reference: Property Types

| Type | Key Pattern | Section |
|------|------------|---------|
| Text | `type: 'Text', defaultValue: ''` | settings |
| OnOff | `type: 'OnOff', defaultValue: false` | settings |
| Number | `type: 'Number', options: { min, max, step }` | settings |
| Color | `type: 'Color', defaultValue: '#000'` | style |
| Length | `type: 'Length', options: { noRange: true }` | style |
| TextSelect | `type: 'TextSelect', options: { options: [{ value, label }] }` | settings |
| TextRadioGroup | `type: 'TextRadioGroup', options: { choices: [{ value, title, icon }] }` | settings |
| Array | `type: 'Array', options: { expandable: true, getItemLabel, item }` | settings |
| Formula | `type: 'Formula', hidden when not bound` | settings |
| InfoBox | `type: 'InfoBox', editorOnly: true` | settings |

**Every property MUST have:** `label: { en: '...' }`, `type`, `section`, `defaultValue`
**Bindable properties MUST have:** `bindingValidation` inside `/* wwEditor:start/end */`

For full code examples of each type, read `references/weweb-rules.md`.

## Key Patterns (Summary)

### Reactivity
- **NEVER** `ref()` for content-derived data → **ALWAYS** `computed()`
- Watch all props affecting rendering for library reinitialization
- Full patterns in `references/weweb-rules.md`

### Internal Variables
- `wwLib.wwVariable.useComponentVariable({ uid, name, type, defaultValue })`
- MANDATORY reset on initialValue change
- Full pattern in `references/weweb-rules.md`

### Trigger Events
- Config: `triggerEvents: [{ name, label: { en }, event: { value: '' } }]`
- Emit: `emit('trigger-event', { name: '...', event: { value: data } })`

### CSS Variables
- Pass via `:style="dynamicStyles"` on inner child (never root)
- Use `computed()` to build the styles object
- Full pattern in `references/weweb-rules.md`

### Root Element Styling
- WeWeb overrides inline styles on root — always style an inner child
- Full pattern in `references/weweb-rules.md`

## Advanced Patterns

For these less common but critical patterns, read `references/advanced-patterns.md`:

- **Form Container Integration** — `_wwForm:useForm` injection, hidden native input, form config properties
- **Dropzones (wwLayout)** — hidden array properties, `<wwLayout>` component, CSS requirements
- **Formula Resolution** — `resolveMappingFormula()` for dynamic field mapping

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
| Styling root element directly | Style inner child — WeWeb overrides root inline styles |
| Missing `wwElementState` prop | Required for form container integration |
| Form input without `useForm` injection | Read `references/advanced-patterns.md` |
