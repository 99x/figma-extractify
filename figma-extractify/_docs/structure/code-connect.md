# Code Connect integration

## What Code Connect is

Code Connect is a Figma feature that maps actual component code to Figma design components. When a designer inspects a component in Figma Dev Mode, they see the real React code and props interface instead of auto-generated CSS. This closes the design-to-code feedback loop.

Instead of guessing which component to use or copying styles manually, designers can:
- See the exact component file location
- View the `Props` interface with types and defaults
- Copy the import path directly into their templates or integration layer

---

## Available MCP tools

The project ships with both Figma MCP servers configured in `.mcp.json` — Desktop (preferred) and Remote (fallback). Both expose the Code Connect tools below; skills resolve whichever is available at run time.

| Tool | Purpose |
|---|---|
| `get_code_connect_map` | Retrieve existing code-to-Figma mappings for a node |
| `get_code_connect_suggestions` | Ask Figma which components could be connected (unmapped design components) |
| `add_code_connect_map` | Create a new mapping between a component file and a Figma node |
| `send_code_connect_mappings` | Push all mappings to Figma (bulk operation) |

---

## Mapping convention

Each component in `src/components/<Name>/index.tsx` maps to its Figma design node:

1. **Component location**: `src/components/<PascalCase>/index.tsx`
2. **Figma location**: Node ID stored in `_docs/figma-paths.yaml` under `components.<kebab-case>`
3. **Props match**: The mapping lists all props from the component's `Props` interface with their types and defaults
4. **When to map**: Only after the component has passed compliance + visual review (Ralph Loop)

**Example mapping**:
```
Component: src/components/Button/index.tsx
Figma node: 123:456
Props:
  - label: string (required)
  - variant: 'primary' | 'secondary' (default: 'primary')
  - disabled: boolean (default: false)
```

---

## Workflow

### New component workflow

1. **Build** → Create component via `/extractify-new-component`
2. **Review** → Pass compliance check + visual review (Ralph Loop)
3. **Map** → Run `/extractify-code-connect <component-name>`
   - The command reads the component's Props interface
   - Looks up the Figma node ID in `_docs/figma-paths.yaml`
   - Calls `add_code_connect_map` to create the mapping
4. **Verify** → Confirm the mapping appears in Figma Dev Mode

### Bulk push workflow (after multiple components mapped)

1. Run `/extractify-code-connect --push`
2. The command calls `send_code_connect_mappings` to push all mappings to Figma at once
3. Designers immediately see the updated components in Dev Mode

---

## Benefits for designers

- **Real prop names** — See the actual `Props` interface instead of guessing
- **Implementation status** — Know which components are already built
- **Copy-paste ready** — Get the exact import path: `src/components/Button/index.tsx`
- **Defaults visible** — See which props are optional and their default values
- **Feedback loop** — Run visual review, then map → designers see it in Figma Dev Mode instantly

---

## When NOT to use Code Connect

Do not create Code Connect mappings for:

| Type | Reason |
|---|---|
| Utility components | `RichText`, `RichTextWrapper` — these are layout helpers, not design components |
| Layout wrappers | Internal-only containers used inside other components |
| Components without Figma counterpart | If the component has no design node, there's nothing to map |
| Page templates | Only components in `src/components/` should be mapped, not full page routes |
| Deprecated components | Remove the mapping when a component is sunset |

---

## Code Connect in Dev Mode

Once mapped, designers can:

1. Open Figma file in browser
2. Click the component in canvas
3. Switch to **Dev Mode** (top right)
4. See the **Code** panel with the real React code:
   ```tsx
   import Button from 'src/components/Button'

   <Button label="Click me" variant="primary" />
   ```
5. Click **Copy code** to use directly in your integration layer or templates

---

## Troubleshooting

| Issue | Solution |
|---|---|
| Mapping not appearing in Dev Mode | Ensure `send_code_connect_mappings` was called (push step) |
| Props interface changed | Re-run `/extractify-code-connect <component-name>` to update the mapping |
| Figma node not found | Verify the node ID in `_docs/figma-paths.yaml` is correct |
| Multiple components mapping to same node | Each Figma node can only map to one component — split the design if needed |
