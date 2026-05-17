# 記帳 (accounting_ruby)

Personal budgeting and **actual expenditure** tracking for monthly income, spending, and category budgets.

**Bilingual:** [English](#english) · [中文](#中文)

Built with **Rails 8.1**, **Phlex** views, **RubyUI** (Tailwind / shadcn-style), **Propshaft**, and **Hotwire** (Turbo + Stimulus).

---

## English

### Features

| Area | What you can do |
|------|-----------------|
| **實際支出** (`/`) | Log expenses with category, payment method, and optional platform; live budget/remain summary and monthly spending chart |
| **支出紀錄** (`/expenses/history`) | Browse, edit, and delete past expenditures |
| **預算** (`/budgets`) | Set monthly **revenue** and **expenditure** budgets (carousel cards, auto-save, allocation chart) |
| **設定** (`/settings`) | Manage per-user lists: 消費類別, 支付方式, 支付平台 (used in expense forms) |

Sign in with **Google OAuth** at `/login`. Without `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`, local dev can use **試用帳號** on the login page; tests still use fixture users.

### Requirements

- **Ruby** 3.4.x ([`.ruby-version`](.ruby-version) — currently `ruby-3.4.8`)
- **Bundler**
- **SQLite** for local dev ([`storage/`](storage/))
- **Node** not required — Tailwind is compiled by the **`tailwindcss-rails`** gem
- **PostgreSQL** gem is available if you set `DATABASE_URL` for production

### Quick start

```bash
bin/setup
```

This installs gems, builds Tailwind CSS, runs `db:prepare`, and starts **`bin/dev`** (Rails + `tailwindcss:watch`).

Open [http://localhost:3000](http://localhost:3000).

Manual steps:

```bash
bundle install
bin/rails tailwindcss:build
bin/rails db:prepare
bin/dev
```

> **Fresh clone:** If pages load without styling, run `bin/rails tailwindcss:build` or use `bin/dev` (not `bin/rails server` alone).

### Routes

| Path | Description |
|------|-------------|
| `/` | Dashboard — log and summarize **actual expenditure** |
| `/expenses/history` | Expense history (edit / delete) |
| `/budgets` | Monthly revenue & expenditure budgets |
| `/settings` | Taxonomy: categories, payment methods, platforms |
| `/login` | Sign in (Google OAuth or local trial) |
| `/logout` | Sign out (DELETE) |
| `/up` | Health check (used by Railway) |
| `/revenue_budgets`, `/expenditure_budgets` | Redirect to `/budgets` |

### Stack

| Piece | Role |
|--------|------|
| Rails 8.1 | Web framework |
| Phlex | Ruby HTML views under [`app/views/`](app/views/) |
| RubyUI | UI components under [`app/components/ruby_ui/`](app/components/ruby_ui/) |
| tailwindcss-rails | `app/assets/tailwind/application.css` → `app/assets/builds/tailwind.css` |
| Propshaft | Asset pipeline (`stylesheet_link_tag :app`) |
| Importmap + Stimulus | JavaScript controllers |

### Models (overview)

| Model | Purpose |
|--------|---------|
| `User` | Account (Google UID + email; trial user for local dev) |
| `CalendarMonth` | Global year/month bucket for budgets and expenses |
| `ActualExpenditure` | Logged spending |
| `RevenueBudget` / `ExpenditureBudget` | Monthly budget lines |
| `ExpenditureTaxonomyItem` | Per-user dropdown options (category, payment method, platform) |

### Commands

| Command | Purpose |
|---------|---------|
| `bin/dev` | **Recommended** — Puma + Tailwind watch |
| `bin/rails server` | Rails only (no CSS rebuild) |
| `bin/rails tailwindcss:build` | One-off Tailwind compile |
| `bin/rails db:prepare` | Create / migrate database |
| `bin/rails test` | Minitest + system tests |
| `bin/rubocop` | Lint |

### Deploying (Railway)

Production boots via **[`bin/start-web`](bin/start-web)** (Thruster → Puma), which:

1. Runs **`db:prepare`** (migrations)
2. Runs **`assets:precompile`** if `public/assets` is missing
3. Sets **`HTTP_PORT`** from Railway’s **`PORT`**

[`railway.toml`](railway.toml) also runs **`assets:precompile`** at build time and **`db:prepare`** as a release command.

**Required variables**

| Variable | Notes |
|----------|--------|
| `SECRET_KEY_BASE` | `bin/rails secret` |
| `RAILS_MASTER_KEY` | If using encrypted credentials |
| `PORT` | Must match Railway public **target port** (Thruster listens here) |

**Docker:** [`Dockerfile`](Dockerfile) precompiles assets during image build. **Kamal:** [`config/deploy.yml`](config/deploy.yml).

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| **500 on `/`** after deploy | Redeploy so `db:prepare` runs; or run `bin/rails db:prepare` on Railway |
| **`tailwind-*.css` 404** / unstyled page | Ensure deploy runs `assets:precompile` (see `railway.toml` / `bin/start-web`) |
| **Application failed to respond** | Set `PORT` to match networking target port; confirm `SECRET_KEY_BASE` |
| **`Propshaft::MissingAssetError`** | Run `bin/rails tailwindcss:build` locally; do not use bare `stylesheet_link_tag "tailwind"` without the built file |

### Contributing

See [`AGENTS.md`](AGENTS.md) for branch/PR workflow and Linear issue conventions.

---

## 中文

### 功能

| 區塊 | 說明 |
|------|------|
| **實際支出**（`/`） | 登錄支出（類別、支付方式、平台等）；即時預算／餘額摘要與本月支出圖表 |
| **支出紀錄**（`/expenses/history`） | 瀏覽、編輯、刪除歷史支出 |
| **預算**（`/budgets`） | 每月**收入**與**支出**預算（輪播卡片、自動儲存、配置圖） |
| **設定**（`/settings`） | 管理個人選項：消費類別、支付方式、支付平台 |

尚未接上 Google 登入前，應用透過 **試用帳號**（`TrialAccount`）讓表單可正常操作。

### 環境需求

- **Ruby** 3.4.x（見 [`.ruby-version`](.ruby-version)）
- **Bundler**
- 本機預設 **SQLite**（[`storage/`](storage/)）
- 不必安裝 **Node** — Tailwind 由 **`tailwindcss-rails`** 編譯
- 正式環境可透過 `DATABASE_URL` 使用 **PostgreSQL**

### 快速開始

```bash
bin/setup
```

會安裝套件、編譯 Tailwind、執行 `db:prepare`，並啟動 **`bin/dev`**。

開啟 [http://localhost:3000](http://localhost:3000)。

手動步驟：

```bash
bundle install
bin/rails tailwindcss:build
bin/rails db:prepare
bin/dev
```

> **新 clone：** 若頁面幾乎無樣式，請執行 `bin/rails tailwindcss:build`，或改用 `bin/dev`（不要只跑 `bin/rails server`）。

### 路由

| 路徑 | 說明 |
|------|------|
| `/` | 儀表板 — **實際支出** |
| `/expenses/history` | 支出紀錄（編輯／刪除） |
| `/budgets` | 收入與支出預算 |
| `/settings` | 消費類別、支付方式、支付平台 |
| `/up` | 健康檢查（Railway 使用） |
| `/revenue_budgets`、`/expenditure_budgets` | 重新導向至 `/budgets` |

### 技術堆疊

| 項目 | 說明 |
|--------|------|
| Rails 8.1 | Web 框架 |
| Phlex | Ruby 視圖 [`app/views/`](app/views/) |
| RubyUI | 元件庫 [`app/components/ruby_ui/`](app/components/ruby_ui/) |
| tailwindcss-rails | 編譯 Tailwind CSS |
| Propshaft | 靜態資源（`stylesheet_link_tag :app`） |
| Importmap + Stimulus | 前端互動 |

### 模型（概覽）

| 模型 | 用途 |
|--------|------|
| `User` | 使用者（本機試用帳號） |
| `CalendarMonth` | 依年月彙總的行事曆月份 |
| `ActualExpenditure` | 實際支出 |
| `RevenueBudget` / `ExpenditureBudget` | 預算列 |
| `ExpenditureTaxonomyItem` | 個人化下拉選項 |

### 常用指令

| 指令 | 用途 |
|---------|---------|
| `bin/dev` | **建議** — Puma + Tailwind 監聽 |
| `bin/rails server` | 僅 Rails（CSS 不會自動重編） |
| `bin/rails tailwindcss:build` | 單次編譯 Tailwind |
| `bin/rails db:prepare` | 建立／遷移資料庫 |
| `bin/rails test` | 測試 |
| `bin/rubocop` | 程式風格檢查 |

### 部署（Railway）

正式環境由 **[`bin/start-web`](bin/start-web)** 啟動（Thruster → Puma），會：

1. 執行 **`db:prepare`**
2. 若缺少 `public/assets` 則執行 **`assets:precompile`**
3. 以 Railway 的 **`PORT`** 設定 **`HTTP_PORT`**

[`railway.toml`](railway.toml) 在建置階段執行 **`assets:precompile`**，並以 **`db:prepare`** 作為 release 指令。

**建議環境變數**

| 變數 | 說明 |
|----------|--------|
| `SECRET_KEY_BASE` | `bin/rails secret` |
| `RAILS_MASTER_KEY` | 若使用加密 credentials |
| `PORT` | 須與 Railway 對外 **target port** 一致 |

**Docker：** [`Dockerfile`](Dockerfile) 建置時會 precompile 資源。**Kamal：** [`config/deploy.yml`](config/deploy.yml)。

### 疑難排解

| 現象 | 處理方式 |
|------|----------|
| 部署後 **`/` 回 500** | 重新部署以執行 `db:prepare`；或在 Railway 執行 `bin/rails db:prepare` |
| **`tailwind-*.css` 404**／無樣式 | 確認部署有跑 `assets:precompile`（見 `railway.toml`、`bin/start-web`） |
| **Application failed to respond** | 設定 `PORT` 與 target port 一致；確認 `SECRET_KEY_BASE` |
| **`Propshaft::MissingAssetError`** | 本機執行 `bin/rails tailwindcss:build` |

### 貢獻

請參閱 [`AGENTS.md`](AGENTS.md)（分支／PR 流程與 Linear 議題慣例）。
