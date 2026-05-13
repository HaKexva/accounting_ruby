# Accounting Ruby

**Bilingual README / 雙語說明：** [English](#english) · [中文](#中文)

Rails app for budgeting and **actual expenditure** tracking. The UI uses **Phlex** views, **RubyUI** (Tailwind / shadcn-style) components, **Propshaft** for assets, and **Importmap** for JavaScript.

以 Rails 打造的預算與**實際支出**追蹤應用；介面使用 **Phlex** 視圖、**RubyUI**（Tailwind / shadcn 風格）元件、**Propshaft** 管理靜態資源，並以 **Importmap** 載入 JavaScript。

---

## English

### Requirements

- **Ruby** 3.4.x (see [`.ruby-version`](.ruby-version); project uses `ruby-3.4.8`)
- **Bundler**
- **Node** is optional for this repo; Tailwind is built via the **`tailwindcss-rails`** gem (no `npm run` required for CSS)
- **SQLite** for local development (databases under [`storage/`](storage/))
- The **PostgreSQL** gem is included for deployments that set `DATABASE_URL`; adjust [`config/database.yml`](config/database.yml) if you use Postgres locally

### Quick start

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

#### First-time / fresh clone checklist

1. **`bin/rails tailwindcss:build`** — generates [`app/assets/builds/tailwind.css`](app/assets/builds/tailwind.css). Without it, pages load but **have almost no styling**.
2. Prefer **`bin/dev`** over **`bin/rails server` alone** so **`tailwindcss:watch`** recompiles CSS when you edit [`app/assets/tailwind/application.css`](app/assets/tailwind/application.css).

### Stack overview

| Piece | Role |
|--------|------|
| **Rails 8.1** | Web framework |
| **Propshaft** | Serves fingerprinted assets from `app/assets` |
| **tailwindcss-rails** | Compiles `app/assets/tailwind/application.css` → `app/assets/builds/tailwind.css` |
| **Phlex** (`phlex-rails`) | Ruby HTML/views under [`app/views/`](app/views/) |
| **RubyUI** | Component library under [`app/components/ruby_ui/`](app/components/ruby_ui/) |
| **Hotwire** | Turbo + Stimulus via importmap |

#### Assets and Propshaft

The layout uses **`stylesheet_link_tag :app`**, which links every `app/assets/**/*.css` that exists (including the Tailwind build under `app/assets/builds/`). That avoids **`Propshaft::MissingAssetError`** if `tailwind.css` has not been built yet (you only miss styles until you run `tailwindcss:build`).

Do **not** rely on `stylesheet_link_tag "tailwind"` unless you are sure `app/assets/builds/tailwind.css` exists in every environment (CI, Docker, new clones).

Theme tokens (colors, radius, sidebar variables) live in [`app/assets/tailwind/application.css`](app/assets/tailwind/application.css).

### App structure

#### Routes (main UI)

| Path | Description |
|------|-------------|
| `/` | Dashboard — **actual expenditure** |
| `/revenue_budgets` | Revenue budgets (placeholder) |
| `/expenditure_budgets` | Expenditure budgets (placeholder) |
| `/settings` | Settings (placeholder) |

#### Layout and pages

- **Shell:** [`app/views/layouts/application.html.erb`](app/views/layouts/application.html.erb) wraps content in **`RubyUI::Layout`** ([`app/components/ruby_ui/layout.rb`](app/components/ruby_ui/layout.rb)): desktop sidebar, mobile sheet menu, flash, centered main column (same pattern as a typical RubyUI / hpees-style app).
- **Pages:** Phlex classes under [`app/views/`](app/views/) (e.g. `Views::Dashboard::Index`). Zeitwerk maps folder names like `revenue_budgets/` to **`Views::RevenueBudget::Index`** (not `RevenueBudgets`) — see Rails inflection in [`config/application.rb`](config/application.rb).

#### Models

Domain models live under [`app/models/`](app/models/) (e.g. actual expenditures, revenue/expenditure budgets). Wire them into the dashboard and section pages as you build features.

### Commands

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

### Docker & production

- [`Dockerfile`](Dockerfile) builds the app; **`rails assets:precompile`** runs in the image and **`tailwindcss:build`** is hooked to **`assets:precompile`** by `tailwindcss-rails`.
- [Kamal](https://kamal-deploy.org/) config: [`config/deploy.yml`](config/deploy.yml).

### Railway

Production uses **[Thruster](https://github.com/basecamp/thruster)** in front of Puma. Thruster’s default HTTP listen port is **80**, while **Railway injects `PORT`** (often **8080**). If they do not match, health checks and browsers get **“Application failed to respond.”**

This repo fixes that by:

- **`Dockerfile`**: `CMD` sets **`HTTP_PORT` from `PORT`** before starting Thruster. Puma runs on Thruster’s default **`TARGET_PORT` (3000)**.
- **[`Procfile`](Procfile)** (for Nixpacks / non-Docker builds): same `HTTP_PORT="${PORT:-80}"` pattern.

**Ports:**

| Port | Role |
|------|------|
| **`PORT`** (Railway) | Port **Thruster** listens on — **injected by Railway** (often `8080`). Must match your public domain **target port**. |
| **3000** (behind Thruster) | **Puma** listens here inside the container (Thruster’s default **`TARGET_PORT`**). Override only if you set **`TARGET_PORT`** explicitly. |
| **3100** (local only) | When **`PORT` is unset** (e.g. `bin/rails server` without Foreman), **`config/puma.rb`** uses **`ENV.fetch("PORT", 3100)`** so local dev defaults to **3100**. |

**Set in the Railway service:**

| Variable | Notes |
|----------|--------|
| `SECRET_KEY_BASE` | Required for production Rails (generate with `bin/rails secret`). |
| `RAILS_MASTER_KEY` | Required if you use encrypted credentials (`config/master.key` contents). |
| `PORT` | Usually **pre-set by Railway** — Thruster’s **`HTTP_PORT`** follows this. |
| `TARGET_PORT` | Optional; Thruster defaults to **3000** for Puma. Only set if you need a different internal port. |

Health check path is **`/up`** (see [`railway.toml`](railway.toml)). If deploys fail during first boot, check logs for **`db:prepare`** or migration errors (`bin/docker-entrypoint` runs migrations when the process is `rails server`).

### Troubleshooting

#### Railway: “Application failed to respond”

1. Confirm Thruster listens on **`PORT`**: redeploy after pulling the Dockerfile / `Procfile` fix above, or set **`HTTP_PORT=$PORT`** (or `THRUSTER_HTTP_PORT`) in Railway variables.
2. Confirm **`SECRET_KEY_BASE`** (and **`RAILS_MASTER_KEY`** if using credentials) are set.
3. Read deploy logs for boot errors (database, missing master key, failed migrations).

#### `Propshaft::MissingAssetError` for `tailwind.css`

Run **`bin/rails tailwindcss:build`** or use **`bin/dev`**. Ensure you are not adding a bare `stylesheet_link_tag "tailwind"` without guaranteeing the file exists.

#### Styles look unstyled / broken layout

1. Confirm **`app/assets/builds/tailwind.css`** exists and is non-empty.
2. Restart the server after changing asset paths or initializers.
3. Clear browser cache if asset digests changed.

#### Spring / stale code (if enabled)

```bash
bin/spring stop
```

### Contributing

If the repo includes **`AGENTS.md`**, follow that for Git/PR workflow and tooling conventions.

### License

See repository root for a `LICENSE` file if one is added; otherwise treat usage as defined by the project owner.

---

## 中文

以下為繁體中文說明，與上方 English 章節對應。

### 環境需求

- **Ruby** 3.4.x（見 [`.ruby-version`](.ruby-version)；本專案使用 `ruby-3.4.8`）
- **Bundler**
- **Node**：此專案非必須；Tailwind 由 **`tailwindcss-rails`** 編譯（CSS 不必執行 `npm run`）
- 本機開發預設 **SQLite**（資料庫檔於 [`storage/`](storage/)）
- Gemfile 含 **PostgreSQL** 驅動，若部署使用 `DATABASE_URL` 可接 Postgres；本機若用 Postgres 請調整 [`config/database.yml`](config/database.yml)

### 快速開始

```bash
bin/setup
```

會安裝套件、執行 **`bin/rails tailwindcss:build`**、準備資料庫，並啟動 **`bin/dev`**（Rails + Tailwind 監聽）。

手動步驟：

```bash
bundle install
bin/rails tailwindcss:build
bin/rails db:prepare
bin/dev
```

瀏覽 [http://localhost:3000](http://localhost:3000)。

#### 首次安裝／全新 clone 檢查

1. 執行 **`bin/rails tailwindcss:build`**，產生 [`app/assets/builds/tailwind.css`](app/assets/builds/tailwind.css)。若略過此步驟，頁面可開啟但**幾乎沒有樣式**。
2. 開發時建議用 **`bin/dev`**，不要只跑 **`bin/rails server`**，否則修改 [`app/assets/tailwind/application.css`](app/assets/tailwind/application.css) 時不會自動重編譯 CSS（需有 **`tailwindcss:watch`**）。

### 技術堆疊概覽

| 項目 | 說明 |
|--------|------|
| **Rails 8.1** | Web 框架 |
| **Propshaft** | 自 `app/assets` 提供帶指紋的靜態資源 |
| **tailwindcss-rails** | 將 `app/assets/tailwind/application.css` 編譯為 `app/assets/builds/tailwind.css` |
| **Phlex**（`phlex-rails`） | 以 Ruby 撰寫的 HTML／視圖，位於 [`app/views/`](app/views/) |
| **RubyUI** | 元件庫，位於 [`app/components/ruby_ui/`](app/components/ruby_ui/) |
| **Hotwire** | 透過 importmap 使用 Turbo + Stimulus |

#### 資源與 Propshaft

版面使用 **`stylesheet_link_tag :app`**，會連結所有存在的 `app/assets/**/*.css`（含 `app/assets/builds/` 下的 Tailwind 產出）。若尚未建置 `tailwind.css`，**不會**因此拋出 **`Propshaft::MissingAssetError`**（只是暫時沒有樣式，執行 `tailwindcss:build` 即可）。

請勿單獨使用 `stylesheet_link_tag "tailwind"`，除非你能保證每個環境（CI、Docker、新 clone）都有 `app/assets/builds/tailwind.css`。

主題色票、圓角、側欄等 CSS 變數定義在 [`app/assets/tailwind/application.css`](app/assets/tailwind/application.css)。

### 應用程式結構

#### 路由（主要介面）

| 路徑 | 說明 |
|------|------|
| `/` | 儀表板 — **實際支出** |
| `/revenue_budgets` | 收入預算（目前為占位頁） |
| `/expenditure_budgets` | 支出預算（目前為占位頁） |
| `/settings` | 設定（目前為占位頁） |

#### 版面與頁面

- **外殼：** [`app/views/layouts/application.html.erb`](app/views/layouts/application.html.erb) 以 **`RubyUI::Layout`**（[`app/components/ruby_ui/layout.rb`](app/components/ruby_ui/layout.rb)）包住內容：桌面側欄、行動版抽屜選單、flash、置中主內容欄（與常見 RubyUI／hpees 風格相同）。
- **頁面：** [`app/views/`](app/views/) 下的 Phlex 類別（例如 `Views::Dashboard::Index`）。Zeitwerk 會將 `revenue_budgets/` 等資料夾對應到 **`Views::RevenueBudget::Index`**（不是 `RevenueBudgets`）— 見 [`config/application.rb`](config/application.rb) 中的複數／單數設定。

#### 模型

網域模型在 [`app/models/`](app/models/)（例如實際支出、收入／支出預算）。實作功能時再將其接到儀表板與各區塊頁面。

### 常用指令

| 指令 | 用途 |
|---------|---------|
| `bin/dev` | Foreman：同時跑 `web`（Puma）與 `css`（`tailwindcss:watch`）— **建議**日常開發使用 |
| `bin/rails server` | 僅 Rails；CSS **不會**自動重編譯 |
| `bin/rails tailwindcss:build` | 單次編譯 Tailwind |
| `bin/rails db:prepare` | 建立／遷移資料庫 |
| `bin/rails db:reset` | 刪除並重建資料庫、執行 seed（具破壞性） |
| `bin/rails test` | 執行 Minitest |
| `bin/rubocop` | 程式風格檢查（RuboCop Omakase） |
| `bin/brakeman` | 安全性掃描 |
| `bundle exec bundler-audit` | 檢查套件已知漏洞 |

### Docker 與正式環境

- [`Dockerfile`](Dockerfile) 建置映像時會跑 **`rails assets:precompile`**；`tailwindcss-rails` 會在 **`assets:precompile`** 階段觸發 **`tailwindcss:build`**。
- [Kamal](https://kamal-deploy.org/) 設定：[`config/deploy.yml`](config/deploy.yml)。

### Railway

正式環境使用 **[Thruster](https://github.com/basecamp/thruster)** 反向代理 Puma。Thruster 預設 **`HTTP_PORT=80`** 監聽 HTTP，而 **Railway 會注入 `PORT`**（常見為 **8080**）。兩者不一致時，健康檢查與瀏覽器會出現 **「Application failed to respond」**。

本專案已處理：

- **`Dockerfile`**：`CMD` 將 **`HTTP_PORT` 設為 Railway 的 `PORT`**。Puma 在 Thruster 後方使用 Thruster 預設 **`TARGET_PORT`（3000）**。
- **[`Procfile`](Procfile)**（Nixpacks／非 Docker 建置）：同上 `HTTP_PORT="${PORT:-80}"`。

**埠號：**

| 埠 | 用途 |
|------|------|
| **`PORT`**（Railway） | **Thruster** 對外監聽 — 由 **Railway 注入**（常為 `8080`）。須與公開網域 **target port** 一致。 |
| **3000**（Thruster 後方） | **Puma** 在容器內監聽（Thruster 預設 **`TARGET_PORT`**）。除非自行設定 **`TARGET_PORT`**，否則不必改。 |
| **3100**（僅本機） | 當 **`PORT` 未設定**（例如未經 Foreman 直接 `bin/rails server`）時，**`config/puma.rb`** 使用 **`ENV.fetch("PORT", 3100)`**，本機預設 **3100**。 |

**建議在 Railway 服務變數中設定：**

| 變數 | 說明 |
|----------|--------|
| `SECRET_KEY_BASE` | 正式環境必填（可用 `bin/rails secret` 產生）。 |
| `RAILS_MASTER_KEY` | 若使用加密 credentials，請貼上 `config/master.key` 內容。 |
| `PORT` | 通常由 **Railway 自動設定** — Thruster 的 **`HTTP_PORT`** 會跟隨此值。 |
| `TARGET_PORT` | 選填；Thruster 對 Puma 預設為 **3000**。僅在需要其他內部埠時設定。 |

健康檢查路徑為 **`/up`**（見 [`railway.toml`](railway.toml)）。若首次部署失敗，請查看日誌是否為 **`db:prepare`** 或遷移錯誤（`bin/docker-entrypoint` 在啟動 `rails server` 時會執行資料庫準備）。

### 疑難排解

#### Railway：「Application failed to respond」

1. 確認 Thruster 監聽 **`PORT`**：請拉取並重新部署含上述 Dockerfile／`Procfile` 的版本，或在 Railway 變數設定 **`HTTP_PORT=$PORT`**（或 `THRUSTER_HTTP_PORT`）。
2. 確認已設定 **`SECRET_KEY_BASE`**（以及使用 credentials 時的 **`RAILS_MASTER_KEY`**）。
3. 查看部署日誌是否有啟動錯誤（資料庫、master key、遷移失敗等）。

#### 出現 `Propshaft::MissingAssetError`（找不到 `tailwind.css`）

執行 **`bin/rails tailwindcss:build`** 或改用 **`bin/dev`**。請勿在未保證檔案存在時單獨使用 `stylesheet_link_tag "tailwind"`。

#### 畫面無樣式／版面異常

1. 確認 **`app/assets/builds/tailwind.css`** 存在且非空檔。
2. 修改資源路徑或 initializer 後請重啟伺服器。
3. 若資源指紋變更，可清除瀏覽器快取。

#### Spring／程式碼未更新（若啟用 Spring）

```bash
bin/spring stop
```

### 貢獻指南

若儲存庫含 **`AGENTS.md`**，請依其中說明進行 Git／PR 流程與工具約定。

### 授權

若專案根目錄有 `LICENSE` 檔請依該檔；若無，則以專案擁有者定義之使用方式為準。
