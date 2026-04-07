## Doc versioning and deprecation

This doc defines how to handle changes to conventions, deprecated patterns, and breaking updates to the docs themselves.

---

### The core principle

These docs are **living source of truth**, not a changelog. The goal is always to reflect the current correct state — not to preserve history.

History lives in git. The docs live in the present.

---

### When a convention changes

#### Minor change (same intent, clearer wording)

Just update the doc in place. No special marking needed.

Example: rephrasing a rule, adding an example, fixing a path.

#### Breaking change (old code still exists, new pattern replaces it)

1. Update the doc to reflect the new pattern
2. Add a `> **Migration note**` block in the same doc explaining what changed and why

```md
> **Migration note (2024-06-01):** Button modifiers now use BEM (`button--black`)
> instead of Tailwind modifier classes. Existing components using the old pattern
> should be updated when they are next touched.
```

3. Add an entry to `learnings.md` with the date, context, and what was changed

#### New pattern replaces an old one entirely

1. Remove the old pattern from the doc — do not keep both
2. If old code using the previous pattern still exists in the repo, add a comment block at the top of that doc section:

```md
> **Deprecated pattern still exists in:** `src/pages/` (legacy Pages Router files).
> Do not replicate. Migrate when touching those files.
```

---

### When a doc becomes wrong (diverged from codebase)

If you notice a doc describes something that no longer matches reality:

1. Fix the doc immediately — do not wait
2. Add an entry to `learnings.md`:
   - What was wrong
   - What the correct state is
   - Why the drift happened (if known)

---

### The `learnings.md` role in versioning

`learnings.md` is the lightweight audit trail. It answers "what changed and when" without polluting the main docs with history.

When you make a breaking change to any doc:
- The doc reflects the new state
- `learnings.md` captures the transition

---

### What AI should do when encountering old patterns in the codebase

If you find code in `src/` that does not match the current docs:

1. **Do not replicate the old pattern** — follow the docs, not the old code
2. **Do not refactor unprompted** — only migrate if the current task touches that file
3. **Add a note to `learnings.md`** if the pattern is widespread and needs a migration plan

---

### Doc ownership summary

| Doc | Who updates it | Trigger |
|---|---|---|
| `project-structure.md` | AI or developer | New folder or route added |
| `project-rules.md` | AI or developer | New naming, file, or styling convention |
| `ai-workflow.md` | AI or developer | Workflow step changes |
| `accessibility.md` | Developer (preferred) | New baseline requirement |
| `learnings.md` | AI (required) | After every task that produces a learning |
| `doc-versioning.md` | Developer | When versioning approach itself changes |
