---
name: weweb-orchestrator
description: Use when building a WeWeb component feature end-to-end that requires planning, implementation, and QA. Triggers on multi-step feature work, vertical slices, rebuilds, or when orchestration is explicitly requested. Manages complexity by splitting work across ephemeral agents with fresh context.
---

# WeWeb Component Orchestrator

## Overview

Trade one long conversation for many disposable specialized sessions. A persistent CTO agent plans and orchestrates, ephemeral Developer agents implement WeWeb components, and a QA agent validates visually in the WeWeb editor via Playwright MCP. Fresh context per agent prevents context bloat and catches mistakes a fatigued session would miss.

## Source of Truth

Before dispatching ANY Dev agent, read the authoritative WeWeb rules:

```
~/.claude/skills/weweb-component-dev/references/weweb-rules.md
```

Include the content of this file in every Dev agent prompt under a "## WeWeb Rules" section. This ensures every ephemeral agent gets the same, up-to-date rules — no stale copies, no drift.

If the task involves form containers or dropzones, also read and include content from:
```
~/.claude/skills/weweb-component-dev/references/advanced-patterns.md
```

## When to Use

- Building a component feature that spans both `wwElement.vue` and `ww-config.js` with significant complexity
- Rebuilding or restructuring a WeWeb custom component
- Any task that would take 30+ tool calls in a single agent
- Adding multiple interrelated features (arrays + formulas + dropzones + triggers)
- User explicitly requests orchestrated development

## When NOT to Use

- Single property addition or quick CSS fix
- Pure research/exploration tasks
- Tasks with fewer than 3 distinct steps
- Simple bug fixes in one file

## The Three Agents

```
┌─────────────┐
│    User      │
└──────┬───────┘
       │ task
       ▼
┌──────────────────────────────────────┐
│  CTO Agent (persistent)              │
│  Plans, reviews, never writes code   │
└──┬────────────────┬──────────────────┘
   │ spawns          │ spawns
   ▼                 ▼
┌────────────┐  ┌────────────────────┐
│ Dev Agent  │  │ QA Agent           │
│ (ephemeral)│  │ (ephemeral)        │
│ Implements │  │ Playwright MCP     │
│ Commits    │  │ Screenshots        │
└────────────┘  └────────────────────┘
```

### CTO Agent (You — the persistent session)
- Plans features, breaks into phased tasks
- **Reads `weweb-rules.md`** and includes it in every Dev agent prompt
- Dispatches Dev agents with full task specs (agent never reads plan files)
- Reviews results between phases (`npx weweb build`, wwEditor block audit, optional chaining check)
- Dispatches QA agent after implementation
- Routes bug fixes back to new Dev agents
- **NEVER writes code directly**

### Developer Agent (Ephemeral subagent)
- Spawned fresh per task — no prior context, no assumptions
- Receives complete task spec inline including WeWeb rules from `weweb-rules.md`
- Works on `src/wwElement.vue` and/or `ww-config.js`
- Commits after each completed task
- Reports back: what was done, build result, issues encountered
- Dies after task completion

### QA Agent (Ephemeral — Playwright MCP)
- Spawned after all Dev work is complete
- Tests the component in the WeWeb editor via Playwright MCP tools
- Takes screenshots at multiple viewports
- Writes structured bug report to `docs/qa-report.md`
- Reports bugs by severity (BLOCKING, IMPORTANT, LOW, INFO)

## Process Flow

```
1. CTO: Brainstorm + Design
         │
         ▼
2. CTO: Write Implementation Plan (phased tasks)
         │
         ▼
3. CTO: Read weweb-rules.md + Dispatch Dev Agent(s) ◄──── fail: re-dispatch
         │                                                    │
         ▼                                                    │
4. CTO: Review (build, wwEditor, ?.)──────────────────────────┘
         │
         ▼ pass
5. More phases? ──yes──► back to step 3
         │
         no
         ▼
6. CTO: Start dev server + Dispatch QA Agent
         │
         ▼
7. Bugs found? ──yes──► CTO: Dispatch Fix Agent ──► re-QA (max 3)
         │
         no
         ▼
8. Done ✓
         │
         ▼ (optional)
9. CTO: Publish (weweb-publish skill)
```

