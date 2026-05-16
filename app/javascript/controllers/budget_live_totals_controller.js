import { Controller } from "@hotwired/stimulus";

/** Live-update 本月預算合計 from all income / expense amount fields while typing. */
export default class extends Controller {
  static targets = ["revenueTotal", "expenditureTotal", "netTotal", "revenueCount", "expenditureCount"];

  connect() {
    this._recalc = () => this.recalc();
    this.element.addEventListener("input", this._recalc);
    this.element.addEventListener("change", this._recalc);
    this.recalc();
  }

  disconnect() {
    this.element.removeEventListener("input", this._recalc);
    this.element.removeEventListener("change", this._recalc);
  }

  recalc() {
    const revInputs = this.element.querySelectorAll('input[name="revenue_budget[amount]"]');
    const expInputs = this.element.querySelectorAll('input[name="expenditure_budget[amount]"]');

    const revSum = this.#sumInputs(revInputs);
    const expSum = this.#sumInputs(expInputs);

    if (this.hasRevenueTotalTarget) {
      this.revenueTotalTarget.textContent = `NT$${this.#formatTwd(revSum)}`;
    }
    if (this.hasExpenditureTotalTarget) {
      this.expenditureTotalTarget.textContent = `NT$${this.#formatTwd(expSum)}`;
    }
    if (this.hasNetTotalTarget) {
      this.netTotalTarget.textContent = `NT$${this.#formatTwd(revSum - expSum)}`;
    }
    if (this.hasRevenueCountTarget) {
      this.revenueCountTarget.textContent = `${revInputs.length} 筆`;
    }
    if (this.hasExpenditureCountTarget) {
      this.expenditureCountTarget.textContent = `${expInputs.length} 筆`;
    }
  }

  #sumInputs(inputs) {
    let sum = 0;
    inputs.forEach((input) => {
      const raw = input.value?.replace(/,/g, "").trim();
      if (!raw) return;
      const n = Number.parseFloat(raw);
      if (!Number.isNaN(n)) sum += n;
    });
    return sum;
  }

  #formatTwd(n) {
    return String(Math.round(n));
  }
}
