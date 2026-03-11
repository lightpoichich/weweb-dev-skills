# Getting Started

Step-by-step guide to set up AI-assisted WeWeb component development with Claude Code.

## Prerequisites

- **Node.js** 18+ and npm
- **Claude Code** CLI installed ([docs](https://docs.anthropic.com/en/docs/claude-code))
- **WeWeb account** with custom component access
- **Playwright MCP plugin** (optional, for visual QA) — configured in Claude Code settings

## 1. Install Skills

```bash
git clone https://github.com/lightpoichich/weweb-dev-skills.git
cd weweb-dev-skills
chmod +x install.sh
./install.sh
```

This installs five skills into `~/.claude/skills/`:
- `weweb-component-dev` — Component development reference
- `weweb-visual-qa` — Playwright-based visual QA
- `weweb-orchestrator` — Multi-agent orchestrated development
- `weweb-publish` — GitHub publishing and version management
- `weweb-kickstart` — Scaffold new components from an empty directory

## 2. Create a New Component Project

### Recommended: Use the Kickstart Skill

Start Claude Code in an empty directory and say:

> "Scaffold a new WeWeb component"

Claude will use the `weweb-kickstart` skill to:
- Ask about your component (description, library, data, interactions)
- Generate all project files with a functional prototype
- Verify the dev server runs
- Hand off to the orchestrator for continued development

### Manual Alternative

If you prefer to set up manually:

```bash
mkdir my-component && cd my-component
npm init -y
npm install --save-dev @weweb/cli@latest
```

Edit `package.json`:
```json
{
  "name": "my-component",
  "version": "0.1.0",
  "scripts": {
    "serve": "ww-front-cli serve",
    "build": "ww-front-cli build"
  },
  "devDependencies": {
    "@weweb/cli": "latest"
  }
}
```

**Important:** The `name` field must NOT contain "ww" or "weweb".

## 3. Set Up CLAUDE.md

Copy the template from this repo:

```bash
cp /path/to/weweb-dev-skills/templates/CLAUDE.md.template ./CLAUDE.md
```

Edit the placeholders:
- `{{COMPONENT_NAME}}` — Your component name (e.g., `advanced-data-table`)
- `{{COMPONENT_DESCRIPTION}}` — Brief description
- `{{PROJECT_ID}}` — Your WeWeb project UUID (from the editor URL)

## 4. First Development Session

Start Claude Code in your project directory:

```bash
cd my-component
claude
```

Describe what you want to build:

> "Build a star rating component for WeWeb. It should have a configurable number of stars (1-10), a primary color, support half-star ratings, and expose the selected rating as an internal variable with a trigger event."

Claude will automatically use the `weweb-component-dev` skill to:
- Create `src/wwElement.vue` with proper Vue 3 structure
- Create `ww-config.js` with all property definitions
- Follow all WeWeb conventions (optional chaining, wwEditor blocks, etc.)

## 5. Test Locally

Start the dev server:

```bash
npm run serve --port=8080
```

Then in the WeWeb editor (`editor-dev.weweb.io`):
1. Click **Dev** in the top nav
2. Click **Add local element**
3. Enter your component name and port 8080
4. Drag the component onto the canvas

## 6. Run Visual QA

With the dev server running, tell Claude:

> "Run visual QA on my component"

Claude will use the `weweb-visual-qa` skill with Playwright MCP to:
- Navigate to the WeWeb editor
- Register your component
- Run the full test matrix (rendering, responsiveness, interactions, console errors)
- Generate a QA report

## 7. Orchestrated Development (Complex Features)

For features that span multiple aspects (config + logic + UI + QA), tell Claude:

> "Build a complex data table with sorting, filtering, and pagination. Use orchestrated development."

Claude will use the `weweb-orchestrator` skill to:
- Plan the implementation in phases
- Dispatch ephemeral Dev agents for each phase
- Review between phases (build check, code audit)
- Run visual QA after implementation
- Fix issues in an iterative loop

## 8. Build and Publish

### Build

```bash
npm run build --name=my-component
```

Fix any build errors before proceeding.

### First-Time Publish

```bash
# Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
dist/
.DS_Store
*.log
.env
EOF

# Initialize and push to GitHub
git init
git add -A
git commit -m "Initial commit: my-component WeWeb component"
gh repo create my-component --public --source=. --remote=origin --push
```

Then in the WeWeb dashboard:
1. Go to **Custom Code** → **Components**
2. Click **Add Component** → **Source Code**
3. Paste your GitHub repo URL
4. Select branch `main` and wait for the build

### Updating an Existing Component

```bash
# Bump version (patch / minor / major)
npm version minor

# Push with tags
git push origin main --tags
```

Then in the dashboard, select the new version as active.

See the [Publishing Guide](./publishing-guide.md) for branch strategies, rollback, and troubleshooting.

## Using the Starter Template

For a pre-configured `ww-config.js` with all professional patterns:

```bash
cp /path/to/weweb-dev-skills/templates/ww-config-starter.js ./ww-config.js
```

This includes:
- Correct TextSelect format (nested options)
- Array with expandable + getItemLabel + Formula mapping
- Style properties with responsive support
- Form container integration (commented, uncomment if needed)
- Dropzone pattern (commented, uncomment if needed)
- Properly matched wwEditor blocks

## Next Steps

- Read the [Orchestrator Guide](./orchestrator-guide.md) for complex multi-file features
- Read the [Visual QA Guide](./visual-qa-guide.md) for detailed QA workflows
- Read the [Publishing Guide](./publishing-guide.md) for version management and release workflow
- Check the `templates/` directory for copy-paste-ready patterns
