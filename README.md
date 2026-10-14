# 記帳 (accounting_ruby)

**Change Languages:** [English](#english) · [中文](#中文)

---

## English

### Features


| Area                           | What you can do                                                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| **實際支出** (`/`)                 | Log expenses with category, payment method, and optional platform; live budget/remain summary and monthly spending chart |
| **支出紀錄** (`/expenses/history`) | Browse, edit, and delete past expenditures                                                                               |
| **預算** (`/budgets`)            | Set monthly **revenue** and **expenditure** budgets (carousel cards, auto-save, allocation chart)                        |
| **設定** (`/settings`)           | Manage per-user lists: 消費類別, 支付方式, 支付平台 (used in expense forms)                                                          |


Sign in with **Google OAuth** at `/login` in production. **Local development** skips login and uses an automatic trial account (`TrialAccount`); tests use fixture users.

### Requirements

- **Ruby** 3.4.x (`[.ruby-version](.ruby-version)` — currently `ruby-3.4.8`)
- **Bundler**
- **SQLite** for local dev (`[storage/](storage/)`)
- **Node** not required — Tailwind is compiled by the `tailwindcss-rails` gem
- **PostgreSQL** gem is available if you set `DATABASE_URL` for production



### Routes


| Path                                       | Description                                          |
| ------------------------------------------ | ---------------------------------------------------- |
| `/`                                        | Dashboard — log and summarize **actual expenditure** |
| `/expenses/history`                        | Expense history (edit / delete)                      |
| `/budgets`                                 | Monthly revenue & expenditure budgets                |
| `/settings`                                | Taxonomy: categories, payment methods, platforms     |
| `/login`                                   | Sign in (Google OAuth or local trial)                |
| `/logout`                                  | Sign out (DELETE)                                    |
| `/up`                                      | Health check (used by Railway)                       |
| `/revenue_budgets`, `/expenditure_budgets` | Redirect to `/budgets`                               |




### Stack


| Piece                | Role                                                                     |
| -------------------- | ------------------------------------------------------------------------ |
| Rails 8.1            | Web framework                                                            |
| Phlex                | Ruby HTML views under `[app/views/](app/views/)`                         |
| RubyUI               | UI components under `[app/components/ruby_ui/](app/components/ruby_ui/)` |
| tailwindcss-rails    | `app/assets/tailwind/application.css` → `app/assets/builds/tailwind.css` |
| Propshaft            | Asset pipeline (`stylesheet_link_tag :app`)                              |
| Importmap + Stimulus | JavaScript controllers                                                   |




### Models (overview)


| Model                                 | Purpose                                                        |
| ------------------------------------- | -------------------------------------------------------------- |
| `User`                                | Account (Google UID + email; trial user for local dev)         |
| `CalendarMonth`                       | Global year/month bucket for budgets and expenses              |
| `ActualExpenditure`                   | Logged spending                                                |
| `RevenueBudget` / `ExpenditureBudget` | Monthly budget lines                                           |
| `ExpenditureTaxonomyItem`             | Per-user dropdown options (category, payment method, platform) |


## 中文



### 功能


| 區塊                            | 說明                                 |
| ----------------------------- | ---------------------------------- |
| **實際支出**（`/`）                 | 登錄支出（類別、支付方式、平台等）；即時預算／餘額摘要與本月支出圖表 |
| **支出紀錄**（`/expenses/history`） | 瀏覽、編輯、刪除歷史支出                       |
| **預算**（`/budgets`）            | 每月**收入**與**支出**預算（輪播卡片、自動儲存、配置圖）   |
| **設定**（`/settings`）           | 管理個人選項：消費類別、支付方式、支付平台              |


本機開發不需登入，自動使用 **試用帳號**（`TrialAccount`）；正式環境以 **Google OAuth** 登入。

### 環境需求

- **Ruby** 3.4.x（見 `[.ruby-version](.ruby-version)`）
- **Bundler**
- 本機預設 **SQLite**（`[storage/](storage/)`）
- 不必安裝 **Node** — Tailwind 由 `tailwindcss-rails` 編譯
- 正式環境可透過 `DATABASE_URL` 使用 **PostgreSQL**

### 路由


| 路徑                                        | 說明               |
| ----------------------------------------- | ---------------- |
| `/`                                       | 儀表板 — **實際支出**   |
| `/expenses/history`                       | 支出紀錄（編輯／刪除）      |
| `/budgets`                                | 收入與支出預算          |
| `/settings`                               | 消費類別、支付方式、支付平台   |
| `/up`                                     | 健康檢查（Railway 使用） |
| `/revenue_budgets`、`/expenditure_budgets` | 重新導向至 `/budgets` |


### 使用技術

| 項目                   | 說明                                                       |
| -------------------- | -------------------------------------------------------- |
| Rails 8.1            | Web 框架                                                   |
| Phlex                | Ruby 視圖 `[app/views/](app/views/)`                       |
| RubyUI               | 元件庫 `[app/components/ruby_ui/](app/components/ruby_ui/)` |
| tailwindcss-rails    | 編譯 Tailwind CSS                                          |
| Propshaft            | 靜態資源（`stylesheet_link_tag :app`）                         |
| Importmap + Stimulus | 前端互動                                                     |




### 模型（概覽）


| 模型                                    | 用途          |
| ------------------------------------- | ----------- |
| `User`                                | 使用者（本機試用帳號） |
| `CalendarMonth`                       | 依年月彙總的行事曆月份 |
| `ActualExpenditure`                   | 實際支出        |
| `RevenueBudget` / `ExpenditureBudget` | 預算列         |
| `ExpenditureTaxonomyItem`             | 個人化下拉選項     |
