# WeWeb Dev Skills — Project Instructions

## What This Project Is

A collection of Claude Code skills for WeWeb custom component development. These skills are installed into `~/.claude/skills/` and used across WeWeb component projects. This is NOT a WeWeb component itself — it's the tooling that helps build them.

## Project Structure

```
skills/               — Skill definitions (SKILL.md files)
  weweb-component-dev/  — Component API reference (properties, reactivity, arrays, dropzones, forms)
  weweb-visual-qa/      — Playwright-based visual QA in WeWeb editor
  weweb-orchestrator/   — Multi-agent CTO/Dev/QA workflow
  weweb-publish/        — GitHub publishing and version management
  weweb-kickstart/      — Scaffold new components from empty directory
  weweb-meta-test/      — Meta-test skill (internal, not installed)
docs/                 — Extended guides for each skill
templates/            — Starter templates (CLAUDE.md, QA report, ww-config.js)
tests/                — Meta-test: golden reference + validation script
  fixtures/             — Progress Tracker golden reference component
  run-meta-test.sh      — Automated validation (42 checks, CI-friendly)
  reports/              — Generated test reports (gitignored)
install.sh            — Symlink/copy installer to ~/.claude/skills/
```

## Key Conventions

- Skills use YAML frontmatter (`name`, `description`) — these must match what Claude Code expects for triggering
- No absolute paths or user-specific references inside skills — they must be portable
- Skills reference each other (e.g., orchestrator dispatches visual-qa) — keep cross-references consistent when editing
- All code examples in skills should use WeWeb patterns: Vue 3 Composition API, `wwLib`, optional chaining on `content`

## WeWeb Editor Context

Important details about the WeWeb editor UI that skills must reference correctly:

- **Dev editor URL**: `editor-dev.weweb.io` (NOT `editor.weweb.io`) — only dev editor supports local component loading
- **Breakpoint testing**: Use the 3 breakpoint buttons in the WeWeb top toolbar (desktop/tablet/mobile icons) — do NOT use `browser_resize` for responsive testing
- **Edit mode**: Click "Edit" button in toolbar (next to "AI") to access the settings/properties panel — required before modifying component props or injecting data
- **Canvas iframe**: Components render inside `#ww-manager-iframe`
- **Drag-drop**: Sidebar intercepts HTML5 drag events — must use manual `page.mouse` API

## When Editing Skills

1. Keep skills self-contained — each SKILL.md should work standalone
2. Update both the skill (`skills/*/SKILL.md`) AND the corresponding doc (`docs/*.md`) when making changes
3. Test that skill triggers correctly by checking the `description` in frontmatter matches expected use cases
4. Maintain the QA report format in `templates/qa-report.md` if test matrix changes
5. **Run the meta-test** after any skill change: `./tests/run-meta-test.sh` — validates 42 checks across all skills

## Language

The primary user speaks French. Skills and docs are written in English for portability, but conversation and explanations should be in French.
