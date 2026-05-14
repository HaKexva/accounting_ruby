import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "paymentMethod",
    "creditCardSection",
    "creditCardPaymentMethod",
    "paymentTiming",
    "paymentPlatformSection",
    "paymentPlatform"
  ];

  connect() {
    this.sync();
  }

  paymentMethodChanged() {
    this.sync();
  }

  formReset() {
    requestAnimationFrame(() => this.sync());
  }

  sync() {
    const value = this.paymentMethodTarget.value || "";
    const showCredit = value.includes("信用卡");
    this.creditCardSectionTarget.classList.toggle("hidden", !showCredit);

    if (this.hasCreditCardPaymentMethodTarget) {
      this.creditCardPaymentMethodTarget.disabled = !showCredit;
      if (!showCredit) {
        this.creditCardPaymentMethodTarget.selectedIndex = 0;
      }
    }

    if (this.hasPaymentTimingTarget) {
      this.paymentTimingTarget.disabled = !showCredit;
      this.paymentTimingTarget.required = showCredit;
      if (!showCredit) {
        this.paymentTimingTarget.selectedIndex = 0;
      }
    }

    const showPlatform = value === "多元支付";
    this.paymentPlatformSectionTarget.classList.toggle("hidden", !showPlatform);
    if (!showPlatform && this.hasPaymentPlatformTarget) {
      this.paymentPlatformTarget.selectedIndex = 0;
    }
  }
}
