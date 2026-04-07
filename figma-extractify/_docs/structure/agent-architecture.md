## Agent architecture

This project uses a **subagent orchestration pattern** to solve two problems:

1. **Right model for each task** — expensive models only where quality matters
2. **No context rot** — each phase runs in a fresh subagent with clean context

---

## How it works

Every slash command (`/extractify-setup`, `/extractify-new-component`, `/extractify-discover`) runs as an **orchestrator** on Sonnet. The orchestrator handles user interaction (AskUserQuestion, confirmations, URL management) and spawns **subagents** for heavy-lifting phases.

Each subagent:
- Starts with a **fresh context window** (no accumulated noise from previous phases)
- Reads **only the docs it needs** (not the entire project)
- Runs on the **optimal model** for its task type
- Returns a structured result to the orchestrator

The orchestrator passes results between phases — e.g. the component name and file paths from the build phase flow into the compliance check and visual review.

---

## Model assignments

| Task type | Model | Why |
|---|---|---|
| Orchestration + user interaction | **Sonnet** | Fast, cheap, handles coordination well |
| Component / page building (code gen) | **Sonnet** | Excellent at following patterns and generating code from specs |
| Figma token extraction (setup steps) | **Sonnet** | Structured extraction following contract docs |
| Compliance checklist | **Haiku** | Pure mechanical verification — fastest and cheapest |
| Visual review loop | **Opus** | Best visual reasoning — comparing screenshots, judging spacing/alignment/color differences |

### When to override

- If a component is unusually complex (many interactive states, complex animations, deeply nested structure), consider using **Opus** for the build phase instead of Sonnet
- If visual review keeps passing on first iteration for simple components, consider downgrading to **Sonnet** to save cost

---

## Subagent patterns

### Pattern 1 — Build subagent (Sonnet)

Used for: component building, page building, setup step extraction.

The orchestrator passes:
- Component/page name
- Figma URL
- List of docs to read (specific to the task)
- Any resolved context (parent/child structure, design tokens from previous steps)

The subagent:
1. Reads only the listed docs
2. Calls Figma MCP to get design context
3. Generates code following all project rules
4. Returns: list of files created/modified

### Pattern 2 — Compliance subagent (Haiku)

Used for: mechanical verification against the component contract.

The orchestrator passes:
- File paths to check (component file + preview page)
- The compliance checklist

The subagent:
1. Reads the files
2. Runs through every checklist item
3. Fixes violations in-place
4. Returns: pass/fail per item + list of fixes applied

### Pattern 3 — Visual review subagent (Opus)

Used for: the Ralph Loop — iterative visual comparison and refinement.

The orchestrator passes:
- Component name + file path
- Figma URL
- Preview URL (localhost)
- PostCSS file path (if any)
- Whether mobile testing is needed

The subagent:
1. Reads `visual-review.md` and `consistency-rules.md`
2. Runs the screenshot → compare → fix loop (max 5 iterations)
3. Returns: iteration count, fixes applied, final status (pass / remaining issues)

### Pattern 4 — Setup extraction subagent (Sonnet)

Used for: each step of `/extractify-setup` (colors, typography, grid, icons, buttons, forms).

The orchestrator passes:
- Step name and number
- Figma URL for this step
- Contract doc path (e.g. `01-colors.md`)
- Current theme.pcss content (so the subagent knows what exists)

The subagent:
1. Reads the contract doc
2. Calls Figma MCP to extract tokens
3. Applies changes to the codebase
4. Returns: summary of tokens applied + files modified

### Pattern 5 — Discovery scanner subagent (Sonnet)

Used for: scanning individual Figma pages in `/extractify-discover`.

The orchestrator passes:
- File key, page name, and page node ID
- Instructions to extract ALL visual tokens (colors, typography, spacing, radius, shadows, buttons, containers)

The subagent:
1. Calls `get_design_context` and `get_variable_defs` on the page
2. Catalogs every unique token found
3. Returns: structured JSON with raw extracted values (no normalization)

### Pattern 6 — Discovery analyzer subagent (Sonnet)

Used for: merging and normalizing tokens from all scanned pages in `/extractify-discover`.

The orchestrator passes:
- Merged JSON array from all page scanner subagents
- Instructions to deduplicate, cluster, and name tokens

The subagent:
1. Clusters similar colors, deduplicates type styles
2. Identifies scales (spacing, radius, shadows)
3. Groups buttons into named variants
4. Returns: normalized design system JSON + decisions log + warnings

### Pattern 7 — DS page builder subagent (Sonnet)

Used for: generating the HTML design system reference page in `/extractify-discover`.

The orchestrator passes:
- The normalized design system JSON from the analyzer
- Layout and styling instructions for the HTML page

The subagent:
1. Generates a self-contained HTML page with all DS sections
2. Returns: complete HTML file

---

## Context rot prevention

### Within a single command run

Each phase is a fresh subagent → no context accumulation. The orchestrator stays lightweight because it only holds:
- The command instructions
- Component name, URLs, file paths
- Results from each subagent (summaries, not full code)

### Across multiple component builds

Each `/extractify-new-component` run should be a **separate conversation**. Do not build 5 components in one conversation — even with subagents, the orchestrator's context will grow.

**Recommended workflow:**
1. Run `/extractify-new-component hero-banner` → build → done
2. New conversation → `/extractify-new-component course-card` → build → done
3. New conversation → `/extractify-new-component footer` → build → done

