import { Controller } from "@hotwired/stimulus";

/** Switch 消費類別 / 支付方式 / 支付平台 panels on the settings page. */
export default class extends Controller {
  static targets = ["kindSelect", "categoryPanel", "paymentMethodPanel", "paymentPlatformPanel"];

  static values = {
    panels: { type: Object, default: {} }
  };

  connect() {
    this.sync();
  }

  sync(event) {
    const kind = this.#kindValueFrom(event);
    this.kindSelectTargets.forEach((el) => {
      if (el.value !== kind) el.value = kind;
    });

    this.categoryPanelTarget.classList.toggle("hidden", kind !== "category");
    this.paymentMethodPanelTarget.classList.toggle("hidden", kind !== "payment_method");
    this.paymentPlatformPanelTarget.classList.toggle("hidden", kind !== "payment_platform");
  }

  #kindValueFrom(event) {
    if (event?.target && this.kindSelectTargets.includes(event.target)) {
      return this.#normalizeKind(event.target.value);
    }
    const first = this.kindSelectTargets[0];
    return this.#normalizeKind(first?.value);
  }

  #normalizeKind(value) {
    if (value === "payment_method" || value === "payment_platform") return value;
    return "category";
  }
}
