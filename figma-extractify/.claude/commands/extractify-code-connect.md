# Connect component code to Figma (Code Connect)

Maps a built component to its Figma design node so designers see real code in Dev Mode.

## Prerequisites

- Component must exist in `src/components/<Name>/index.tsx`
- Component must have passed compliance + visual review
- Figma URL or node ID must exist in `_docs/figma-paths.yaml`
- Figma Desktop MCP must be connected (Figma Desktop open in Dev Mode)

---

## Phase 1 — Resolve component (orchestrator)

**If `$ARGUMENTS` is `--push`:**
  - Skip to Phase 3 (push all mappings to Figma)

**If `$ARGUMENTS` is a component name:**
  1. Normalize the name: extract PascalCase for folder, kebab-case for lookup
  2. Verify `src/components/<PascalCase>/index.tsx` exists
  3. Look up the Figma URL in `_docs/figma-paths.yaml` under `components.<kebab-case>`
  4. If not found → ask the user for the Figma URL or node ID

**If `$ARGUMENTS` is empty:**
  - Call `get_code_connect_suggestions` to get Figma's suggestions for unmapped components
  - Cross-reference with existing components in `src/components/`
  - Show the user which components can be connected and ask which one to connect

---

## Phase 2 — Create mapping

1. Read the component file (`src/components/<PascalCase>/index.tsx`)
2. Extract the `Props` interface:
   - List all prop names, types, and default values
   - Note which props are required vs optional
3. Extract the Figma file key and node ID from the URL
4. Call `get_code_connect_map` with the node ID to check if a mapping already exists
   - If mapping exists → ask user if they want to update it
   - If user declines → stop
5. Call `add_code_connect_map` with:
   - `source`: the component file path (`src/components/<PascalCase>/index.tsx`)
   - `fileKey`: extracted from the Figma URL
   - `nodeId`: extracted from the Figma URL
   - `componentName`: PascalCase component name
   - `label`: 'React' (this project uses React)
6. Display success message with the mapped props

---

## Phase 3 — Push mappings (only with `--push` flag)

1. Call `get_code_connect_map` to list all current mappings in the file
2. Show the user a summary of what will be pushed (component names and node IDs)
3. Ask for confirmation: "Push [N] mappings to Figma?"
4. Call `send_code_connect_mappings` to push all mappings to Figma
5. Confirm success and explain that designers will see the updates in Dev Mode

---

## Output

Display a summary with:
- Component name
- Figma node linked
- Props interface (name, type, default value)
- Status: `connected` / `updated` / `pushed`
- Next step: "Designers can now see this component in Figma Dev Mode"

The component name is: `$ARGUMENTS`
