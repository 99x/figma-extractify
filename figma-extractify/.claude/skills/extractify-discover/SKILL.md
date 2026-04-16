---
name: extractify-discover
description: "Use this skill whenever the user wants to scan an entire Figma file to discover or reverse-engineer its design system — when there is no formal design system page yet and the tokens need to be inferred from the actual designs. Triggers on: 'discover design system', 'scan Figma file', 'reverse-engineer tokens', 'analyze the whole Figma file', 'extract all tokens', 'there is no design system page', 'find all the colors and fonts used in Figma', '/extractify-discover', 'create a design system from scratch', 'map the design system', or any request to analyze a full Figma file rather than a specific component or page. Also trigger when the user says 'I don't have a design system set up yet' or 'can you figure out the tokens from the designs'."
---

# Extractify Discover — Design System Discovery

Scans every page of a Figma file, reverse-engineers the implicit design system from the actual designs (colors, typography, spacing, radii, shadows), normalizes the discovered tokens, and optionally pushes a structured Design System reference page back into Figma.

Use this when the design team has **not** created a formal design system page — this skill discovers the tokens from what's actually used in the designs.

## Before starting

Read:
1. `_docs/structure/agent-architecture.md` — subagent model assignments
2. `.claude/commands/extractify-discover.md` — **full implementation: read this and follow it exactly**

## Prerequisites

- **At least one Figma MCP** for reads — Desktop (`127.0.0.1:3845/mcp`) preferred, Remote (`mcp.figma.com/mcp`) as automatic fallback. Discovery fails only if both are down.
- **Figma Remote MCP** additionally required for **write-back** (`generate_figma_design`) — this is Remote-only. Without it, discovery runs in analysis-only mode.
- Dev or Full seat on a paid Figma plan (required for Desktop Dev Mode; Remote works via OAuth against any plan that has access to the file).

## Phases

| Phase | What happens |
|---|---|
| 0: Pre-flight | Check MCP connectivity, Node deps |
| 1: Map file | Get all pages from the Figma file |
| 2: Scan pages | One subagent per page extracts raw token data |
| 3: Normalize | Merge and deduplicate — round to scale, detect aliases |
| 4: Review | Show discovered tokens to user, get approval |
| 5: Generate DS page | Build an HTML design system reference page |
| 6: Push to Figma | Create the DS page in Figma (if write-back is available) |

## What it outputs

- `discovered-tokens.yaml` — normalized token set (colors, type, spacing, radii, shadows)
- A Design System page pushed directly into the Figma file (if write-back available)
- A handoff to `/extractify-setup` — once discovery is complete, run setup to apply tokens to the codebase

## After discovery

Run `/extractify-setup` and point each step at the new Design System page in Figma.
