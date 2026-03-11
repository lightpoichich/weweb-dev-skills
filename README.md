# WeWeb Dev Skills for Claude Code

AI-assisted development skills for building WeWeb custom components with Claude Code. Five specialized skills that cover the full development lifecycle: from component architecture to visual QA to GitHub publishing.

## What This Is

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills that supercharge WeWeb custom component development:

- **Component Development Reference** — Complete API guide for properties, reactivity, arrays, dropzones, forms, triggers
- **Visual QA with Playwright** — Automated visual testing in the WeWeb editor via Playwright MCP
- **Multi-Agent Orchestrator** — CTO/Dev/QA workflow for complex multi-file features
- **GitHub Publishing** — Version management, branch strategies, and release workflow via `gh` CLI

## Skills Overview

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| `weweb-component-dev` | Complete reference for WeWeb component API: property types, reactivity patterns, arrays with formula mapping, dropzones, form container integration, internal variables, editor blocks | Any WeWeb component work |
| `weweb-visual-qa` | Automated visual testing using Playwright MCP in the WeWeb editor: rendering, responsiveness, interactions, console errors | After code changes, before publish |
| `weweb-orchestrator` | Multi-agent workflow: CTO plans phases, Dev agents implement, QA agent validates in browser | Complex multi-file features |
| `weweb-publish` | GitHub publishing: repo creation, version bumping, branch strategies, release workflow | Publish, release, deploy, version bump |
| `weweb-kickstart` | Scaffold new components from scratch: brainstorm, generate functional prototype, verify, hand off to orchestrator | New component, scaffold, kickstart, empty directory |

## Quick Install

```bash
git clone https://github.com/lightpoichich/weweb-dev-skills.git
cd weweb-dev-skills
chmod +x install.sh
./install.sh
```

By default, skills are **symlinked** so `git pull` updates them automatically. Use `--copy` for standalone copies.

## Manual Install

Copy the skill directories to your Claude Code skills folder:

```bash
cp -r skills/weweb-component-dev ~/.claude/skills/
cp -r skills/weweb-visual-qa ~/.claude/skills/
cp -r skills/weweb-orchestrator ~/.claude/skills/
cp -r skills/weweb-publish ~/.claude/skills/
cp -r skills/weweb-kickstart ~/.claude/skills/
```

## Templates Included

| Template | Description |
|----------|-------------|
| `templates/CLAUDE.md.template` | Project-level instructions for WeWeb component projects — fill in placeholders and drop into your repo |
| `templates/qa-report.md` | Structured QA report template (16 tests, severity levels, iteration tracking) |
| `templates/ww-config-starter.js` | Production-ready `ww-config.js` with all professional patterns pre-configured |

## Usage Examples

### Starting a New Component

**Or use the Kickstart skill** for a guided setup from scratch:
```
> Scaffold a new WeWeb component
```

```
> Build a star rating component for WeWeb. It should have configurable star count,
> primary color, half-star support, and expose the rating as an internal variable.
```

Claude automatically uses `weweb-component-dev` to generate:
- `src/wwElement.vue` with proper Vue 3 structure, optional chaining, reactivity
- `ww-config.js` with correct property types, editor blocks, triggers

### Running Visual QA

```
> Run visual QA on my component
```

Claude uses `weweb-visual-qa` with Playwright MCP to:
- Navigate to the WeWeb editor, register the component
- Test rendering at 3 viewports (desktop, tablet, mobile)
- Verify property changes update in realtime
- Check for console errors
- Generate a structured QA report

### Orchestrated Development

```
> Build a data table with sorting, filtering, and pagination. Use orchestrated development.
```

Claude uses `weweb-orchestrator` to:
- Plan implementation in 5 phases (Setup → Config → Logic → UI → QA)
- Dispatch ephemeral Dev agents per phase with full WeWeb context
- Review between phases (build check, code audit)
- Run visual QA, fix issues in iterative loop

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Node.js 18+
- WeWeb account with custom component access
- [Playwright MCP plugin](https://github.com/anthropics/claude-code) configured (for visual QA)

## Meta-Test

A 42-check automated validation suite that verifies all skills produce correct, consistent code. Catches regressions after skill modifications.

```bash
# Run all checks
./tests/run-meta-test.sh

# Verbose output
./tests/run-meta-test.sh --verbose
```

The meta-test uses a golden reference "Progress Tracker" component that exercises every WeWeb feature: Text, OnOff, Number, Color, TextSelect (nested), Array with expandable/getItemLabel, Formula mapping, internal variables, trigger events, CSS variables, responsive layout, and matched wwEditor blocks.

## Project Structure

```
weweb-dev-skills/
├── README.md
├── install.sh
│
├── skills/
│   ├── weweb-component-dev/
│   │   └── SKILL.md
│   ├── weweb-visual-qa/
│   │   └── SKILL.md
│   ├── weweb-orchestrator/
│   │   └── SKILL.md
│   ├── weweb-publish/
│   │   └── SKILL.md
│   ├── weweb-kickstart/
│   │   └── SKILL.md
│   └── weweb-meta-test/
│       └── SKILL.md          # Internal — not installed via install.sh
│
├── tests/
│   ├── run-meta-test.sh      # 42-check validation script
│   ├── fixtures/              # Golden reference component
│   │   ├── progress-tracker-spec.md
│   │   ├── package.json
│   │   ├── ww-config.js
│   │   └── src/wwElement.vue
│   └── reports/               # Generated reports (gitignored)
│
├── templates/
│   ├── CLAUDE.md.template
│   ├── qa-report.md
│   └── ww-config-starter.js
│
└── docs/
    ├── getting-started.md
    ├── orchestrator-guide.md
    ├── visual-qa-guide.md
    └── publishing-guide.md
```

## Documentation

- [Getting Started](docs/getting-started.md) — Step-by-step setup guide
- [Orchestrator Guide](docs/orchestrator-guide.md) — Detailed multi-agent workflow
- [Visual QA Guide](docs/visual-qa-guide.md) — Playwright testing deep dive
- [Publishing Guide](docs/publishing-guide.md) — GitHub publishing and version management
- [Kickstart Guide](docs/kickstart-guide.md) — Scaffolding new components from scratch

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Make your changes
4. Test by installing locally (`./install.sh`)
5. Submit a PR with a clear description

### Skill Development Guidelines

- Skills must have valid YAML frontmatter (`name`, `description`)
- No absolute paths or project-specific references
- Include practical code examples for every pattern
- Test with Claude Code to verify skill triggers correctly

## License

MIT