This ensures every component starts with zero accumulated context.

---

## Role framing

Each subagent prompt begins with a **role frame** — a short paragraph that sets the agent's mindset, strictness level, and success criteria. This is not about pretending to be someone; it's about setting an **attention filter** that shifts how the agent weighs competing concerns.

### When role frames help

| Situation | Why it helps |
|---|---|
| Judgment-heavy steps (visual review, QA) | Sets the strictness bar — "find problems" vs "confirm it works" |
| Steps where the agent might cut corners | Combats the model's tendency to confirm its own work |
| Steps with ambiguous quality thresholds | Defines what "good enough" means concretely |

### When role frames don't help

| Situation | Why it's redundant |
|---|---|
| Purely procedural steps | Concrete instructions already do the work |
| Steps with exhaustive checklists | The checklist itself sets the standard |

### Anatomy of a good role frame

A role frame has three parts (2–4 sentences total):

1. **Identity + attention filter** — what to pay attention to (e.g. "senior UI engineer with a trained eye for spacing")
2. **Success criteria** — what the output will be judged on (e.g. "evaluated on how closely the implementation matches Figma")
3. **Bias correction** — which direction to err (e.g. "assume the code has problems until proven otherwise")

Separate the role frame from the task instructions with a `---` divider so the agent can distinguish mindset from procedure.

### Current role assignments

| Phase | Role | Key bias |
|---|---|---|
| Build (Sonnet) | Front-end developer, production-ready code | Conservative interpretation of ambiguity |
| Compliance (Haiku) | QA engineer, strict auditor | Assume violations exist |
| Visual review (Opus) | Senior UI engineer, pixel-level review | Never approve "close enough" |
| Setup extraction (Sonnet) | Design systems engineer, precision-first | Extract exactly what exists, never invent |
| Discovery scanner (Sonnet) | Design token archaeologist, exhaustive cataloger | Miss nothing — catalog every visual property |
| Discovery analyzer (Sonnet) | Design systems architect, pattern recognizer | Be opinionated about naming, explain decisions |
| DS page builder (Sonnet) | Documentation specialist, visual clarity | Professional reference quality, clean structure |

---

## Agent tool usage

All subagents are spawned via the **Agent tool** with these parameters:

```
Agent tool call:
  model: "sonnet" | "opus" | "haiku"
  description: short description of the task
  prompt: focused prompt with only the context this phase needs
```

The prompt for each subagent must include:
1. **What to build** — component name, Figma URL, specific requirements
2. **What to read** — exact doc file paths (not "read all docs")
3. **What to return** — expected output format (files created, pass/fail, iteration count)

Never include the full command file content in a subagent prompt. Only include what that specific phase needs.

---

## Ralph-loop integration (enforced iteration)

The project includes a **ralph-loop** stop hook (`.claude/hooks/ralph-stop.sh`) that prevents Claude from exiting until a completion promise is objectively met. This is registered in `.claude/settings.json` under `hooks.Stop`.

### How it works

1. A slash command (`/ralph-loop`) initializes a state file (`.ralph-loop-state.json`) with the task prompt, completion promise, and max iteration count
2. Claude works on the task normally
3. When Claude tries to exit, the stop hook intercepts the exit
4. If the completion promise string is found in the output → allow exit
5. If max iterations reached → allow exit with warning
6. Otherwise → block exit (exit code 2), re-inject the original prompt, increment the iteration counter

### When to use it

| Scenario | Use ralph-loop? | Why |
|---|---|---|
| `/extractify-new-component` with Figma URL | **Yes** | Enforces visual review thresholds — Claude can't bail on "close enough" |
| `/extractify-audit` across many components | **Yes** | Ensures every component is checked, not just a few |
| `/extractify-setup` (token extraction) | No | No visual review loop — single-pass extraction |
| `/extractify-discover` | No | Long-running scan — subagent pattern handles iteration internally |
| Quick prototyping | No | Overhead not worth it for exploratory work |

### Completion promise conventions

| Command | Promise string | Exit condition |
|---|---|---|
| `/extractify-new-component` | `VISUAL_REVIEW_PASS` | Pixelmatch ≥ 95%, 0 critical a11y violations, all breakpoints tested |
| `/extractify-audit` | `ALL_COMPONENTS_PASS` | Every component passes compliance + a11y |
| Generic task | `DONE` | Task-specific — defined by the user |

### Interaction with subagents

The stop hook operates at the **session level** (the orchestrator). It does not directly affect subagents spawned via the Agent tool — subagents have their own iteration limits (e.g., max 5 visual review iterations).

The ralph-loop wraps the **entire pipeline**: if the orchestrator tries to finish but the visual review subagent reported failures, the stop hook catches that the completion promise was never output and forces another pass.

This creates two layers of enforcement:
1. **Inner loop**: Opus subagent iterates on pixel diff / a11y within its 5-iteration cap
2. **Outer loop**: ralph-loop re-runs the full pipeline if the inner loop exhausted its cap without passing

### Safety

- Always set `--max-iterations` as a cap (recommended: 8 for components, 5 for audits)
- The state file (`.ralph-loop-state.json`) is gitignored
- To manually stop: delete `.ralph-loop-state.json` or set `"active": false` in it
