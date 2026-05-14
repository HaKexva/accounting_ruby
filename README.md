# Accounting

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
| `/budgets` | Budgets — two-part layout (summary + entry) like actual expenditure; **dropdown** switches income vs expenditure placeholders |
| `/revenue_budgets` | Redirects (301) to `/budgets` |
| `/expenditure_budgets` | Redirects (301) to `/budgets` |
| `/settings` | Settings (placeholder) |

#### Layout and pages

- **Shell:** [`app/views/layouts/application.html.erb`](app/views/layouts/application.html.erb) wraps content in **`RubyUI::Layout`** ([`app/components/ruby_ui/layout.rb`](app/components/ruby_ui/layout.rb)): desktop sidebar, mobile sheet menu, flash, centered main column (same pattern as a typical RubyUI / hpees-style app).
- **Pages:** Phlex classes under [`app/views/`](app/views/) (e.g. `Views::Dashboard::Index`, `Views::Budgets::Index`). Zeitwerk maps `budgets/` to **`Views::Budgets::Index`** — see Rails inflection in [`config/application.rb`](config/application.rb).

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

Production uses **[Thruster](https://github.com/basecamp/thruster)** in front of Puma. Thruster’s public listen port is **`HTTP_PORT`**; Puma’s internal port is **`TARGET_PORT`** (default **3000**). **Railway injects `PORT`** for the public edge — **`HTTP_PORT` must equal `PORT`**. If they differ, you get **“Application failed to respond.”**

**[`bin/start-web`](bin/start-web)** sets:

- `HTTP_PORT="${PORT:-8080}"` — if Railway does not set `PORT`, we default Thruster to **8080** (common PaaS default; **set `PORT` in Railway Variables** to match your service networking if needed).
- `TARGET_PORT` default **3000** for Puma behind Thruster.
- If `HTTP_PORT` and `TARGET_PORT` would be the same (e.g. you set **`PORT=3000`**), Puma is moved to **3100** so Thruster and Puma do not bind the same TCP port.

**Dockerfile** / **[`Procfile`](Procfile)** invoke **`bin/start-web`**.

**Ports:**

| Port | Role |
|------|------|
| **`PORT`** (Railway) | Must match **Thruster’s public listen** (`HTTP_PORT`). Set in Railway **Variables** if the platform does not inject it; must match public **target port**. |
| **3000** (typical internal) | **Puma** behind Thruster when `PORT` ≠ 3000. |
| **3100** | **Puma** when you force **`PORT=3000`** (collision avoidance), or **local** `bin/rails server` when `PORT` is unset (`config/puma.rb`). |

**Set in the Railway service:**

| Variable | Notes |
|----------|--------|
| `SECRET_KEY_BASE` | Required for production Rails (generate with `bin/rails secret`). |
| `RAILS_MASTER_KEY` | Required if you use encrypted credentials (`config/master.key` contents). |
| `PORT` | Prefer Railway’s auto value; if missing, set explicitly (e.g. **8080**) and match networking / custom domain **target port**. You may use **3000** — the script avoids Thruster/Puma port clash. |
| `TARGET_PORT` | Optional override for Puma’s internal port (default **3000** unless collision logic sets **3100**). |

Health check path is **`/up`** (see [`railway.toml`](railway.toml)). If deploys fail during first boot, check logs for **`db:prepare`** or migration errors (`bin/docker-entrypoint` runs migrations when the process is `rails server`).

### Troubleshooting

#### Railway: “Application failed to respond”

1. In **Variables**, ensure **`PORT`** is set and matches **Public Networking / custom domain target port**; deploy a build that uses **`bin/start-web`**.
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
| `/budgets` | 預算 — 與實際支出相同**上下兩區**（本月資料／登錄），**下拉選單**切換收入／支出占位內容 |
| `/revenue_budgets` | 301 重新導向至 `/budgets` |
| `/expenditure_budgets` | 301 重新導向至 `/budgets` |
| `/settings` | 設定（目前為占位頁） |

#### 版面與頁面

- **外殼：** [`app/views/layouts/application.html.erb`](app/views/layouts/application.html.erb) 以 **`RubyUI::Layout`**（[`app/components/ruby_ui/layout.rb`](app/components/ruby_ui/layout.rb)）包住內容：桌面側欄、行動版抽屜選單、flash、置中主內容欄（與常見 RubyUI／hpees 風格相同）。
- **頁面：** [`app/views/`](app/views/) 下的 Phlex 類別（例如 `Views::Dashboard::Index`、`Views::Budgets::Index`）。Zeitwerk 會將 `budgets/` 對應到 **`Views::Budgets::Index`** — 見 [`config/application.rb`](config/application.rb) 中的複數／單數設定。

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

正式環境使用 **[Thruster](https://github.com/basecamp/thruster)**：對外聽 **`HTTP_PORT`**，後面轉給 **Puma**（**`TARGET_PORT`**，預設 **3000**）。**Railway 的環境變數 `PORT` 必須等於 Thruster 對外聽的埠**；若對不起來，就會 **502 / Application failed to respond**。

**[`bin/start-web`](bin/start-web)** 會：

- 設 **`HTTP_PORT="${PORT:-8080}"`** — 若 Railway **沒有**注入 `PORT`，先預設對外 **8080**（常見 PaaS 慣例）。**建議你仍在 Railway → Variables 手動加 `PORT`**，數字要與 **Public Networking / 自訂網域的 target port** 一致（多數情況跟 Railway 自動值即可，例如 **8080**）。
- 設 **`TARGET_PORT=3000`**（Puma 在容器內）。
- **若 `PORT` 與 `TARGET_PORT` 會撞同一個 TCP 埠**（例如你手動設 **`PORT=3000`**，而 Puma 預設也想用 3000），腳本會把 **Puma 改成 3100**，避免 Thruster 與 Puma 搶同一個埠。

**`Dockerfile` / [`Procfile`](Procfile)** 都改為執行 **`bin/start-web`**。

**埠號對照（重點）：**

| 埠 | 用途 |
|------|------|
| **`PORT`（Railway Variables）** | **Thruster 對外**監聽 = `HTTP_PORT`。請與網域 **target port** 一致。若平台沒自動給，**請自己設**（常用 **8080**；設 **3000** 也可以，程式會自動避免與 Puma 撞埠）。 |
| **3000** | 多數情況下 **Puma** 在 Thruster 後面聽這裡。 |
| **3100** | ① 你強制 **`PORT=3000`** 時，**Puma** 會被改聽這裡（避開 Thruster）。② **本機**沒設 `PORT` 時，`config/puma.rb` 預設聽 **3100**。 |

**本機 3100 要不要跟 Railway 一樣？**  
**不用。** 本機只是「沒設 `PORT` 時預設 3100」方便開發；Railway 請依 **`PORT` + target port** 對齊，**不必**刻意設成 3100。

**建議在 Railway 服務變數中設定：**

| 變數 | 說明 |
|----------|--------|
| `SECRET_KEY_BASE` | 正式環境必填（可用 `bin/rails secret` 產生）。 |
| `RAILS_MASTER_KEY` | 若使用加密 credentials，請貼上 `config/master.key` 內容。 |
| `PORT` | 優先使用 Railway 自動注入；若沒有，**請手動新增**（例如 **8080**），並與 **Networking / target port** 一致。設 **3000** 時程式會自動把 Puma 改到 **3100**。 |
| `TARGET_PORT` | 選填；一般不必設，除非你要自訂 Puma 內部埠。 |

健康檢查路徑為 **`/up`**（見 [`railway.toml`](railway.toml)）。若首次部署失敗，請查看日誌是否為 **`db:prepare`** 或遷移錯誤（`bin/docker-entrypoint` 在啟動 `rails server` 時會執行資料庫準備）。

### 疑難排解

#### Railway：「Application failed to respond」

1. 在 **Variables** 確認 **`PORT`** 有值，且與 **Public Networking / 自訂網域 target port** 相同；並已部署含 **`bin/start-web`** 的版本。
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
