<p align="center">
  <img src="banner.svg" alt="Figma Extractify" width="100%">
</p>

# Figma Extractify — Monorepo

This repo contains two independent projects that work great together but are designed to be used separately.

---

## What's here

### [`figma-extractify/`](./figma-extractify)

The AI skill system. Point it at any Figma file and extract your design tokens, build components with automated visual review, and link everything back to Figma Dev Mode.

Works with **Claude Code**, **Cowork**, **Cursor**, **Windsurf**, and **GitHub Copilot**. Does not require the boilerplate — install it into any existing project.

→ [Read the Figma Extractify docs](./figma-extractify/README.md)

### [`boilerplate/`](./boilerplate)

A clean **Next.js 16 + Tailwind CSS v4** starter for building isolated, props-driven UI components. Includes GSAP, Swiper, react-hook-form, and Fancybox out of the box.

Works standalone. Figma Extractify is not required, but pairs perfectly with it.

→ [Read the Boilerplate docs](./boilerplate/README.md)

---

## Repo structure

```
figma-extractify/          ← repo root (clone lands here)
├── figma-extractify/      ← the AI skill system — install.sh lives here
│   ├── install.sh
│   ├── _docs/
│   └── .claude/
└── boilerplate/           ← Next.js + Tailwind starter (package.json lives here)
```

## Using them together

The recommended setup — clone the repo, run the installer, and start extracting:

```bash
# 1. Clone the repo
git clone https://github.com/your-org/figma-extractify.git

# 2. Run the installer from inside the figma-extractify/ subfolder
#    (the installer auto-detects the monorepo and installs npm deps in boilerplate/)
cd figma-extractify/figma-extractify
bash install.sh

# 3. Restart Claude Code / Cowork so /extractify-* commands appear

# 4. Add your Figma URLs and start extracting
# → edit _docs/figma-paths.yaml
# → open Figma Desktop in Dev Mode
# → cd ../boilerplate && npm run dev
# → /extractify-setup
```

> **Why `cd figma-extractify/figma-extractify`?** The monorepo root contains two siblings: `figma-extractify/` (the skill system) and `boilerplate/` (the Next.js project). The installer must be run from inside `figma-extractify/` where `install.sh` lives — not from the repo root.

## Using them separately

**Just the boilerplate** — clone and use `boilerplate/` as your project root. No AI tooling required.

**Just Figma Extractify** — copy the `figma-extractify/` folder into any existing Next.js project, then run `bash install.sh` from inside it. It drops in the `.claude/`, `_docs/`, and `scripts/` folders without touching your codebase.