## Phasing Strategy (WeWeb-Specific)

| Phase | Content | Files | Execution |
|-------|---------|-------|-----------|
| **Setup** | Package.json, dependencies, project scaffold | `package.json` | Sequential (one agent) |
| **Config** | Property definitions, sections, TextSelects, Arrays | `ww-config.js` | Sequential |
| **Component Logic** | Vue setup, computed props, watchers, internal variables | `src/wwElement.vue` (script) | Sequential |
| **UI / Style** | Template structure, scoped SCSS, CSS variables | `src/wwElement.vue` (template + style) | Can parallel with triggers |
| **Triggers & Events** | Trigger events, emit patterns, event payloads | Both files | Sequential |
| **QA** | Browser testing, bug fixes | N/A | Sequential |
| **Publish** (optional) | Version bump, GitHub push, dashboard instructions | `package.json` | Sequential |

**Key rule:** Tasks within a phase can run in parallel only if they don't touch the same files.

## Dispatching a Dev Agent

Use the Agent tool with a comprehensive prompt:

```
Agent(
  name: "dev-phase-2-config",
  description: "ww-config property definitions",
  mode: "bypassPermissions",
  prompt: <see template below>
)
```

### Dev Agent Prompt Template

**Before using this template**, read `~/.claude/skills/weweb-component-dev/references/weweb-rules.md` and paste its content into the `## WeWeb Rules` section below. If the task involves form containers or dropzones, also include content from `advanced-patterns.md`.

```markdown
You are an ephemeral Developer Agent building a WeWeb custom component.

## Project Context
- **Working directory:** [path to project]
- **Component:** [component name and description]
- **Files:** `src/wwElement.vue` (Vue 3 SFC), `ww-config.js` (editor config)

## WeWeb Rules
[PASTE CONTENT OF weweb-rules.md HERE — this is the single source of truth]

## Your Task
[Exact specification: files to modify, code to write, patterns to follow]

## Existing Code
[Paste relevant existing file content — agent has no prior context]

## Verification
After completing the task:
1. Run `npx weweb build -- name=[component-name] type=wwobject` — must succeed with no errors
2. Verify all `/* wwEditor:start */` have matching `/* wwEditor:end */`
3. Verify all `props.content` references use optional chaining (`?.`)
4. Commit with a clear message describing the change

## Report Back
Summarize: what was done, build result, any issues or decisions made.
```

### What to Include in Task Spec
- **Complete code snippets** — the agent has no prior context
- **Existing file content** that the agent needs to know about (relevant exports, interfaces)
- **Property names and types** already defined (to avoid conflicts)
- **Trigger event names** already registered

## Dispatching the QA Agent

After all Dev work, start the dev server and dispatch QA:

```markdown
You are a QA Agent testing a WeWeb custom component.

## Parameters
- **Component:** [COMPONENT_NAME]
- **Port:** [PORT]
- **Project ID:** [PROJECT_ID from editor URL]
- **Features to test:** [list of features implemented]

## Process
1. Verify dev server: `curl -sk https://localhost:[PORT]/ -o /dev/null -w "%{http_code}"` (expect 200)
2. Accept SSL cert: `browser_navigate("https://localhost:[PORT]/")`, then type `thisisunsafe`
3. Navigate to: `browser_navigate("https://editor-dev.weweb.io/[PROJECT_ID]")`
4. Register component via Dev panel (name: [COMPONENT_NAME], port: [PORT])
5. Drag-drop component to canvas using manual mouse API:
   ```javascript
   async (page) => {
     const source = page.locator('div').filter({ hasText: /^COMPONENT_NAME - PORT$/ }).nth(1);
     const sourceBox = await source.boundingBox();
     const iframe = page.locator('#ww-manager-iframe');
     const iframeBox = await iframe.boundingBox();
     await page.mouse.move(sourceBox.x + sourceBox.width/2, sourceBox.y + sourceBox.height/2);
     await page.mouse.down();
     await page.mouse.move(sourceBox.x + 10, sourceBox.y, { steps: 3 });
     await page.mouse.move(iframeBox.x + iframeBox.width/2, iframeBox.y + iframeBox.height/2, { steps: 20 });
     await page.waitForTimeout(500);
     await page.mouse.up();
   }
   ```
