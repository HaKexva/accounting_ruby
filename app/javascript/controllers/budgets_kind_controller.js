import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "kindSelect",
    "revenueSummary",
    "expenditureSummary",
    "revenueEntry",
    "expenditureEntry"
  ];

  connect() {
    this.sync();
  }

  sync() {
    const showRevenue = this.kindSelectTarget.value === "revenue";
    this.revenueSummaryTarget.classList.toggle("hidden", !showRevenue);
    this.expenditureSummaryTarget.classList.toggle("hidden", showRevenue);
    this.revenueEntryTarget.classList.toggle("hidden", !showRevenue);
    this.expenditureEntryTarget.classList.toggle("hidden", showRevenue);
  }
}
