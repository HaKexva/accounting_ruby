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
    if (this.hasPaymentMethodTarget) this.sync();
  }

  paymentMethodChanged() {
    this.sync();
  }

  formReset() {
    requestAnimationFrame(() => this.sync());
  }

  /**
   * @param {{ preserveDependent?: boolean }} [options]
   *   preserveDependent: keep信用卡／多元支付子欄位已選值（歷史紀錄編輯帶入時用）
   */
  sync(options = {}) {
    if (!this.hasPaymentMethodTarget) return;

    const preserve = options.preserveDependent === true;
    const value = this.paymentMethodTarget.value || "";
    const showCredit = value.includes("信用卡");
    if (this.hasCreditCardSectionTarget) {
      this.creditCardSectionTarget.classList.toggle("hidden", !showCredit);
    }

    if (this.hasCreditCardPaymentMethodTarget) {
      this.creditCardPaymentMethodTarget.disabled = !showCredit;
      this.creditCardPaymentMethodTarget.required = showCredit;
      if (!showCredit && !preserve) {
        this.creditCardPaymentMethodTarget.selectedIndex = 0;
      }
    }

    if (this.hasPaymentTimingTarget) {
      this.paymentTimingTarget.disabled = !showCredit;
      this.paymentTimingTarget.required = showCredit;
      if (!showCredit && !preserve) {
        this.paymentTimingTarget.selectedIndex = 0;
      }
    }

    const showPlatform = value === "多元支付";
    if (this.hasPaymentPlatformSectionTarget) {
      this.paymentPlatformSectionTarget.classList.toggle("hidden", !showPlatform);
    }
    if (this.hasPaymentPlatformTarget) {
      this.paymentPlatformTarget.disabled = !showPlatform;
      this.paymentPlatformTarget.required = showPlatform;
      if (!showPlatform && !preserve) {
        this.paymentPlatformTarget.selectedIndex = 0;
      }
    }
  }
}
