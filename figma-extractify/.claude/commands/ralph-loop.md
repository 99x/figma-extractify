# Ralph Loop — autonomous iteration until completion

Wraps any task in an enforced iteration loop. Claude cannot exit until the **completion promise** is output or **max iterations** is reached.

Uses a stop hook (`.claude/hooks/ralph-stop.sh`) that intercepts exit attempts, re-injects the prompt, and forces Claude to keep working.

---

## How to use

```
/ralph-loop <your task prompt> --completion-promise "<EXACT_STRING>" --max-iterations <N>
```

### Examples

```
# Build a component with enforced visual review
/ralph-loop "/extractify-new-component hero-banner" --completion-promise "VISUAL_REVIEW_PASS" --max-iterations 8

# Run audit until everything passes
/ralph-loop "/extractify-audit" --completion-promise "ALL_COMPONENTS_PASS" --max-iterations 5

# Any arbitrary task
/ralph-loop "Build a hello world API" --completion-promise "DONE" --max-iterations 10
```

---

## How it works

1. Claude works on the task
2. Claude tries to exit (finishes responding)
3. The stop hook blocks the exit (exit code 2)
4. The original prompt is re-injected with the iteration count
5. Claude sees all previous file changes and continues
6. Repeat until the completion promise appears in output or max iterations is hit

---

## Parsing arguments

Parse `$ARGUMENTS` to extract three parts:

1. **prompt** — everything before the first `--` flag
2. **--completion-promise** — the exact string Claude must output to exit (default: `"DONE"`)
3. **--max-iterations** — safety cap (default: `5`)

---

## Phase 1 — Initialize the loop

1. Parse `$ARGUMENTS` into prompt, completion-promise, and max-iterations
2. Create the state file `.ralph-loop-state.json` in the project root:

```json
{
  "active": true,
  "prompt": "<the parsed prompt>",
  "completion_promise": "<the parsed promise>",
  "max_iterations": <N>,
  "current_iteration": 1,
  "started_at": "<ISO timestamp>"
}
```

3. Confirm to the user:

```
Ralph Loop initialized
────────────────────────────
  Task:       <prompt summary>
  Promise:    <completion_promise>
  Max iter:   <N>
  Status:     Running (iteration 1/<N>)
────────────────────────────
The stop hook will prevent exit until "<completion_promise>" is output or <N> iterations complete.
```

---

## Phase 2 — Execute the task

Run the parsed prompt as if the user typed it directly.

If the prompt starts with `/` (e.g., `/extractify-new-component hero`), execute it as a slash command.
Otherwise, treat it as a regular task instruction.

**Important**: The stop hook handles iteration. You do NOT need to implement looping logic yourself. Just do the work. When you try to finish, the hook will either let you exit (promise detected or max reached) or re-inject the prompt for another pass.

---

## Phase 3 — Completion

When the task is truly done and all criteria are met, output the completion promise as a standalone line:

```
VISUAL_REVIEW_PASS
```

The stop hook will detect it and allow exit.

If max iterations are reached without the promise, the hook allows exit and logs a warning. In that case, note what remains unfinished.

---

## Cleanup

After the loop ends (either by promise or max iterations):

1. The state file stays in the project root for reference
2. To manually deactivate: delete `.ralph-loop-state.json` or set `"active": false`
3. The state file is gitignored (add it to `.gitignore` if not already there)

---

## Default completion promises for figma-extractify commands

When wrapping a `/extract-*` command, use these standard promises:

| Command | Recommended promise | What it means |
|---|---|---|
| `/extractify-new-component` | `VISUAL_REVIEW_PASS` | Pixelmatch ≥ 95%, 0 critical a11y violations, all breakpoints tested |
| `/extractify-audit` | `ALL_COMPONENTS_PASS` | Every component passes compliance + a11y |
| `/extractify-setup` | `SETUP_COMPLETE` | All requested token steps extracted and applied |
| `/extractify-code-connect` | `CODE_CONNECT_MAPPED` | Component mapped to Figma node |

The arguments are: $ARGUMENTS
