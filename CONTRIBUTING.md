# Contributing to Figma Extractify

Thank you for your interest in contributing! This guide will help you get started.

## Getting started

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/<your-username>/figma-extractify.git
   cd figma-extractify
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b feature/my-change
   ```

## Development setup

The boilerplate lives in `boilerplate/`. To get it running:

```bash
cd boilerplate
npm install
npm run dev
```

Run the full quality check before submitting:

```bash
npm run check   # audit + lint + typecheck + build
```

## What you're editing

This repo has four kinds of source, each tested differently. A PR that touches more than one should run through each relevant check below.

| Source | Where | How to test |
|---|---|---|
| **Prompts** (`/extractify-*` commands) | `figma-extractify/.claude/commands/*.md` | Install locally against a throwaway project, run the command end-to-end against `example-file/example.fig`, verify the output against the contract doc it references |
| **Scripts** (`visual-diff.js`, `a11y-audit.js`, `install.sh`/`ps1`/`bat`, `uninstall.*`) | `figma-extractify/scripts/`, `figma-extractify/install.*`, `figma-extractify/uninstall.*` | Run against a clean checkout in a throwaway folder; also test re-running (upgrade path) and uninstall |
| **Contracts** (`_docs/front-end/*.md`, `_docs/structure/*.md`, `_docs/start-here.md`) | `figma-extractify/_docs/` | Re-run the command that consumes the contract — a contract change that doesn't change command behavior is probably a doc-only edit and that's fine |
| **Boilerplate** (Next.js app) | `boilerplate/src/` | `cd boilerplate && npm run check` |

## IDE parity

Agent guidance is duplicated across four IDE configs. When you change one, grep for the same content in the others and update them in the same PR:

- `figma-extractify/CLAUDE.md` (Claude Code)
- `figma-extractify/.cursor/rules/figma-to-code.mdc` (Cursor)
- `figma-extractify/.windsurfrules` (Windsurf)
- `figma-extractify/.github/copilot-instructions.md` (GitHub Copilot)

A PR that only touches one of the four will be asked to sync the others. If a rule is genuinely IDE-specific, call that out in the PR description so the asymmetry is intentional.

## Testing the installer

Before submitting changes to `install.sh`/`install.ps1`/`install.bat` or to the list of files the installer copies:

1. **Clean install.** Clone to a fresh folder, copy `figma-extractify/` into `boilerplate/`, run the installer. Verify `/extractify-preflight` reports everything green.
2. **Upgrade install.** Run the installer *again* on the same folder. Confirm:
   - User-owned files unchanged: `_docs/figma-paths.yaml`, `_docs/learnings.md`, `CLAUDE.md`, `.mcp.json`, `.claude/settings.json`.
   - Shipped files overwritten: `.claude/commands/*`, `.claude/skills/figma-use/`, `scripts/*`, `_docs/front-end/*`, `_docs/structure/*`, `.cursor/rules/*`, `.windsurfrules`, `.github/copilot-instructions.md`.
   - Summary line at the end reads `Upgrade summary: N shipped files updated, M user-owned files preserved`.
3. **Uninstall.** Run `uninstall.sh`, confirm the post-uninstall state matches the documented "What it does NOT touch" list in `figma-extractify/README.md`.

## Changelog discipline

Every user-visible change needs a CHANGELOG entry under `## [Unreleased]`:

- `### Added` — new commands, new contracts, new extract targets, new IDE support
- `### Changed` — renamed commands, changed contract shape, new required YAML fields, installer behavior changes
- `### Fixed` — bug fixes
- `### Removed` — deprecated features

Prompt-only tweaks that don't change observable behavior (wording, clarifications) don't need an entry.

## How to contribute

### Reporting bugs

Open an [issue](https://github.com/99x/figma-extractify/issues/new?template=bug_report.md) with a clear description, steps to reproduce, and expected vs. actual behavior.

### Suggesting features

Open an [issue](https://github.com/99x/figma-extractify/issues/new?template=feature_request.md) describing the problem you want to solve and how you'd approach it.

### Submitting pull requests

1. Make sure your branch is up to date with `main`.
2. Keep pull requests focused — one feature or fix per PR.
3. Write clear commit messages. We recommend the [Conventional Commits](https://www.conventionalcommits.org/) format:
   - `feat: add new component template`
   - `fix: resolve install.sh path issue on Linux`
   - `docs: update contributing guide`
4. Make sure `npm run check` passes in `boilerplate/`.
5. Open a pull request against `main` and fill in the PR template.

## Code style

- **TypeScript** for all source files in `boilerplate/src/`.
- **ESLint** is configured — run `npm run lint` to check.
- **Tailwind CSS v4** for styling — avoid inline styles.
- Follow the existing patterns: PascalCase for component folders, kebab-case for SVG assets.

## Project structure

This is a monorepo with three parts:

- `figma-extractify/` — the AI command system (shell scripts, YAML configs, prompt templates).
- `boilerplate/` — the Next.js + Tailwind starter (TypeScript, React).
- `example-file/` — sample Figma file for testing.

When contributing, make sure your changes go in the right folder.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
