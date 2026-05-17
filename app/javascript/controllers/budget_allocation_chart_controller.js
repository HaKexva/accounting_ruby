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

/** Doughnut: 支出依「類別」加總 + 未使用收入（收入合計 − 支出合計），與表單即時連動。 */
export default class extends Controller {
  static targets = ["canvas", "chartLegend"];

  connect() {
    this._percentBase = 1;
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
    // Chart.js v4 wraps `chart.options` in Proxies. Do not assign whole branches
    // like `chart.options.plugins = {}` after construction — that can recurse
    // between resolver proxies (helpers.config) and blow the stack.
    Chart.defaults.color = this.#cssColor("--muted-foreground");
    const tooltipTheme = {
      backgroundColor: this.#cssColor("--card"),
      borderColor: this.#cssColor("--border"),
      titleColor: this.#cssColor("--foreground"),
      bodyColor: this.#cssColor("--muted-foreground"),
    };
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
            ...tooltipTheme,
            callbacks: {
              label: (ctx) => {
                if (ctx.label === "尚無預算資料") return ` ${ctx.label}`;
                const v = Number(ctx.raw) || 0;
                const base = this._percentBase > 0 ? this._percentBase : 1;
                const pct = Math.min(100, Math.round((v / base) * 100));
                return ` ${ctx.label}: NT$${this.#formatTwd(v)}（${pct}%）`;
              },
            },
          },
        },
      },
    });
  }

  recalc() {
    if (!this._chart) return;

    const revenue = this.#revenueTotal();
    const expPairs = this.#expenditureTotalsByCategory();
    const expTotal = expPairs.reduce((s, [, a]) => s + a, 0);
    const unused = Math.max(0, revenue - expTotal);

    const series = [ ...expPairs ];
    if (unused > 0) {
      series.push([ "未使用收入", unused ]);
    }

    const sliceSum = series.reduce((s, [, a]) => s + a, 0);
    this._percentBase = revenue > 0 ? revenue : (sliceSum > 0 ? sliceSum : 1);

    const ds = this._chart.data.datasets[0];

    if (series.length === 0) {
      this._chart.data.labels = [ "尚無預算資料" ];
      ds.data = [ 1 ];
      ds.backgroundColor = [ this.#cssColor("--muted") ];
    } else {
      this._chart.data.labels = series.map(([label]) => label);
      ds.data = series.map(([, amount]) => amount);
      let colorIdx = 0;
      ds.backgroundColor = series.map(([label]) => {
        if (label === "未使用收入") {
          return this.#cssColor("--muted");
        }
        const c = this.#cssColor(
          CHART_CSS_VARS[colorIdx % CHART_CSS_VARS.length]
        );
        colorIdx += 1;
        return c;
      });
    }

    this._chart.update();
    this.#syncHtmlLegend(series);
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
      p.textContent =
        "尚無可畫分資料 · 請於下方填寫「收入預算」或「支出預算」金額（支出請選類別）";
      root.appendChild(p);
      return;
    }

    const base =
      this._percentBase > 0 ? this._percentBase : 1;

    const wrap = document.createElement("div");
    wrap.className =
      "flex flex-wrap justify-center gap-x-3 gap-y-0.5 px-0.5 sm:gap-x-4";
    wrap.setAttribute("role", "list");

    let colorIdx = 0;
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
      if (label === "未使用收入") {
        dot.style.backgroundColor = this.#cssColor("--muted");
      } else {
        dot.style.backgroundColor = this.#cssColor(
          CHART_CSS_VARS[colorIdx % CHART_CSS_VARS.length]
        );
        colorIdx += 1;
      }

      const text = document.createElement("span");
      text.className = "min-w-0 break-words";
      const pct = Math.min(100, Math.round((amount / base) * 100));
      text.textContent = `${label}（${pct}%）`;

      row.appendChild(dot);
      row.appendChild(text);
      wrap.appendChild(row);
    });

    root.appendChild(wrap);
  }

  #revenueTotal() {
    let sum = 0;
    const forms = this.element.querySelectorAll("form");

    for (const form of forms) {
      const amountInput = form.querySelector(
        'input[name="revenue_budget[amount]"]'
      );
      if (!amountInput) continue;

      const raw = amountInput.value?.replace(/,/g, "").trim();
      if (!raw) continue;
      const n = Number.parseFloat(raw);
      if (Number.isNaN(n) || n <= 0) continue;

      sum += n;
    }
    return sum;
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
