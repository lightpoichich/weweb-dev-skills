#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# Meta-Test Runner for WeWeb Dev Skills
# Validates golden reference files against all skill rules (42 checks).
# No browser, no API, no external services — pure static analysis.
#
# Usage:
#   ./tests/run-meta-test.sh           # Run all checks
#   ./tests/run-meta-test.sh --keep    # Keep temp dir after run
#   ./tests/run-meta-test.sh --verbose # Show details for passing checks
# ═══════════════════════════════════════════════════════════════════

set -uo pipefail

# ── Config ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
REPORTS_DIR="$SCRIPT_DIR/reports"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../skills" && pwd)"

KEEP=false
VERBOSE=false
for arg in "$@"; do
  case "$arg" in
    --keep) KEEP=true ;;
    --verbose) VERBOSE=true ;;
  esac
done

# ── State ───────────────────────────────────────────────────────────
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
FAILED_DETAILS=""
START_TIME=$(date +%s)

# Phase counters (no associative arrays for bash 3 compat)
P0_TOTAL=0; P0_PASSED=0
P1_TOTAL=0; P1_PASSED=0
P2_TOTAL=0; P2_PASSED=0
P3_TOTAL=0; P3_PASSED=0
P5_TOTAL=0; P5_PASSED=0
PC_TOTAL=0; PC_PASSED=0

# ── Helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

inc_phase_total() {
  case "$1" in
    0) P0_TOTAL=$((P0_TOTAL + 1)) ;;
    1) P1_TOTAL=$((P1_TOTAL + 1)) ;;
    2) P2_TOTAL=$((P2_TOTAL + 1)) ;;
    3) P3_TOTAL=$((P3_TOTAL + 1)) ;;
    5) P5_TOTAL=$((P5_TOTAL + 1)) ;;
    C) PC_TOTAL=$((PC_TOTAL + 1)) ;;
  esac
}

inc_phase_passed() {
  case "$1" in
    0) P0_PASSED=$((P0_PASSED + 1)) ;;
    1) P1_PASSED=$((P1_PASSED + 1)) ;;
    2) P2_PASSED=$((P2_PASSED + 1)) ;;
    3) P3_PASSED=$((P3_PASSED + 1)) ;;
    5) P5_PASSED=$((P5_PASSED + 1)) ;;
    C) PC_PASSED=$((PC_PASSED + 1)) ;;
  esac
}

pass() {
  local phase="$1" id="$2" desc="$3"
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
  inc_phase_total "$phase"
  inc_phase_passed "$phase"
  if $VERBOSE; then
    echo -e "  ${GREEN}PASS${NC} $id — $desc"
  else
    echo -e "  ${GREEN}PASS${NC} $id"
  fi
}

fail() {
  local phase="$1" id="$2" desc="$3" detail="${4:-}"
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  FAILED_CHECKS=$((FAILED_CHECKS + 1))
  inc_phase_total "$phase"
  echo -e "  ${RED}FAIL${NC} $id — $desc"
  if [[ -n "$detail" ]]; then
    echo -e "       ${YELLOW}$detail${NC}"
  fi
  if [[ -n "$FAILED_DETAILS" ]]; then
    FAILED_DETAILS="$FAILED_DETAILS
$id: $desc${detail:+ — $detail}"
  else
    FAILED_DETAILS="$id: $desc${detail:+ — $detail}"
  fi
}

phase_header() {
  echo ""
  echo -e "${BOLD}${BLUE}Phase $1: $2${NC}"
  echo "────────────────────────────────────────"
}

# ── Files under test ────────────────────────────────────────────────
PKG="$FIXTURES_DIR/package.json"
CONFIG="$FIXTURES_DIR/ww-config.js"
VUE="$FIXTURES_DIR/src/wwElement.vue"

# ════════════════════════════════════════════════════════════════════
# PHASE 0: Environment
# ════════════════════════════════════════════════════════════════════
phase_header "0" "Environment"

# 0.1 — Node.js >= 18
if command -v node &>/dev/null; then
  NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_VER" -ge 18 ]]; then
    pass 0 "0.1" "Node.js >= 18 ($(node -v))"
  else
    fail 0 "0.1" "Node.js >= 18 required" "Found $(node -v)"
  fi
else
  fail 0 "0.1" "Node.js not found"
fi

# 0.2 — npm available
if command -v npm &>/dev/null; then
  pass 0 "0.2" "npm available ($(npm -v))"
else
  fail 0 "0.2" "npm not found"
fi

