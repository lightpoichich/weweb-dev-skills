# Progress Tracker — Test Component Spec

## Purpose

A test component designed to exercise **every feature** documented in the WeWeb dev skills. Used by the meta-test to validate that all skills produce correct, consistent code.

## Component Description

A multi-step progress tracker that displays a series of steps with labels, descriptions, and visual states (completed, active, upcoming). Supports horizontal and vertical layouts with responsive behavior.

## Feature Matrix

| Feature WeWeb | Usage in Component | Skill Tested |
|---|---|---|
| Text property | `title` — tracker heading | component-dev |
| OnOff toggle | `showLabels` — show/hide step labels | component-dev |
| Number property | `currentStep` — active step index | component-dev |
| Color property | `activeColor` — color for active/completed steps | component-dev |
| TextSelect (nested) | `layout` — horizontal/vertical/compact | component-dev |
| Array + objects | `steps` [{id, label, description}] | component-dev |
| Formula mapping | `stepsLabelFormula` — dynamic label field | component-dev |
| Internal variable | `currentStep` exposed via wwLib | component-dev |
| Trigger events | `step-click`, `step-complete`, `value-change` | component-dev + visual-qa |
| CSS variables | `--active-color`, `--step-size` | component-dev |
| Responsive | Horizontal desktop → vertical mobile | visual-qa |
| wwEditor blocks | Matched in both files | component-dev + publish |
| bindingValidation | On all bindable properties | component-dev |
| defaultValue | On all properties | component-dev |
| section | On all visible properties | component-dev |

## Properties

### `title` (Text)
- Default: `'Progress'`
- Bindable, section: settings
- bindingValidation: string

### `showLabels` (OnOff)
- Default: `true`
- Bindable, section: settings
- Controls visibility of step labels and descriptions

### `currentStep` (Number)
- Default: `0`
- Bindable, section: settings
- Options: min 0, max 100, step 1
- Also exposed as internal variable via wwLib

### `activeColor` (Color)
- Default: `'#3B82F6'`
- Bindable, section: style
- Applied via CSS variable `--active-color`

### `layout` (TextSelect)
- Options: horizontal, vertical, compact
- Default: `'horizontal'`
- Bindable, section: settings
- MUST use nested `options: { options: [...] }` format

### `steps` (Array)
- Default: 3 sample steps
- Bindable, section: settings
- expandable: true
- getItemLabel: returns `item?.label || 'Step'`
- Item schema: `{ id: Text, label: Text, description: Text }`
- bindingValidation: array

### `stepsLabelFormula` (Formula)
- Maps label field when steps are bound to external data
- Hidden when steps are not bound or empty

### `stepSize` (Number)
- Default: `32`
- Section: style
- Controls step indicator size via CSS variable `--step-size`

## Trigger Events

1. `step-click` — fired when user clicks a step, payload: `{ value: stepIndex }`
2. `step-complete` — fired when a step is marked complete, payload: `{ value: stepIndex }`
3. `value-change` — fired when currentStep changes, payload: `{ value: newStep }`

## Internal Variables

- `currentStep` (number) — exposed to bindings panel, synced from prop

## Responsive Behavior

- Desktop: horizontal layout (flex-direction: row)
- Mobile: vertical layout (flex-direction: column)
- Compact mode: minimal spacing regardless of breakpoint

## CSS Variables

- `--active-color` — from `activeColor` prop
- `--step-size` — from `stepSize` prop (in px)
