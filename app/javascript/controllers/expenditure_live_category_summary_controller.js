import { Controller } from "@hotwired/stimulus";

const FORM_ID = "dashboard_actual_expenditure_form";

/**
 * 依表單「消費類別」與「列帳金額」即時更新左側摘要：預算、類別支出、餘額。
 */
export default class extends Controller {
  static targets = ["budgetAmount", "expenseAmount", "remainAmount", "remainLabel"];

  static values = {
    budgets: Object,
    spent: Object,
  };

  connect() {
    this.#debounceTimer = null;
    this.#onFormChange = (event) => {
      if (!this.#isDashboardFormEvent(event)) return;
      this.#scheduleRecalc();
    };
    this.element.addEventListener("input", this.#onFormChange);
    this.element.addEventListener("change", this.#onFormChange);
    this.recalc();
  }

  disconnect() {
    this.element.removeEventListener("input", this.#onFormChange);
    this.element.removeEventListener("change", this.#onFormChange);
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

    const budget = Number(this.budgetsValue[category]) || 0;
    const saved = Number(this.spentValue[category]) || 0;
    const live = this.#livePostedAmount();
    const expense = saved + live;
    const remain = budget - expense;

    this.#setDisplay(budget, expense, remain, true);
  }

  applySpent(event) {
    const next = event.detail?.by_category;
    if (!next || typeof next !== "object") return;
    this.spentValue = { ...next };
    this.recalc();
  }

  #scheduleRecalc() {
    if (this.#debounceTimer != null) clearTimeout(this.#debounceTimer);
    this.#debounceTimer = window.setTimeout(() => {
      this.#debounceTimer = null;
      this.recalc();
    }, 150);
  }

  #isDashboardFormEvent(event) {
    const form = this.#form();
    if (!form || !event.target) return false;
    return form.contains(event.target);
  }

  #form() {
    return this.element.querySelector(`#${FORM_ID}`);
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

  #setDisplay(budget, expense, remain, hasCategory) {
    const fmt = (n) => this.#formatTwd(n);

    if (this.hasBudgetAmountTarget) {
      this.budgetAmountTarget.textContent = hasCategory ? fmt(budget) : fmt(0);
    }
    if (this.hasExpenseAmountTarget) {
      this.expenseAmountTarget.textContent = hasCategory ? fmt(expense) : fmt(0);
    }
    if (this.hasRemainAmountTarget) {
      this.remainAmountTarget.textContent = hasCategory ? fmt(remain) : fmt(0);
      this.remainAmountTarget.classList.remove(
        "text-emerald-600",
        "dark:text-emerald-400",
        "text-destructive"
      );
      if (hasCategory) {
        if (remain > 0) {
          this.remainAmountTarget.classList.add("text-emerald-600", "dark:text-emerald-400");
        } else if (remain < 0) {
          this.remainAmountTarget.classList.add("text-destructive");
        }
      }
    }
    if (this.hasRemainLabelTarget) {
      this.remainLabelTarget.textContent = "餘額";
    }
  }

  #formatTwd(n) {
    const v = Math.round(Number(n) || 0);
    return `NT$${v.toLocaleString("zh-TW")}`;
  }
}
