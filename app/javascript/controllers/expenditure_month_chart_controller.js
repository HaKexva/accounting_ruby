import { Controller } from "@hotwired/stimulus";
import Chart from "chart.js/auto";

const CHART_CSS_VARS = [
  "--chart-1",
  "--chart-2",
  "--chart-3",
  "--chart-4",
  "--chart-5",
];

const BUDGET_SURPLUS_LABEL = "預算收入－預算支出";

/** 本月消費支出結構：各類淺色＝尚未使用預算、相鄰深色＝已使用；另含預算結餘。 */
export default class extends Controller {
  static targets = ["canvas", "chartLegend"];

  static values = {
    categories: Object,
    budgets: Object,
    revenueTotal: Number,
    categoryOrder: Array,
  };

  connect() {
    this._spent = { ...this.categoriesValue };
    this._percentBase = 1;
    this._sliceMeta = [];
    this._recalc = () => this.#scheduleRecalc();
    this._themeDebounce = null;
    this.element.addEventListener("input", this._recalc);
    this.element.addEventListener("change", this._recalc);
    this.initDarkModeObserver();
    this.initChart();
    this.recalc();
    this.#resizeChart();
  }

  disconnect() {
    this.element.removeEventListener("input", this._recalc);
    this.element.removeEventListener("change", this._recalc);
    this.darkModeObserver?.disconnect();
    if (this._debounceTimer != null) {
      clearTimeout(this._debounceTimer);
      this._debounceTimer = null;
    }
    if (this._themeDebounce != null) {
      clearTimeout(this._themeDebounce);
      this._themeDebounce = null;
    }
    this._chart?.destroy();
    this._chart = null;
  }

  applyTally(event) {
    const next = event.detail?.by_category;
    if (!next || typeof next !== "object") return;
    this._spent = { ...next };
    this.recalc();
    this.#resizeChart();
  }