6. **Generate component-specific test plan**: Read `ww-config.js` + `src/wwElement.vue`, extract all properties, trigger events, toggleable features, interactions, and generate a numbered test plan specific to THIS component (see weweb-visual-qa skill Step 6)
7. Click "Edit" button in toolbar (next to "AI") to enter Edit mode
8. Generate smart dummy data based on Array property schemas:
   - **Empty** (0 items): test empty state
   - **Typical** (5-15 items): realistic data with accented chars, mixed values
   - **Stress** (50-200 items): long strings, special chars, extreme numbers, duplicates, nulls
9. Bind each dataset via settings panel, screenshot after each
10. Execute the component-specific test plan (property changes, interactions, feature toggles)
11. Test responsive via WeWeb breakpoint buttons (desktop/tablet/mobile) in toolbar
12. Check console errors: `browser_console_messages(level="error")` after all data + interaction tests
13. Write report to `docs/qa-report.md` (include component analysis + specific test results)
14. Report back: PASS/FAIL + issue summary by severity

## Severity Levels
- **BLOCKING:** Crashes, doesn't render, editor errors → must fix
- **IMPORTANT:** Feature broken, visual regression → should fix
- **LOW:** Cosmetic, minor layout → can ship
- **INFO:** Suggestion, enhancement idea → optional
```

## CTO Review Checklist (Between Phases)

Run these checks after each Dev agent completes:

```bash
# 1. Build check — must pass
npx weweb build -- name=[component-name] type=wwobject

# 2. wwEditor block audit — every start must have matching end
grep -n "wwEditor:start\|wwEditor:end" src/wwElement.vue ww-config.js

# 3. Optional chaining audit — no bare props.content. references
grep -n "props\.content\." src/wwElement.vue | grep -v "props\.content\?\."

# 4. Working tree status
git log --oneline -5
git status --short
```

**If any check fails:** Do NOT proceed to next phase. Dispatch a fix agent.

## Iteration Loop

```
QA Report
  │
  ├── All PASS → Done ✓
  │
  └── Issues found
        │
        ├── Iteration 1: Dispatch fix agent → Re-run QA
        │
        ├── Iteration 2: Dispatch fix agent → Re-run QA
        │
        └── Iteration 3 (FINAL): Dispatch fix agent → Re-run QA
              │
              └── If still failing → Escalate to user with full report
```

**Max 3 iterations.** If bugs persist after 3 fix-QA cycles, present the user with:
- Full QA report with remaining issues
- What was attempted
- Recommended manual investigation areas

## Optional Publish Phase

After QA passes and the user confirms readiness, invoke the `weweb-publish` skill:

1. **CTO confirms:** All QA iterations pass, user wants to publish
2. **Auto-detect:** Run `git remote get-url origin` to determine first publish vs update
3. **First publish:** Create GitHub repo with `gh repo create`, push code, provide dashboard instructions
4. **Update:** Determine bump type (patch/minor/major), run `npm version`, push with tags
5. **Dashboard instructions:** Provide clear manual steps (cannot be automated)

**Important:** Publishing is always optional and user-initiated. The CTO should ask before proceeding to publish. Not every development session ends with a release.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| CTO writes code directly | Only dispatch agents. CTO plans and reviews. |
| Agent prompt too vague | Include complete code, file paths, and weweb-rules.md content |
| Skipping CTO review between phases | Always verify build + wwEditor blocks before next phase |
| Parallel agents touching same files | `wwElement.vue` and `ww-config.js` are usually coupled — serialize |
| QA without dev server running | Start `npm run serve --port=PORT` before Playwright testing |
| Not committing between tasks | Each agent commits its work before dying |
| Hardcoding WeWeb rules in prompt | Read `weweb-rules.md` at dispatch time — rules may have been updated |
| Using `editor.weweb.io` for QA | Must use `editor-dev.weweb.io` for local component loading |
| Forgetting SSL cert step | Must type `thisisunsafe` at start of each Playwright session |