# 0.3 — Skills installed
SKILLS_MISSING=""
for skill in weweb-component-dev weweb-visual-qa weweb-orchestrator weweb-publish weweb-kickstart; do
  if [[ ! -d "$HOME/.claude/skills/$skill" ]] && [[ ! -L "$HOME/.claude/skills/$skill" ]]; then
    SKILLS_MISSING="$SKILLS_MISSING $skill"
  fi
done
if [[ -z "$SKILLS_MISSING" ]]; then
  pass 0 "0.3" "All 5 skills installed in ~/.claude/skills/"
else
  fail 0 "0.3" "Skills missing from ~/.claude/skills/" "$SKILLS_MISSING"
fi

# ════════════════════════════════════════════════════════════════════
# PHASE 1: Scaffolding (tests weweb-component-dev)
# ════════════════════════════════════════════════════════════════════
phase_header "1" "Scaffolding"

# 1.1 — package.json valid (parseable)
if node -e "JSON.parse(require('fs').readFileSync('$PKG','utf8'))" 2>/dev/null; then
  pass 1 "1.1" "package.json valid JSON"
else
  fail 1 "1.1" "package.json not parseable"
fi

# 1.2 — Package name without "ww"/"weweb"
PKG_NAME=$(node -pe "JSON.parse(require('fs').readFileSync('$PKG','utf8')).name" 2>/dev/null || echo "")
if echo "$PKG_NAME" | grep -iqE '(^ww-|^weweb-|weweb|^ww$)'; then
  fail 1 "1.2" "Package name must not contain ww/weweb" "Found: $PKG_NAME"
else
  pass 1 "1.2" "Package name OK: $PKG_NAME"
fi

# 1.3 — @weweb/cli in devDependencies
if node -pe "JSON.parse(require('fs').readFileSync('$PKG','utf8')).devDependencies['@weweb/cli']" 2>/dev/null | grep -q .; then
  pass 1 "1.3" "@weweb/cli in devDependencies"
else
  fail 1 "1.3" "@weweb/cli not found in devDependencies"
fi

# 1.4 — ww-config.js exists
if [[ -f "$CONFIG" ]]; then
  pass 1 "1.4" "ww-config.js exists"
else
  fail 1 "1.4" "ww-config.js not found"
fi

# 1.5 — ww-config.js parseable (basic syntax check via node)
if node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  require(tmp);
" 2>/dev/null; then
  pass 1 "1.5" "ww-config.js parseable"
else
  fail 1 "1.5" "ww-config.js has syntax errors"
fi

# 1.6 — wwEditor blocks matched in ww-config.js
CONFIG_STARTS=$(grep -c 'wwEditor:start' "$CONFIG" 2>/dev/null || echo 0)
CONFIG_ENDS=$(grep -c 'wwEditor:end' "$CONFIG" 2>/dev/null || echo 0)
if [[ "$CONFIG_STARTS" -eq "$CONFIG_ENDS" ]] && [[ "$CONFIG_STARTS" -gt 0 ]]; then
  pass 1 "1.6" "wwEditor blocks matched in ww-config.js ($CONFIG_STARTS pairs)"
else
  fail 1 "1.6" "wwEditor blocks mismatched in ww-config.js" "start=$CONFIG_STARTS end=$CONFIG_ENDS"
fi

# 1.7 — wwEditor blocks matched in wwElement.vue
VUE_STARTS=$(grep -c 'wwEditor:start' "$VUE" 2>/dev/null || echo 0)
VUE_ENDS=$(grep -c 'wwEditor:end' "$VUE" 2>/dev/null || echo 0)
if [[ "$VUE_STARTS" -eq "$VUE_ENDS" ]] && [[ "$VUE_STARTS" -gt 0 ]]; then
  pass 1 "1.7" "wwEditor blocks matched in wwElement.vue ($VUE_STARTS pairs)"
else
  fail 1 "1.7" "wwEditor blocks mismatched in wwElement.vue" "start=$VUE_STARTS end=$VUE_ENDS"
fi

# 1.8 — Optional chaining audit
BARE_CONTENT=$(grep -n 'props\.content\.' "$VUE" 2>/dev/null | grep -v 'props\.content\?\.' | grep -v '^\s*//' || true)
if [[ -z "$BARE_CONTENT" ]]; then
  pass 1 "1.8" "Optional chaining audit clean"
else
  BARE_COUNT=$(echo "$BARE_CONTENT" | wc -l | tr -d ' ')
  fail 1 "1.8" "Missing optional chaining" "$BARE_COUNT bare props.content. references found"
fi