  #scheduleRecalc() {
    if (this._debounceTimer != null) clearTimeout(this._debounceTimer);
    this._debounceTimer = window.setTimeout(() => {
      this._debounceTimer = null;
      this.recalc();
    }, 150);
  }

  initDarkModeObserver() {
    this.darkModeObserver = new MutationObserver(() => {
      if (this._themeDebounce != null) clearTimeout(this._themeDebounce);
      this._themeDebounce = window.setTimeout(() => {
        this._themeDebounce = null;
        if (!this.isConnected) return;
        this._chart?.destroy();
        this._chart = null;
        this.initChart();
        this.recalc();
        this.#resizeChart();
      }, 30);
    });
    this.darkModeObserver.observe(document.documentElement, {
      attributeFilter: ["class"],
    });
  }

  initChart() {
    Chart.defaults.color = this.#cssColor("--muted-foreground");
    const tooltipTheme = {
      backgroundColor: this.#cssColor("--card"),
      borderColor: this.#cssColor("--border"),
      titleColor: this.#cssColor("--foreground"),
      bodyColor: this.#cssColor("--muted-foreground"),
    };
    const border = this.#cssColor("--border");
    const ctx = this.canvasTarget.getContext("2d");
    this._chart = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: [],
        datasets: [
          {
            data: [],
            backgroundColor: [],
            borderColor: border,
            borderWidth: 1,
            hoverOffset: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        cutout: "58%",
        plugins: {
          legend: { display: false },
          tooltip: {
            ...tooltipTheme,
            filter: (item) => Number(item.raw) > 0,
            callbacks: {
              title: (items) => {
                const meta = this._sliceMeta[items[0]?.dataIndex];
                return meta?.category || items[0]?.label || "";
              },
              label: (ctx) => {
                if (ctx.label === "尚無可畫分資料") return ` ${ctx.label}`;
                const meta = this._sliceMeta[ctx.dataIndex];
                const v = Number(ctx.raw) || 0;
                const base = this._percentBase > 0 ? this._percentBase : 1;
                const pct = Math.min(100, Math.round((v / base) * 100));
                const role =
                  meta?.role === "used"
                    ? "已使用"
                    : meta?.role === "unused"
                      ? "尚未使用"
                      : meta?.role === "surplus"
                        ? BUDGET_SURPLUS_LABEL
                        : ctx.label;
                return ` ${role}: NT$${this.#formatTwd(v)}（${pct}%）`;
              },
            },
          },
        },
      },
    });
  }

  recalc() {
    if (!this._chart) return;

    const spent = this.#spentByCategory();
    const budgets = this.budgetsValue || {};
    const revenueBudget = Number(this.revenueTotalValue) || 0;
    const expenditureBudget = Object.values(budgets).reduce(
      (s, v) => s + (Number(v) || 0),
      0
    );
    const budgetSurplus = Math.max(0, revenueBudget - expenditureBudget);

    const { labels, data, colors, legendRows, sliceMeta } = this.#buildSeries({
      budgets,
      spent,
      budgetSurplus,
      revenueBudget,
    });

    this._sliceMeta = sliceMeta;

    const sliceSum = data.reduce((s, v) => s + v, 0);
    this._percentBase =
      revenueBudget > 0 ? revenueBudget : sliceSum > 0 ? sliceSum : 1;

    const ds = this._chart.data.datasets[0];

    if (labels.length === 0) {
      this._chart.data.labels = ["尚無可畫分資料"];
      this._sliceMeta = [{ role: "empty", category: "" }];
      ds.data = [1];
      ds.backgroundColor = [this.#cssColor("--muted")];
    } else {
      this._chart.data.labels = labels;
      ds.data = data;
      ds.backgroundColor = colors;
    }

    this._chart.update();
    this.#syncHtmlLegend(legendRows);
    this.#resizeChart();
  }

  /**
   * 每類別：先淺色扇區（尚未使用），再緊接深色扇區（已使用，視覺上疊在該類預算區塊）。
   */
  #buildSeries({ budgets, spent, budgetSurplus, revenueBudget }) {
    const labels = [];
    const data = [];
    const colors = [];
    const sliceMeta = [];
    const legendRows = [];

    const categoryRows = this.#categoryRows(budgets, spent);
    const unknownCategories = this.#unknownCategories(
      categoryRows.map((r) => r.category)
    );

    categoryRows.forEach((row) => {
      const { darkColor, lightColor } = this.#colorsForCategory(
        row.category,
        unknownCategories
      );

      if (row.unused > 0) {
        labels.push(row.category);
        data.push(row.unused);
        colors.push(lightColor);
        sliceMeta.push({
          category: row.category,
          role: "unused",
        });
      }

      if (row.spent > 0) {
        labels.push(row.category);
        data.push(row.spent);
        colors.push(darkColor);
        sliceMeta.push({
          category: row.category,
          role: "used",
        });
      }

      legendRows.push({
        label: row.category,
        spent: row.spent,
        unused: row.unused,
        darkColor,
        lightColor,
      });
    });

    if (revenueBudget > 0 && budgetSurplus > 0) {
      labels.push(BUDGET_SURPLUS_LABEL);
      data.push(budgetSurplus);
      colors.push(this.#cssColor("--muted"));
      sliceMeta.push({ category: BUDGET_SURPLUS_LABEL, role: "surplus" });
      legendRows.push({
        label: BUDGET_SURPLUS_LABEL,
        spent: 0,
        unused: budgetSurplus,
        surplus: true,
        lightColor: this.#cssColor("--muted"),
        darkColor: null,
      });
    }

    return { labels, data, colors, legendRows, sliceMeta };
  }

  #categoryRows(budgets, spent) {
    const cats = new Set([...Object.keys(budgets), ...Object.keys(spent)]);
    const rows = [];

    cats.forEach((category) => {
      const budget = Number(budgets[category]) || 0;
      const used = Number(spent[category]) || 0;
      const unused = Math.max(0, budget - used);
      const total = unused + used;
      if (total <= 0) return;
      rows.push({ category, budget, spent: used, unused, total });
    });

    const unknown = this.#unknownCategories(rows.map((r) => r.category));
    return rows.sort(
      (a, b) =>
        this.#categoryColorIndex(a.category, unknown) -
        this.#categoryColorIndex(b.category, unknown)
    );
  }

  #unknownCategories(activeNames) {
    const order = this.categoryOrderValue || [];
    return [...new Set(activeNames)]
      .filter((c) => !order.includes(c))
      .sort((a, b) => a.localeCompare(b, "zh-Hant"));
  }

  /** 固定依 ExpenditureTaxonomy::CATEGORIES 順序與配色（不依金額排序）。 */
  #categoryColorIndex(category, unknownCategories = []) {
    const order = this.categoryOrderValue || [];
    const idx = order.indexOf(category);
    if (idx >= 0) return idx;
    return order.length + unknownCategories.indexOf(category);
  }

  #colorsForCategory(category, unknownCategories) {
    const colorIdx = this.#categoryColorIndex(category, unknownCategories);
    const chartVar = CHART_CSS_VARS[colorIdx % CHART_CSS_VARS.length];
    const base = this.#cssColor(chartVar);
    return {
      darkColor: this.#usedSliceColor(base),
      lightColor: this.#unusedSliceColor(base),
    };
  }

  #spentByCategory() {
    const totals = { ...this._spent };
    const cat = this.#selectedCategory();
    if (cat) {
      const saved = Number(totals[cat]) || 0;
      totals[cat] = saved + this.#livePostedAmount();
    }
    return totals;
  }

  #form() {
    return this.element.querySelector("#dashboard_actual_expenditure_form");
  }

  #field(suffix) {
    const form = this.#form();
    if (!form) return null;
    return form.elements.namedItem(`actual_expenditure[${suffix}]`);
  }

  #selectedCategory() {
    const el = this.#field("category");
    return el?.value?.trim() || "";
  }

  #livePostedAmount() {
    const el = this.#field("posted_amount");
    if (!el?.value) return 0;
    const n = parseFloat(String(el.value).replace(/,/g, ""));
    return Number.isFinite(n) ? n : 0;
  }

  #syncHtmlLegend(rows) {
    if (!this.hasChartLegendTarget) return;
    const root = this.chartLegendTarget;
    root.replaceChildren();

    if (rows.length === 0) {
      const p = document.createElement("p");
      p.className =
        "text-center text-[11px] leading-snug text-muted-foreground";
      p.textContent =
        "尚無可畫分資料 · 請於預算頁設定收入／支出預算，或登錄實際支出";
      root.appendChild(p);
      return;
    }

    const base = this._percentBase > 0 ? this._percentBase : 1;
    const wrap = document.createElement("div");
    wrap.className = "flex w-full flex-col gap-2";
    wrap.setAttribute("role", "list");

    const roleKey = this.#roleLegendKey();
    if (roleKey) wrap.appendChild(roleKey);

    rows.forEach((row) => {
      const el = document.createElement("div");
      el.setAttribute("role", "listitem");
      el.className = "flex items-start gap-2";

      const swatch = document.createElement("span");
      swatch.className =
        "relative mt-0.5 h-2.5 w-3 shrink-0 overflow-hidden rounded-sm ring-1 ring-border/50";
      swatch.setAttribute("aria-hidden", "true");

      const light = document.createElement("span");
      light.className = "absolute inset-0";
      light.style.backgroundColor = row.lightColor;
      swatch.appendChild(light);

      if (row.spent > 0 && row.darkColor) {
        const dark = document.createElement("span");
        dark.className = "absolute inset-y-0 right-0";
        const total = row.spent + row.unused;
        const usedPct = total > 0 ? (row.spent / total) * 100 : 100;
        dark.style.width = `${usedPct}%`;
        dark.style.backgroundColor = row.darkColor;
        swatch.appendChild(dark);
      }

      const body = document.createElement("div");
      body.className =
        "grid min-w-0 flex-1 grid-cols-[minmax(0,1fr)_auto] items-start gap-x-3 gap-y-0.5";

      const label = document.createElement("span");
      label.className =
        "min-w-0 text-[11px] leading-snug text-foreground/90 sm:text-xs";
      label.textContent = row.label;

      const meta = document.createElement("div");
      meta.className = "text-right leading-tight";

      const total = row.spent + row.unused;
      const pct = Math.min(100, Math.round((total / base) * 100));

      const pctEl = document.createElement("span");
      pctEl.className =
        "block text-[11px] font-medium tabular-nums text-foreground sm:text-xs";
      pctEl.textContent = `${pct}%`;

      const detailEl = document.createElement("span");
      detailEl.className =
        "mt-0.5 block whitespace-nowrap text-[10px] tabular-nums text-muted-foreground sm:text-[11px]";
      detailEl.textContent = this.#legendDetailText(row);

      meta.appendChild(pctEl);
      if (detailEl.textContent) meta.appendChild(detailEl);

      body.appendChild(label);
      body.appendChild(meta);
      el.appendChild(swatch);
      el.appendChild(body);
      wrap.appendChild(el);
    });

    root.appendChild(wrap);
  }

  #legendDetailText(row) {
    if (row.surplus) return "";

    if (row.spent > 0 && row.unused > 0) {
      return `已用 ${this.#formatTwd(row.spent)} · 未用 ${this.#formatTwd(row.unused)}`;
    }
    if (row.spent > 0) return `已用 ${this.#formatTwd(row.spent)}`;
    if (row.unused > 0) return `未用 ${this.#formatTwd(row.unused)}`;
    return "";
  }

  #resizeChart() {
    if (!this._chart) return;
    requestAnimationFrame(() => {
      if (!this._chart) return;
      this._chart.resize();
    });
  }

  #formatTwd(n) {
    const v = Math.round(Number(n) || 0);
    return `NT$${v.toLocaleString("zh-TW")}`;
  }

  /** 尚未使用：同色系淺色（與背景混合，保留色相）。 */
  #unusedSliceColor(base) {
    const surface = this.#cssColor("--card");
    return this.#colorMix(base, surface, 28);
  }

  /** 已使用：同色系深色（飽和原色，與淺色區塊對比）。 */
  #usedSliceColor(base) {
    return this.#colorMix(base, base, 100);
  }

  #colorMix(colorA, colorB, percentA) {
    if (
      typeof CSS !== "undefined" &&
      CSS.supports("color", "color-mix(in oklch, red, blue)")
    ) {
      const b = 100 - percentA;
      return `color-mix(in oklch, ${colorA} ${percentA}%, ${colorB} ${b}%)`;
    }
    return colorA;
  }

  #roleLegendKey() {
    const sample = this.#cssColor("--chart-2");
    const unused = this.#unusedSliceColor(sample);
    const used = this.#usedSliceColor(sample);

    const key = document.createElement("div");
    key.className =
      "mb-1 flex flex-wrap items-center justify-center gap-x-4 gap-y-1 border-b border-border/40 pb-2 text-[10px] text-muted-foreground sm:text-[11px]";
    key.setAttribute("aria-hidden", "true");

    [ ["尚未使用", unused], ["已使用", used] ].forEach(([label, bg]) => {
      const item = document.createElement("span");
      item.className = "inline-flex items-center gap-1.5";
      const sw = document.createElement("span");
      sw.className = "h-2.5 w-3 shrink-0 rounded-sm ring-1 ring-border/50";
      sw.style.backgroundColor = bg;
      item.appendChild(sw);
      item.appendChild(document.createTextNode(label));
      key.appendChild(item);
    });

    return key;
  }

  #cssColor(varName) {
    const v = getComputedStyle(document.documentElement)
      .getPropertyValue(varName)
      .trim();
    return v || "oklch(0.6 0 0)";
  }
}
