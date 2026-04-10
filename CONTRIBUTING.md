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

- `figma-extractify/` — the AI skill system (shell scripts, YAML configs, prompt templates).
- `boilerplate/` — the Next.js + Tailwind starter (TypeScript, React).
- `example-file/` — sample Figma file for testing.

When contributing, make sure your changes go in the right folder.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
