# Accounting Ruby

Rails app for budgeting and **actual expenditure** tracking. The UI uses **Phlex** views, **RubyUI** (Tailwind / shadcn-style) components, **Propshaft** for assets, and **Importmap** for JavaScript.

## Requirements

- **Ruby** 3.4.x (see [`.ruby-version`](.ruby-version); project uses `ruby-3.4.8`)
- **Bundler**
- **Node** is optional for this repo; Tailwind is built via the **`tailwindcss-rails`** gem (no `npm run` required for CSS)
- **SQLite** for local development (databases under [`storage/`](storage/))
- The **PostgreSQL** gem is included for deployments that set `DATABASE_URL`; adjust [`config/database.yml`](config/database.yml) if you use Postgres locally

## Quick start

```bash
bin/setup
```

This installs gems, runs **`bin/rails tailwindcss:build`**, prepares the database, then starts **`bin/dev`** (Rails + Tailwind watch).

Manual equivalent:

```bash
bundle install
bin/rails tailwindcss:build
bin/rails db:prepare
bin/dev
```

Open [http://localhost:3000](http://localhost:3000).

### First-time / fresh clone checklist

1. **`bin/rails tailwindcss:build`** — generates [`app/assets/builds/tailwind.css`](app/assets/builds/tailwind.css). Without it, pages load but **have almost no styling**.
2. Prefer **`bin/dev`** over **`bin/rails server` alone** so **`tailwindcss:watch`** recompiles CSS when you edit [`app/assets/tailwind/application.css`](app/assets/tailwind/application.css).

## Stack overview

| Piece | Role |
|--------|------|
| **Rails 8.1** | Web framework |
| **Propshaft** | Serves fingerprinted assets from `app/assets` |
| **tailwindcss-rails** | Compiles `app/assets/tailwind/application.css` → `app/assets/builds/tailwind.css` |
| **Phlex** (`phlex-rails`) | Ruby HTML/views under [`app/views/`](app/views/) |
| **RubyUI** | Component library under [`app/components/ruby_ui/`](app/components/ruby_ui/) |
| **Hotwire** | Turbo + Stimulus via importmap |

### Assets and Propshaft

The layout uses **`stylesheet_link_tag :app`**, which links every `app/assets/**/*.css` that exists (including the Tailwind build under `app/assets/builds/`). That avoids **`Propshaft::MissingAssetError`** if `tailwind.css` has not been built yet (you only miss styles until you run `tailwindcss:build`).

Do **not** rely on `stylesheet_link_tag "tailwind"` unless you are sure `app/assets/builds/tailwind.css` exists in every environment (CI, Docker, new clones).

Theme tokens (colors, radius, sidebar variables) live in [`app/assets/tailwind/application.css`](app/assets/tailwind/application.css).

## App structure

### Routes (main UI)

| Path | Description |
|------|-------------|
| `/` | Dashboard — **actual expenditure** |
| `/revenue_budgets` | Revenue budgets (placeholder) |
| `/expenditure_budgets` | Expenditure budgets (placeholder) |
| `/settings` | Settings (placeholder) |

### Layout and pages

- **Shell:** [`app/views/layouts/application.html.erb`](app/views/layouts/application.html.erb) wraps content in **`RubyUI::Layout`** ([`app/components/ruby_ui/layout.rb`](app/components/ruby_ui/layout.rb)): desktop sidebar, mobile sheet menu, flash, centered main column (same pattern as a typical RubyUI / hpees-style app).
- **Pages:** Phlex classes under [`app/views/`](app/views/) (e.g. `Views::Dashboard::Index`). Zeitwerk maps folder names like `revenue_budgets/` to **`Views::RevenueBudget::Index`** (not `RevenueBudgets`) — see Rails inflection in [`config/application.rb`](config/application.rb).

### Models

Domain models live under [`app/models/`](app/models/) (e.g. actual expenditures, revenue/expenditure budgets). Wire them into the dashboard and section pages as you build features.

## Commands

| Command | Purpose |
|---------|---------|
| `bin/dev` | Foreman: `web` (Puma) + `css` (`tailwindcss:watch`) — **recommended** for development |
| `bin/rails server` | Rails only; CSS will **not** auto-rebuild |
| `bin/rails tailwindcss:build` | One-off Tailwind compile |
| `bin/rails db:prepare` | Create/migrate DB |
| `bin/rails db:reset` | Drop, create, migrate, seed (destructive) |
| `bin/rails test` | Minitest |
| `bin/rubocop` | Lint (RuboCop Omakase) |
| `bin/brakeman` | Security scan |
| `bundle exec bundler-audit` | Gem vulnerability audit |

## Docker & production

- [`Dockerfile`](Dockerfile) builds the app; **`rails assets:precompile`** runs in the image and **`tailwindcss:build`** is hooked to **`assets:precompile`** by `tailwindcss-rails`.
- [Kamal](https://kamal-deploy.org/) config: [`config/deploy.yml`](config/deploy.yml).

## Troubleshooting

### `Propshaft::MissingAssetError` for `tailwind.css`

Run **`bin/rails tailwindcss:build`** or use **`bin/dev`**. Ensure you are not adding a bare `stylesheet_link_tag "tailwind"` without guaranteeing the file exists.

### Styles look unstyled / broken layout

1. Confirm **`app/assets/builds/tailwind.css`** exists and is non-empty.
2. Restart the server after changing asset paths or initializers.
3. Clear browser cache if asset digests changed.

### Spring / stale code (if enabled)

```bash
bin/spring stop
```

## Contributing

If the repo includes **`AGENTS.md`**, follow that for Git/PR workflow and tooling conventions.

## License

See repository root for a `LICENSE` file if one is added; otherwise treat usage as defined by the project owner.
