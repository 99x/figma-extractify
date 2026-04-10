# Next.js Boilerplate

A clean, production-ready **Next.js 16 + Tailwind CSS v4** starter for building isolated, props-driven UI components.

Components are built in isolation, previewed locally via `src/app/` routes, and exported as fully typed, reusable React modules. This is not a full Next.js application — it's a component workbench.

---

## Quick start

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the component index.

---

## Stack

| Tool | Version |
|---|---|
| Next.js | ^16.2.2 |
| React | ^19.0.0 |
| Tailwind CSS | ^4.1.18 |
| TypeScript | 5.x |
| GSAP | ^3.13.0 |
| Swiper | ^11.2.4 |
| react-hook-form | ^7.60.0 |
| Fancybox | ^6.0.14 |

---

## Structure

```
src/
  app/                    # Preview pages (Next.js App Router)
  components/             # Reusable components (PascalCase folders)
  assets/css/             # Tailwind v4 + PostCSS
  utils/functions.ts      # Shared helpers (incl. sanitizeHtml via isomorphic-dompurify — use before any dangerouslySetInnerHTML)

public/
  fonts/                  # Self-hosted fonts
  img/                    # Raster images
  svg/ux/                 # UI icons (kebab-case SVG)
```

---

## Adding Figma Extractify

To connect this boilerplate to your Figma file and extract design tokens automatically, install [Figma Extractify](https://github.com/99x/figma-extractify) on top of it:

```bash
# from the root of this project
bash <(curl -fsSL https://raw.githubusercontent.com/99x/figma-extractify/main/install.sh)
```

---

## License

MIT License
