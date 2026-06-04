import { Controller } from "@hotwired/stimulus";

const FORM_ID = "dashboard_actual_expenditure_form";

const FIELD_IDS = {
  category: "actual_expenditure_category",
  actual_amount: "actual_expenditure_actual_amount",
  posted_amount: "actual_expenditure_posted_amount",
};

/**
 * 依表單「消費類別」與金額欄位即時更新左側摘要：預算、類別支出、餘額。
 */
export default class extends Controller {
  static targets = ["budgetAmount", "expenseAmount", "remainAmount", "remainLabel"];

  #debounceTimer = null;
  #budgets = {};
  #spent = {};

  connect() {
    this.#budgets = this.#readJsonAttribute("budgets");
    this.#spent = this.#readJsonAttribute("spent");

    const form = this.#form();
    this._onFormChange = () => this.#scheduleRecalc();
    if (form) {
      form.addEventListener("input", this._onFormChange);
      form.addEventListener("change", this._onFormChange);
    } else {
      this.element.addEventListener("input", this._onFormChange);
      this.element.addEventListener("change", this._onFormChange);
    }

    this.recalc();
  }

  disconnect() {
    const form = this.#form();
    if (form) {
      form.removeEventListener("input", this._onFormChange);
      form.removeEventListener("change", this._onFormChange);
    } else {
      this.element.removeEventListener("input", this._onFormChange);
      this.element.removeEventListener("change", this._onFormChange);
    }
    if (this.#debounceTimer != null) {
      clearTimeout(this.#debounceTimer);
      this.#debounceTimer = null;
    }
  }

  recalc() {
    const category = this.#selectedCategory();
    if (!category) {
      this.#setDisplay(0, 0, 0, false);
      return;
    }

    const budget = this.#amountFor(this.#budgets, category);
    const saved = this.#amountFor(this.#spent, category);
    const live = this.#liveDraftAmount();
    const expense = saved + live;
    const remain = budget - expense;

    this.#setDisplay(budget, expense, remain, true);
  }

  applySpent(event) {
    const next = event.detail?.by_category;
    if (!next || typeof next !== "object") return;
    this.#spent = this.#normalizeAmountMap(next);
    this.recalc();
  }

  #readJsonAttribute(name) {
    const attr = `data-${this.identifier}-${name}-value`;
    const raw = this.element.getAttribute(attr);
    if (!raw) return {};
    try {
      const parsed = JSON.parse(raw);
      return this.#normalizeAmountMap(parsed);
    } catch {
      return {};
    }
  }

  #normalizeAmountMap(obj) {
    const out = {};
    Object.entries(obj || {}).forEach(([key, value]) => {
      const n = Number(value);
      out[key] = Number.isFinite(n) ? n : 0;
    });
    return out;
  }

  #amountFor(map, category) {
    if (map[category] != null) return Number(map[category]) || 0;
    return 0;
  }

  #scheduleRecalc() {
    if (this.#debounceTimer != null) clearTimeout(this.#debounceTimer);
    this.#debounceTimer = window.setTimeout(() => {
      this.#debounceTimer = null;
      this.recalc();
    }, 150);
  }

  #form() {
    return document.getElementById(FORM_ID);
  }

  #field(suffix) {
    const id = FIELD_IDS[suffix];
    if (id) {
      const byId = document.getElementById(id);
      if (byId) return byId;
    }
    const form = this.#form();
    if (!form) return null;
    return form.elements.namedItem(`actual_expenditure[${suffix}]`);
  }

  #selectedCategory() {
    const el = this.#field("category");
    return el?.value?.trim() || "";
  }

  #liveDraftAmount() {
    const postedEl = this.#field("posted_amount");
    const actualEl = this.#field("actual_amount");
    // 列帳為主；尚未填列帳時用實際消費金額預覽左側「支出／餘額」。
    if (postedEl?.value?.trim()) return this.#parseAmountEl(postedEl);
    if (actualEl?.value?.trim()) return this.#parseAmountEl(actualEl);
    return 0;
  }

  #parseAmountEl(el) {
    if (!el?.value) return 0;
    const n = parseFloat(String(el.value).replace(/,/g, ""));
    return Number.isFinite(n) ? n : 0;
  }

  #setDisplay(budget, expense, remain, hasCategory) {
    const fmt = (n) => this.#formatTwd(n);

    // Desktop + mobile both declare these targets; update every match (singular Target is first in DOM only).
    this.budgetAmountTargets.forEach((el) => {
      el.textContent = hasCategory ? fmt(budget) : fmt(0);
    });
    this.expenseAmountTargets.forEach((el) => {
      el.textContent = hasCategory ? fmt(expense) : fmt(0);
    });
    this.remainAmountTargets.forEach((el) => {
      el.textContent = hasCategory ? fmt(remain) : fmt(0);
      el.classList.remove("text-emerald-600", "dark:text-emerald-400", "text-destructive");
      if (hasCategory) {
        if (remain > 0) {
          el.classList.add("text-emerald-600", "dark:text-emerald-400");
        } else if (remain < 0) {
          el.classList.add("text-destructive");
        }
      }
    });
    this.remainLabelTargets.forEach((el) => {
      el.textContent = "餘額";
    });
  }

  #formatTwd(n) {
    const v = Math.round(Number(n) || 0);
    return `NT$${v.toLocaleString("zh-TW")}`;
  }
}
