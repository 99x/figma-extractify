---
name: extractify-code-connect
description: "Use this skill whenever the user wants to link a built component back to its Figma source using Figma Code Connect, push component mappings to Figma, or make components show real React code in Figma Dev Mode. Triggers on: 'code connect', 'link component to Figma', 'connect to Figma', 'push to Figma', 'make code visible in Figma', 'Dev Mode', 'designers should see the code', '/extractify-code-connect', 'map components to Figma', 'push all mappings', or any request to surface real component code inside Figma for designers. Also trigger when the user says 'I want designers to see the props' or 'link the code to the design'."
---

# Extractify Code Connect — Link Components to Figma

Maps built React components to their Figma design nodes so designers see the real component code, prop names, and import paths directly inside Figma Dev Mode.

Run this after a component has passed compliance + visual review.

## Before starting

Read:
1. `_docs/structure/code-connect.md` — Code Connect integration details
2. `.claude/commands/extractify-code-connect.md` — **full implementation: read this and follow it exactly**

## How to call this

```
/extractify-code-connect hero           ← map one component by name
/extractify-code-connect --push         ← push all existing mappings to Figma
```

For `--push`: reads all `.figma-connect.ts` files in `src/components/` and pushes them to Figma in one batch.

## What it produces

For each component mapped, creates `src/components/<Name>/<Name>.figma-connect.ts`:

```ts
import figma from '@figma/code-connect'
import { MyComponent } from './index'

figma.connect(MyComponent, 'https://www.figma.com/...', {
  props: {
    title: figma.string('title'),
    variant: figma.enum('Variant', { primary: 'primary', secondary: 'secondary' }),
  },
  example: ({ title, variant }) => <MyComponent title={title} variant={variant} />,
})
```

## Prerequisites

- Component exists in `src/components/<Name>/index.tsx`
- Component has passed compliance + visual review
- Figma URL exists in `_docs/figma-paths.yaml` under `components.<name>`
- Figma Desktop MCP connected

## Recommended workflow

1. `/extractify-new-component hero` — build + review
2. `/extractify-audit` — verify compliance
3. `/extractify-code-connect hero` — map to Figma
4. `/extractify-code-connect --push` — publish all mappings
