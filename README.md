# WeWeb Dev Skills for Claude Code

AI-assisted development skills for building WeWeb custom components with Claude Code. Three specialized skills that cover the full development lifecycle: from component architecture to visual QA.

## What This Is

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills that supercharge WeWeb custom component development:

- **Component Development Reference** — Complete API guide for properties, reactivity, arrays, dropzones, forms, triggers
- **Visual QA with Playwright** — Automated visual testing in the WeWeb editor via Playwright MCP
- **Multi-Agent Orchestrator** — CTO/Dev/QA workflow for complex multi-file features

## Skills Overview

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| `weweb-component-dev` | Complete reference for WeWeb component API: property types, reactivity patterns, arrays with formula mapping, dropzones, form container integration, internal variables, editor blocks | Any WeWeb component work |
| `weweb-visual-qa` | Automated visual testing using Playwright MCP in the WeWeb editor: rendering, responsiveness, interactions, console errors | After code changes, before publish |
| `weweb-orchestrator` | Multi-agent workflow: CTO plans phases, Dev agents implement, QA agent validates in browser | Complex multi-file features |

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
```

## Templates Included

| Template | Description |
|----------|-------------|
| `templates/CLAUDE.md.template` | Project-level instructions for WeWeb component projects — fill in placeholders and drop into your repo |
| `templates/qa-report.md` | Structured QA report template (16 tests, severity levels, iteration tracking) |
| `templates/ww-config-starter.js` | Production-ready `ww-config.js` with all professional patterns pre-configured |

## Usage Examples

### Starting a New Component

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

## Project Structure

```
weweb-dev-skills/
├── README.md
├── install.sh
│
├── skills/
│   ├── weweb-orchestrator/
│   │   └── SKILL.md
│   ├── weweb-component-dev/
│   │   └── SKILL.md
│   └── weweb-visual-qa/
│       └── SKILL.md
│
├── templates/
│   ├── CLAUDE.md.template
│   ├── qa-report.md
│   └── ww-config-starter.js
│
└── docs/
    ├── getting-started.md
    ├── orchestrator-guide.md
    └── visual-qa-guide.md
```

## Documentation

- [Getting Started](docs/getting-started.md) — Step-by-step setup guide
- [Orchestrator Guide](docs/orchestrator-guide.md) — Detailed multi-agent workflow
- [Visual QA Guide](docs/visual-qa-guide.md) — Playwright testing deep dive

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
