import { Controller } from "@hotwired/stimulus";
import Chart from "chart.js/auto";

/** Theme tokens for slice colors (must be module-level—Stimulus scans `static` fields as value defs). */
const CHART_CSS_VARS = [
  "--chart-1",
  "--chart-2",
  "--chart-3",
  "--chart-4",
  "--chart-5",
];

/** Doughnut: 支出預算依「類別」加總占比（多張卡片即時合併），隨類別／金額欄位更新。 */
export default class extends Controller {
  static targets = ["canvas", "chartLegend"];

  connect() {
    this._recalc = () => this.recalc();
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
    if (this._themeDebounce != null) {
      clearTimeout(this._themeDebounce);
      this._themeDebounce = null;
    }
    this._chart?.destroy();
    this._chart = null;
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
    const ctx = this.canvasTarget.getContext("2d");
    this._chart = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: [],
        datasets: [
          {
            data: [],
            backgroundColor: [],
            borderColor: this.#cssColor("--border"),
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
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              label: (ctx) => {
                if (ctx.label === "尚無支出預算資料") return ` ${ctx.label}`;
                const dataset = ctx.dataset.data;
                const total = dataset.reduce((a, b) => a + Number(b), 0);
                const v = Number(ctx.raw) || 0;
                const pct =
                  total > 0 ? Math.min(100, Math.round((v / total) * 100)) : 0;
                return ` ${ctx.label}: NT$${this.#formatTwd(v)}（${pct}%）`;
              },
            },
          },
        },
      },
    });
    this.#applyChartTheme();
  }

  recalc() {
    if (!this._chart) return;

    const pairs = this.#expenditureTotalsByCategory();
    const ds = this._chart.data.datasets[0];

    if (pairs.length === 0) {
      this._chart.data.labels = ["尚無支出預算資料"];
      ds.data = [1];
      ds.backgroundColor = [this.#cssColor("--muted")];
    } else {
      this._chart.data.labels = pairs.map(([label]) => label);
      ds.data = pairs.map(([, amount]) => amount);
      ds.backgroundColor = pairs.map((_, i) =>
        this.#cssColor(CHART_CSS_VARS[i % CHART_CSS_VARS.length])
      );
    }

    this._chart.update();
    this.#syncHtmlLegend(pairs);
    this.#resizeChart();
  }

  /** HTML legend below chart: stagger alternate rows (上下交錯). */
  #syncHtmlLegend(pairs) {
    if (!this.hasChartLegendTarget) return;
    const root = this.chartLegendTarget;
    root.replaceChildren();

    if (pairs.length === 0) {
      const p = document.createElement("p");
      p.className = "text-center text-[11px] leading-snug text-muted-foreground";
      p.textContent = "尚無可畫分資料 · 請於下方「支出預算」填寫金額與類別";
      root.appendChild(p);
      return;
    }

    const wrap = document.createElement("div");
    wrap.className =
      "flex flex-wrap justify-center gap-x-3 gap-y-0.5 px-0.5 sm:gap-x-4";
    wrap.setAttribute("role", "list");

    pairs.forEach(([label, amount], i) => {
      const row = document.createElement("div");
      row.setAttribute("role", "listitem");
      const stagger =
        i % 2 === 1 ? " translate-y-1.5 sm:translate-y-2" : "";
      row.className = [
        "flex min-w-0 max-w-[15rem] items-center gap-1.5 text-left text-[11px]",
        "leading-snug text-muted-foreground",
        stagger,
      ].join(" ");

      const dot = document.createElement("span");
      dot.className =
        "h-2 w-2 shrink-0 rounded-sm ring-1 ring-border/50";
      dot.setAttribute("aria-hidden", "true");
      dot.style.backgroundColor = this.#cssColor(
        CHART_CSS_VARS[i % CHART_CSS_VARS.length]
      );

      const text = document.createElement("span");
      text.className = "min-w-0 break-words";
      const total = pairs.reduce((s, [, a]) => s + a, 0);
      const pct =
        total > 0 ? Math.min(100, Math.round((amount / total) * 100)) : 0;
      text.textContent = `${label}（${pct}%）`;

      row.appendChild(dot);
      row.appendChild(text);
      wrap.appendChild(row);
    });

    root.appendChild(wrap);
  }

  /** @returns {Array<[string, number]>} sorted by amount descending */
  #expenditureTotalsByCategory() {
    const totals = new Map();
    const forms = this.element.querySelectorAll("form");

    for (const form of forms) {
      const amountInput = form.querySelector(
        'input[name="expenditure_budget[amount]"]'
      );
      if (!amountInput) continue;

      const categorySelect = form.querySelector(
        'select[name="expenditure_budget[category]"]'
      );
      const raw = amountInput.value?.replace(/,/g, "").trim();
      if (!raw) continue;
      const n = Number.parseFloat(raw);
      if (Number.isNaN(n) || n <= 0) continue;

      let cat = categorySelect?.value?.trim() || "";
      if (cat === "") cat = "未選類別";

      totals.set(cat, (totals.get(cat) || 0) + n);
    }

    return [ ...totals.entries() ].sort((a, b) => b[1] - a[1]);
  }

  #applyChartTheme() {
    if (!this._chart) return;
    Chart.defaults.color = this.#cssColor("--muted-foreground");
    this._chart.options.plugins = this._chart.options.plugins || {};
    const tooltip = this._chart.options.plugins.tooltip || {};
    tooltip.backgroundColor = this.#cssColor("--card");
    tooltip.borderColor = this.#cssColor("--border");
    tooltip.titleColor = this.#cssColor("--foreground");
    tooltip.bodyColor = this.#cssColor("--muted-foreground");
    this._chart.update();
  }

  /** Canvas parent is in a flex/svh layout — defer resize so dimensions are non-zero. */
  #resizeChart() {
    if (!this._chart) return;
    requestAnimationFrame(() => {
      if (!this._chart) return;
      this._chart.resize();
    });
  }

  #formatTwd(n) {
    return String(Math.round(Number(n) || 0));
  }

  #cssColor(varName) {
    const v = getComputedStyle(document.documentElement)
      .getPropertyValue(varName)
      .trim();
    return v || "oklch(0.6 0 0)";
  }
}
