import { Controller } from "@hotwired/stimulus";

/** Switch 收入 / 支出 panels; syncs duplicate kind <select>s inside each card toolbar. */
export default class extends Controller {
  static targets = ["kindSelect", "revenuePanel", "expenditurePanel"];

  connect() {
    this.sync();
  }

  sync(event) {
    const value = this.#kindValueFrom(event);
    this.kindSelectTargets.forEach((el) => {
      if (el.value !== value) el.value = value;
    });
    const showRevenue = value === "revenue";
    this.revenuePanelTarget.classList.toggle("hidden", !showRevenue);
    this.expenditurePanelTarget.classList.toggle("hidden", showRevenue);
  }

  #kindValueFrom(event) {
    if (event?.target && this.kindSelectTargets.includes(event.target)) {
      return event.target.value === "expenditure" ? "expenditure" : "revenue";
    }
    const first = this.kindSelectTargets[0];
    return first?.value === "expenditure" ? "expenditure" : "revenue";
  }
}
