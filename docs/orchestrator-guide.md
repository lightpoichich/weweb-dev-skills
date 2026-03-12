# Orchestrator Guide

Detailed guide for using the `weweb-orchestrator` skill to build complex WeWeb components with multi-agent orchestration.

## When to Use Orchestration

**Use orchestration when:**
- Building a feature that touches both `wwElement.vue` and `ww-config.js` with significant complexity
- Adding multiple interrelated features (arrays + formulas + dropzones + triggers)
- Rebuilding or restructuring a component
- The task would take 30+ tool calls in a single agent session

**Use direct development when:**
- Adding a single property or fixing a CSS issue
- Quick bug fixes in one file
- Tasks with fewer than 3 distinct steps

## How the CTO Agent Works

The CTO is the persistent session — it's **you** (Claude Code in the main conversation). The CTO:

1. **Plans** — Breaks the feature into phases with dependencies
2. **Dispatches** — Spawns ephemeral agents with full task specs
3. **Reviews** — Verifies each phase before moving to the next
4. **Routes fixes** — When QA finds bugs, dispatches new fix agents

**The CTO NEVER writes code directly.** All implementation is done by Dev agents.

## How Dev Agents Work

Each Dev agent is **ephemeral** — spawned fresh with zero prior context. This is intentional:
- Fresh context prevents hallucination from stale state
- Each agent gets exactly what it needs, nothing more
- Mistakes from one agent don't propagate

### What to Include in a Dev Agent Prompt

1. **Project context** — Working directory, component purpose
2. **WeWeb Rules from source of truth** — Read `~/.claude/skills/weweb-component-dev/references/weweb-rules.md` and paste its content into the prompt. This replaces manually listing the 10 rules — the reference file is always up-to-date.
3. **Existing code** — Relevant file contents the agent needs
4. **Task specification** — Exact files to modify, code patterns to follow
5. **Verification steps** — Build check, wwEditor audit, optional chaining check
6. **Commit instructions** — What to commit and message format

### Example: Dispatching a Config Phase Agent

```
Agent(
  name: "dev-config-phase",
  description: "ww-config property definitions",
  mode: "bypassPermissions",
  prompt: "You are an ephemeral Developer Agent.

  ## Project
  Working directory: /path/to/my-component
  Component: Advanced Data Table with sorting and filtering

  ## WeWeb Rules
  [paste content of ~/.claude/skills/weweb-component-dev/references/weweb-rules.md]

  ## Task
  Create ww-config.js with:
  - columns: Array with expandable, getItemLabel, Formula mapping
  - sortable: OnOff toggle
  - sortDirection: TextSelect (asc/desc)
  - filterEnabled: OnOff toggle
  - pageSize: Number (5-100, step 5)
  - Theme: TextSelect (light/dark/auto)
  - All style properties with responsive support

  ## Existing Code
  package.json: { name: 'advanced-data-table', ... }

  ## Verification
  1. npm run build --name=advanced-data-table
  2. All wwEditor:start have matching wwEditor:end
  3. Commit: 'feat: add ww-config.js with table properties'
  "
)
```

## The Review Cycle

After each Dev agent completes, the CTO runs:

```bash
# Build must pass
npm run build --name=component-name

# Every start has a matching end
grep -n "wwEditor:start\|wwEditor:end" src/wwElement.vue ww-config.js

# No bare props.content. without optional chaining
grep -n "props\.content\." src/wwElement.vue | grep -v "props\.content\?\."

# Clean working tree
git log --oneline -5
git status --short
```

If anything fails, the CTO dispatches a fix agent before proceeding.

## WeWeb-Specific Phases

| Phase | Focus | Files | Notes |
|-------|-------|-------|-------|
| **Setup** | Dependencies, package.json | `package.json` | One agent, sequential |
| **Config** | Property definitions | `ww-config.js` | Critical: TextSelect format, Array patterns |
| **Logic** | Vue setup, computed, watchers | `wwElement.vue` script | Reactivity rules, internal variables |
| **UI/Style** | Template + SCSS | `wwElement.vue` template/style | CSS variables, responsive, no fixed root dims |
| **Triggers** | Events, emit patterns | Both files | Connect config triggers to component emits |
| **QA** | Browser testing | N/A | Playwright via `weweb-visual-qa` skill |

### Phase Dependencies

```
Setup → Config → Logic → UI/Style → Triggers → QA
                    ↘                ↗
                     (can parallel if independent)
```

**Key constraint:** `wwElement.vue` and `ww-config.js` are tightly coupled. Avoid parallel agents on both files unless they're truly independent (e.g., one adds a style property, another adds a trigger).

## QA Phase

After all Dev work:

1. CTO starts the dev server: `npm run serve --port=8080`
2. CTO dispatches QA agent with the `weweb-visual-qa` prompt template
3. QA agent tests in the WeWeb editor via Playwright MCP
4. QA reports back with pass/fail + issue list

### The Fix Loop

```
QA finds bugs → CTO dispatches fix agent → Re-run QA → max 3 iterations
```

If bugs persist after 3 cycles, the CTO escalates to the user with:
- Full QA report
- What was attempted
- Recommended manual investigation

## Tips for Effective Prompting

1. **Be exhaustive in Dev agent prompts** — Include complete code snippets, not just descriptions
2. **Include the 10 Critical Rules** — Every time, in every Dev agent prompt
3. **Specify exact file paths** — The agent has no context from previous sessions
4. **List existing properties** — So the agent doesn't create conflicts
5. **Require build verification** — Every agent must run `npm run build` before committing
6. **One concern per agent** — Config in one, logic in another, not mixed

## Example: Full Orchestration Session

```
User: "Build a color picker component with preset palettes, custom color input, and opacity slider"

CTO Plan:
  Phase 1 (Setup): package.json with dependencies
  Phase 2 (Config): Properties — palettes array, showCustom toggle, showOpacity toggle, style props
  Phase 3 (Logic): Internal variable for selected color, computed palettes, watchers
  Phase 4 (UI): Template with palette grid, custom input, opacity slider, SCSS
  Phase 5 (Triggers): color-change, palette-select, opacity-change events
  Phase 6 (QA): Full visual test matrix

CTO dispatches:
  → Dev Agent 1: Setup + Config (small enough to combine)
  → CTO Review: build ✓, wwEditor blocks ✓
  → Dev Agent 2: Logic
  → CTO Review: build ✓, optional chaining ✓
  → Dev Agent 3: UI/Style
  → CTO Review: build ✓, no fixed root dims ✓
  → Dev Agent 4: Triggers
  → CTO Review: build ✓, all triggers connected ✓
  → QA Agent: Full test matrix
  → Bug: opacity slider doesn't update in realtime
  → Fix Agent 1: Add opacity to watcher array
  → QA Agent (round 2): All pass ✓
```