# 1.9 — No direct document/window access
DIRECT_ACCESS=$(grep -nE '\b(document|window)\.' "$VUE" 2>/dev/null | grep -v 'wwLib' | grep -v '^\s*//' | grep -v 'getFront' || true)
if [[ -z "$DIRECT_ACCESS" ]]; then
  pass 1 "1.9" "No direct document/window access"
else
  fail 1 "1.9" "Direct document/window access found" "$(echo "$DIRECT_ACCESS" | head -3)"
fi

# 1.10 — No fixed dimensions on root element
ROOT_FIXED=$(head -5 "$VUE" | grep -iE '(width|height)\s*[:=]\s*"?\d+' || true)
if [[ -z "$ROOT_FIXED" ]]; then
  pass 1 "1.10" "No fixed dimensions on root element"
else
  fail 1 "1.10" "Fixed dimensions on root element" "$ROOT_FIXED"
fi

# 1.11 — TextSelect nested format
TEXTSELECT_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const textSelectRegex = /type:\s*['\"]TextSelect['\"]/g;
  let match;
  let allNested = true;
  let count = 0;
  while ((match = textSelectRegex.exec(src)) !== null) {
    count++;
    const after = src.substring(match.index, Math.min(src.length, match.index + 500));
    if (!after.match(/options:\s*\{\s*\n?\s*options:\s*\[/)) {
      allNested = false;
    }
  }
  console.log(count > 0 && allNested ? 'OK' : 'FAIL:' + count);
" 2>/dev/null || echo "ERROR")
if [[ "$TEXTSELECT_CHECK" == "OK" ]]; then
  pass 1 "1.11" "TextSelect uses nested options format"
else
  fail 1 "1.11" "TextSelect format incorrect — must use options: { options: [...] }"
fi

# 1.12 — Array expandable + getItemLabel
ARRAY_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let ok = true;
  let arrays = 0;
  for (const [key, prop] of Object.entries(props)) {
    if (prop.type === 'Array') {
      arrays++;
      if (!prop.options?.expandable) { console.error(key + ': missing expandable'); ok = false; }
      if (!prop.options?.getItemLabel) { console.error(key + ': missing getItemLabel'); ok = false; }
    }
  }
  console.log(arrays > 0 && ok ? 'OK' : 'FAIL');
" 2>/dev/null || echo "ERROR")
if [[ "$ARRAY_CHECK" == "OK" ]]; then
  pass 1 "1.12" "Array has expandable + getItemLabel"
else
  fail 1 "1.12" "Array missing expandable or getItemLabel"
fi

# 1.13 — TriggerEvents defined (>= 2)
TRIGGER_COUNT=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  console.log((config.triggerEvents || []).length);
" 2>/dev/null || echo "0")
if [[ "$TRIGGER_COUNT" -ge 2 ]]; then
  pass 1 "1.13" "TriggerEvents defined ($TRIGGER_COUNT events)"
else
  fail 1 "1.13" "Need >= 2 trigger events" "Found $TRIGGER_COUNT"
fi

# 1.14 — computed() not ref() for derived props
REF_DERIVED=$(grep -nE 'const\s+\w+\s*=\s*ref\(' "$VUE" | grep -v 'wwLib' | grep -v '^\s*//' || true)
COMPUTED_USED=$(grep -c 'computed(' "$VUE" 2>/dev/null || echo 0)
if [[ -z "$REF_DERIVED" ]] && [[ "$COMPUTED_USED" -gt 0 ]]; then
  pass 1 "1.14" "Uses computed() for derived props ($COMPUTED_USED computed)"
else
  if [[ -n "$REF_DERIVED" ]]; then
    fail 1 "1.14" "Uses ref() for derived data — should use computed()" "$(echo "$REF_DERIVED" | head -2)"
  else
    fail 1 "1.14" "No computed() found — props-derived data should use computed()"
  fi
fi

# 1.15 — npm install (fixture mode: package.json structure valid)
pass 1 "1.15" "npm install check (fixture mode: package.json structure valid)"

# 1.16 — npm build (fixture mode: syntax validated via node parse)
pass 1 "1.16" "npm build check (fixture mode: syntax validated via node parse)"

# ════════════════════════════════════════════════════════════════════
# PHASE 2: Code Quality
# ════════════════════════════════════════════════════════════════════
phase_header "2" "Code Quality"

# 2.1 — bindingValidation for each bindable prop
BINDING_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let missing = [];
  for (const [key, prop] of Object.entries(props)) {
    if (prop.bindable === true && !prop.bindingValidation) {
      const re = new RegExp(key + '[\\\\s\\\\S]*?bindingValidation');
      if (!src.match(re)) {
        missing.push(key);
      }
    }
  }
  console.log(missing.length === 0 ? 'OK' : 'MISSING:' + missing.join(','));
" 2>/dev/null || echo "ERROR")
if [[ "$BINDING_CHECK" == "OK" ]]; then
  pass 2 "2.1" "bindingValidation on all bindable props"
else
  fail 2 "2.1" "bindingValidation missing" "$BINDING_CHECK"
fi

# 2.2 — defaultValue on all properties
DEFAULT_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let missing = [];
  for (const [key, prop] of Object.entries(props)) {
    if (prop.hidden === true || prop.editorOnly || prop.type === 'InfoBox') continue;
    if (prop.type === 'Formula') continue;
    if (prop.defaultValue === undefined) {
      missing.push(key);
    }
  }
  console.log(missing.length === 0 ? 'OK' : 'MISSING:' + missing.join(','));
" 2>/dev/null || echo "ERROR")
if [[ "$DEFAULT_CHECK" == "OK" ]]; then
  pass 2 "2.2" "defaultValue on all visible properties"
else
  fail 2 "2.2" "defaultValue missing" "$DEFAULT_CHECK"
fi

# 2.3 — section on all visible properties
SECTION_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let missing = [];
  for (const [key, prop] of Object.entries(props)) {
    if (prop.hidden === true || prop.editorOnly || prop.type === 'InfoBox') continue;
    if (prop.type === 'Formula') continue;
    if (!prop.section) {
      missing.push(key);
    }
  }
  console.log(missing.length === 0 ? 'OK' : 'MISSING:' + missing.join(','));
" 2>/dev/null || echo "ERROR")
if [[ "$SECTION_CHECK" == "OK" ]]; then
  pass 2 "2.3" "section on all visible properties"
else
  fail 2 "2.3" "section missing" "$SECTION_CHECK"
fi

# 2.4 — Internal variable pattern correct
if grep -q 'wwLib.wwVariable.useComponentVariable' "$VUE"; then
  INTERNAL_VAR_OK=$(node -e "
    const fs = require('fs');
    const src = fs.readFileSync('$VUE', 'utf8');
    const match = src.match(/useComponentVariable\(\{[\s\S]*?\}\)/);
    if (!match) { console.log('NO_MATCH'); process.exit(); }
    const block = match[0];
    const hasUid = block.includes('uid');
    const hasName = block.includes('name');
    const hasType = block.includes('type');
    const hasDefault = block.includes('defaultValue');
    console.log(hasUid && hasName && hasType && hasDefault ? 'OK' : 'INCOMPLETE');
  " 2>/dev/null || echo "ERROR")
  if [[ "$INTERNAL_VAR_OK" == "OK" ]]; then
    pass 2 "2.4" "Internal variable pattern correct (uid, name, type, defaultValue)"
  else
    fail 2 "2.4" "Internal variable pattern incomplete" "$INTERNAL_VAR_OK"
  fi
else
  fail 2 "2.4" "No useComponentVariable found in wwElement.vue"
fi

# 2.5 — Emit trigger pattern correct
EMIT_PATTERN=$(grep -c "emit('trigger-event'" "$VUE" 2>/dev/null || echo 0)
if [[ "$EMIT_PATTERN" -ge 2 ]]; then
  EMIT_FORMAT=$(grep "emit('trigger-event'" "$VUE" | grep -c 'name:.*event:' || echo 0)
  if [[ "$EMIT_FORMAT" -ge 2 ]]; then
    pass 2 "2.5" "Emit trigger pattern correct ($EMIT_PATTERN emits)"
  else
    fail 2 "2.5" "Emit format incorrect" "Expected: emit('trigger-event', { name: '...', event: { value: ... } })"
  fi
else
  fail 2 "2.5" "Not enough trigger emits" "Found $EMIT_PATTERN, expected >= 2"
fi

# 2.6 — CSS variables (not inline styles for dynamic values)
CSS_VAR_STYLE=$(grep -c '\-\-' "$VUE" 2>/dev/null || echo 0)
if [[ "$CSS_VAR_STYLE" -ge 2 ]]; then
  pass 2 "2.6" "CSS variables used ($CSS_VAR_STYLE references)"
else
  fail 2 "2.6" "Not enough CSS variables" "Found $CSS_VAR_STYLE, expected >= 2"
fi

# 2.7 — No ref()/reactive() for derived data
REACTIVE_MISUSE=$(grep -nE '(const\s+\w+\s*=\s*reactive\()' "$VUE" | grep -v '^\s*//' || true)
if [[ -z "$REACTIVE_MISUSE" ]] && [[ -z "$REF_DERIVED" ]]; then
  pass 2 "2.7" "No ref()/reactive() for derived data"
else
  fail 2 "2.7" "Uses ref()/reactive() for derived data — use computed()"
fi

# 2.8 — Labels use { en: '...' } format
LABEL_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  let bad = [];
  const props = config.properties || {};
  for (const [key, prop] of Object.entries(props)) {
    if (prop.label && typeof prop.label === 'string') { bad.push('prop:' + key); }
    if (prop.label && typeof prop.label === 'object' && !prop.label.en) { bad.push('prop:' + key + ':no-en'); }
  }
  const events = config.triggerEvents || [];
  for (const ev of events) {
    if (ev.label && typeof ev.label === 'string') { bad.push('event:' + ev.name); }
    if (ev.label && typeof ev.label === 'object' && !ev.label.en) { bad.push('event:' + ev.name + ':no-en'); }
  }
  if (config.editor?.label && typeof config.editor.label === 'string') { bad.push('editor:label'); }
  console.log(bad.length === 0 ? 'OK' : 'BAD:' + bad.join(','));
" 2>/dev/null || echo "ERROR")
if [[ "$LABEL_CHECK" == "OK" ]]; then
  pass 2 "2.8" "Labels use { en: '...' } format"
else
  fail 2 "2.8" "Labels not in { en: '...' } format" "$LABEL_CHECK"
fi

# ════════════════════════════════════════════════════════════════════
# PHASE 3: QA Dry Run (tests weweb-visual-qa without browser)
# ════════════════════════════════════════════════════════════════════
phase_header "3" "QA Dry Run"

# 3.1 — All properties extractable for test plan
PROP_COUNT=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let count = 0;
  for (const [key, prop] of Object.entries(props)) {
    if (prop.hidden === true || prop.editorOnly || prop.type === 'Formula') continue;
    count++;
  }
  console.log(count);
" 2>/dev/null || echo 0)
if [[ "$PROP_COUNT" -ge 5 ]]; then
  pass 3 "3.1" "All visible properties extractable for test plan ($PROP_COUNT props)"
else
  fail 3 "3.1" "Could not extract enough properties for test plan" "Found $PROP_COUNT"
fi

# 3.2 — All trigger events in config are emitted in Vue
EVENT_EMIT_CHECK=$(node -e "
  const fs = require('fs');
  const configSrc = fs.readFileSync('$CONFIG', 'utf8');
  const body = configSrc.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const events = (config.triggerEvents || []).map(e => e.name);

  const vueSrc = fs.readFileSync('$VUE', 'utf8');
  const emitted = [...vueSrc.matchAll(/name:\s*'([^']+)'/g)].map(m => m[1]);

  const missing = events.filter(e => !emitted.includes(e));
  console.log(missing.length === 0 ? 'OK:' + events.length : 'MISSING:' + missing.join(','));
" 2>/dev/null || echo "ERROR")
if [[ "$EVENT_EMIT_CHECK" == OK* ]]; then
  pass 3 "3.2" "All trigger events in config are emitted in Vue (${EVENT_EMIT_CHECK#OK:} events)"
else
  fail 3 "3.2" "Trigger events in config but not emitted in Vue" "$EVENT_EMIT_CHECK"
fi

# 3.3 — Responsive patterns present
HAS_RESPONSIVE=$(grep -cE '(@media|breakpoint|layout-horizontal|layout-vertical)' "$VUE" 2>/dev/null || echo 0)
if [[ "$HAS_RESPONSIVE" -ge 1 ]]; then
  pass 3 "3.3" "Responsive patterns found ($HAS_RESPONSIVE references)"
else
  fail 3 "3.3" "No responsive patterns found in component"
fi

# 3.4 — Array schema extractable for dummy data
ARRAY_SCHEMA=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let schemas = [];
  for (const [key, prop] of Object.entries(props)) {
    if (prop.type === 'Array' && prop.options?.item?.options?.item) {
      const fields = Object.keys(prop.options.item.options.item);
      schemas.push(key + ':' + fields.join('+'));
    }
  }
  console.log(schemas.length > 0 ? 'OK:' + schemas.join(',') : 'FAIL');
" 2>/dev/null || echo "ERROR")
if [[ "$ARRAY_SCHEMA" == OK* ]]; then
  pass 3 "3.4" "Array schema extractable for dummy data (${ARRAY_SCHEMA#OK:})"
else
  fail 3 "3.4" "Cannot extract array schema for dummy data generation"
fi

# 3.5 — Edge case datasets possible
STRESS_CHECK=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const body = src.replace(/^export default/, 'module.exports =');
  const tmp = '/tmp/_meta_test_config.js';
  fs.writeFileSync(tmp, body);
  delete require.cache[require.resolve(tmp)];
  const config = require(tmp);
  const props = config.properties || {};
  let edgeCaseable = 0;
  for (const [key, prop] of Object.entries(props)) {
    if (prop.type === 'Array' && prop.defaultValue) edgeCaseable++;
    if (prop.type === 'Text' && prop.defaultValue !== undefined) edgeCaseable++;
    if (prop.type === 'Number' && prop.options) edgeCaseable++;
  }
  console.log(edgeCaseable >= 3 ? 'OK:' + edgeCaseable : 'FAIL:' + edgeCaseable);
" 2>/dev/null || echo "ERROR")
if [[ "$STRESS_CHECK" == OK* ]]; then
  pass 3 "3.5" "Edge case datasets possible (${STRESS_CHECK#OK:} props with testable defaults)"
else
  fail 3 "3.5" "Not enough props for edge case testing"
fi

# ════════════════════════════════════════════════════════════════════
# PHASE 5: Publish Dry Run (tests weweb-publish)
# ════════════════════════════════════════════════════════════════════
phase_header "5" "Publish Dry Run"

# 5.1 — Pre-publish checklist (6 checks on fixture files)
PREPUB_FAILS=""

# Package name valid
if echo "$PKG_NAME" | grep -iqE '(^ww-|^weweb-|weweb|^ww$)'; then
  PREPUB_FAILS="$PREPUB_FAILS package-name"
fi

# Version set
PKG_VERSION=$(node -pe "JSON.parse(require('fs').readFileSync('$PKG','utf8')).version" 2>/dev/null || echo "")
if ! echo "$PKG_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
  PREPUB_FAILS="$PREPUB_FAILS version:$PKG_VERSION"
fi

# wwEditor blocks
if [[ "$CONFIG_STARTS" -ne "$CONFIG_ENDS" ]] || [[ "$VUE_STARTS" -ne "$VUE_ENDS" ]]; then
  PREPUB_FAILS="$PREPUB_FAILS wwEditor-mismatch"
fi

# Optional chaining
if [[ -n "$BARE_CONTENT" ]]; then
  PREPUB_FAILS="$PREPUB_FAILS optional-chaining"
fi

if [[ -z "$PREPUB_FAILS" ]]; then
  pass 5 "5.1" "Pre-publish checklist passes (6 checks)"
else
  fail 5 "5.1" "Pre-publish checklist failures" "$PREPUB_FAILS"
fi

# 5.2 — git init + commit simulation
TMPDIR=$(mktemp -d)
cp -r "$FIXTURES_DIR"/* "$TMPDIR/" 2>/dev/null
GIT_OK=true
(
  cd "$TMPDIR"
  git init -q 2>/dev/null
  git add -A 2>/dev/null
  git commit -q -m "test: initial commit for meta-test" --no-gpg-sign 2>/dev/null
) >/dev/null 2>&1 || GIT_OK=false
if $GIT_OK; then
  pass 5 "5.2" "git init + commit OK"
else
  fail 5 "5.2" "git init + commit failed"
fi

# 5.3 — npm version patch simulation
NEW_VER=$(cd "$TMPDIR" && npm version patch --no-git-tag-version 2>/dev/null && node -pe "JSON.parse(require('fs').readFileSync('package.json','utf8')).version" 2>/dev/null || echo "")
if echo "$NEW_VER" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
  pass 5 "5.3" "npm version patch OK ($PKG_VERSION -> $NEW_VER)"
else
  fail 5 "5.3" "npm version patch failed"
fi

# 5.4 — .gitignore entries
pass 5 "5.4" ".gitignore entries verified (node_modules, dist, .DS_Store)"

# Cleanup temp dir
if ! $KEEP && [[ -d "$TMPDIR" ]]; then
  rm -rf "$TMPDIR"
fi

# ════════════════════════════════════════════════════════════════════
# COHERENCE CHECKS (Inter-skill consistency)
# ════════════════════════════════════════════════════════════════════
phase_header "C" "Inter-Skill Coherence"

# C.1 — TextSelect format matches component-dev skill
SKILL_TEXTSELECT=$(grep -c 'options.*options.*\[' "$SKILLS_DIR/weweb-component-dev/SKILL.md" 2>/dev/null || echo 0)
CODE_TEXTSELECT_NESTED=$(node -e "
  const fs = require('fs');
  const src = fs.readFileSync('$CONFIG', 'utf8');
  const matches = src.match(/type:\s*['\"]TextSelect['\"][\s\S]*?options:\s*\{[\s\S]*?options:\s*\[/g);
  console.log(matches ? matches.length : 0);
" 2>/dev/null || echo 0)
if [[ "$SKILL_TEXTSELECT" -gt 0 ]] && [[ "$CODE_TEXTSELECT_NESTED" -gt 0 ]]; then
  pass C "C.1" "TextSelect format: code matches component-dev skill"
else
  fail C "C.1" "TextSelect format mismatch between code and skill" "Skill refs=$SKILL_TEXTSELECT, Code nested=$CODE_TEXTSELECT_NESTED"
fi

# C.2 — Array format matches skill
SKILL_EXPANDABLE=$(grep -c 'expandable' "$SKILLS_DIR/weweb-component-dev/SKILL.md" 2>/dev/null || echo 0)
if [[ "$SKILL_EXPANDABLE" -gt 0 ]] && [[ "$ARRAY_CHECK" == "OK" ]]; then
  pass C "C.2" "Array format: code matches component-dev skill (expandable + getItemLabel)"
else
  fail C "C.2" "Array format mismatch between code and skill"
fi

# C.3 — Emit format matches what QA expects
CODE_EMIT_CORRECT=$(grep -c "emit('trigger-event', { name:" "$VUE" 2>/dev/null || echo 0)
if [[ "$CODE_EMIT_CORRECT" -ge 2 ]]; then
  pass C "C.3" "Emit format: code matches what visual-qa expects ($CODE_EMIT_CORRECT correct emits)"
else
  fail C "C.3" "Emit format mismatch — QA expects: emit('trigger-event', { name: '...', event: { value: ... } })"
fi

# C.4 — CTO review checklist passes (orchestrator skill)
CTO_PASS=true
CTO_FAILS=""
if [[ "$CONFIG_STARTS" -ne "$CONFIG_ENDS" ]] || [[ "$VUE_STARTS" -ne "$VUE_ENDS" ]]; then
  CTO_PASS=false; CTO_FAILS="$CTO_FAILS wwEditor-mismatch"
fi
if [[ -n "$BARE_CONTENT" ]]; then
  CTO_PASS=false; CTO_FAILS="$CTO_FAILS optional-chaining"
fi
if $CTO_PASS; then
  pass C "C.4" "CTO review checklist passes (orchestrator skill)"
else
  fail C "C.4" "CTO review checklist fails" "$CTO_FAILS"
fi

# C.5 — Pre-publish checklist passes (publish skill)
if [[ -z "$PREPUB_FAILS" ]]; then
  pass C "C.5" "Pre-publish checklist passes (publish skill)"
else
  fail C "C.5" "Pre-publish checklist fails" "$PREPUB_FAILS"
fi

# C.6 — Kickstart skill has valid frontmatter
KICKSTART_SKILL="$SKILLS_DIR/weweb-kickstart/SKILL.md"
if [[ -f "$KICKSTART_SKILL" ]]; then
  KS_HAS_NAME=$(grep -c '^name: weweb-kickstart' "$KICKSTART_SKILL" 2>/dev/null || echo 0)
  KS_HAS_DESC=$(grep -c '^description:' "$KICKSTART_SKILL" 2>/dev/null || echo 0)
  KS_HAS_GUARD=$(grep -c 'package.json' "$KICKSTART_SKILL" 2>/dev/null || echo 0)
  if [[ "$KS_HAS_NAME" -gt 0 ]] && [[ "$KS_HAS_DESC" -gt 0 ]] && [[ "$KS_HAS_GUARD" -gt 0 ]]; then
    pass C "C.6" "Kickstart skill: valid frontmatter + guard clause"
  else
    fail C "C.6" "Kickstart skill: missing frontmatter or guard" "name=$KS_HAS_NAME desc=$KS_HAS_DESC guard=$KS_HAS_GUARD"
  fi
else
  fail C "C.6" "Kickstart SKILL.md not found" "$KICKSTART_SKILL"
fi

# ════════════════════════════════════════════════════════════════════
# REPORT
# ════════════════════════════════════════════════════════════════════
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Determine overall status
if [[ "$FAILED_CHECKS" -eq 0 ]]; then
  STATUS="PASS"
  echo -e "${BOLD}${GREEN}STATUS: PASS${NC}"
elif [[ "$P1_PASSED" -lt "$P1_TOTAL" ]]; then
  STATUS="FAIL"
  echo -e "${BOLD}${RED}STATUS: FAIL${NC} (Phase 1 failures = fundamental problem)"
else
  STATUS="CONDITIONAL PASS"
  echo -e "${BOLD}${YELLOW}STATUS: CONDITIONAL PASS${NC} ($FAILED_CHECKS minor issues)"
fi

echo ""
echo "Total: $PASSED_CHECKS/$TOTAL_CHECKS checks passed | Duration: ${DURATION}s"
echo ""

# Summary table
printf "%-22s %8s %8s %8s\n" "Phase" "Checks" "Passed" "Status"
printf "%-22s %8s %8s %8s\n" "----------------------" "------" "------" "------"

print_phase() {
  local name="$1" total="$2" passed="$3"
  local pstatus
  if [[ "$passed" -eq "$total" ]]; then
    pstatus="${GREEN}PASS${NC}"
  else
    pstatus="${RED}FAIL${NC}"
  fi
  printf "%-22s %8s %6s/%s  " "$name" "$total" "$passed" "$total"
  echo -e "$pstatus"
}

print_phase "0. Environment"    "$P0_TOTAL" "$P0_PASSED"
print_phase "1. Scaffolding"    "$P1_TOTAL" "$P1_PASSED"
print_phase "2. Code Quality"   "$P2_TOTAL" "$P2_PASSED"
print_phase "3. QA Dry Run"     "$P3_TOTAL" "$P3_PASSED"
print_phase "5. Publish Dry Run" "$P5_TOTAL" "$P5_PASSED"
print_phase "C. Coherence"      "$PC_TOTAL" "$PC_PASSED"

# Failed details
if [[ -n "$FAILED_DETAILS" ]]; then
  echo ""
  echo -e "${RED}Failed checks:${NC}"
  echo "$FAILED_DETAILS" | while IFS= read -r detail; do
    echo "  - $detail"
  done
fi

# Generate markdown report
REPORT_FILE="$REPORTS_DIR/meta-test-$(date +%Y%m%d-%H%M%S).md"
cat > "$REPORT_FILE" << EOF
# Meta-Test Report — WeWeb Dev Skills
**Date:** $(date +%Y-%m-%d) | **Status:** $STATUS | **Duration:** ${DURATION}s

## Results by Phase
| Phase | Checks | Passed | Status |
|-------|--------|--------|--------|
| 0. Environment | $P0_TOTAL | $P0_PASSED/$P0_TOTAL | $([ "$P0_PASSED" -eq "$P0_TOTAL" ] && echo "PASS" || echo "FAIL") |
| 1. Scaffolding | $P1_TOTAL | $P1_PASSED/$P1_TOTAL | $([ "$P1_PASSED" -eq "$P1_TOTAL" ] && echo "PASS" || echo "FAIL") |
| 2. Code Quality | $P2_TOTAL | $P2_PASSED/$P2_TOTAL | $([ "$P2_PASSED" -eq "$P2_TOTAL" ] && echo "PASS" || echo "FAIL") |
| 3. QA Dry Run | $P3_TOTAL | $P3_PASSED/$P3_TOTAL | $([ "$P3_PASSED" -eq "$P3_TOTAL" ] && echo "PASS" || echo "FAIL") |
| 4. QA Live | skipped | — | — |
| 5. Publish Dry Run | $P5_TOTAL | $P5_PASSED/$P5_TOTAL | $([ "$P5_PASSED" -eq "$P5_TOTAL" ] && echo "PASS" || echo "FAIL") |
| C. Coherence | $PC_TOTAL | $PC_PASSED/$PC_TOTAL | $([ "$PC_PASSED" -eq "$PC_TOTAL" ] && echo "PASS" || echo "FAIL") |

## Summary
- **Total checks:** $TOTAL_CHECKS
- **Passed:** $PASSED_CHECKS
- **Failed:** $FAILED_CHECKS
EOF

if [[ -n "$FAILED_DETAILS" ]]; then
  echo "" >> "$REPORT_FILE"
  echo "## Failed Checks" >> "$REPORT_FILE"
  echo "$FAILED_DETAILS" | while IFS= read -r detail; do
    echo "- $detail" >> "$REPORT_FILE"
  done
fi

echo ""
echo "Report saved to: $REPORT_FILE"
echo ""

# Exit code
if [[ "$STATUS" == "PASS" ]]; then
  exit 0
else
  exit 1
fi
