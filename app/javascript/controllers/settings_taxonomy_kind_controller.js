import { Controller } from "@hotwired/stimulus";

/** Switch 消費類別 / 支付方式 / 支付平台 panels on the settings page. */
export default class extends Controller {
  static targets = [
    "kindSelect",
    "kindButton",
    "categoryPanel",
    "paymentMethodPanel",
    "paymentPlatformPanel"
  ];

  connect() {
    this.sync();
  }

  pickKind(event) {
    const kind = event.currentTarget.dataset.kindValue;
    if (!kind) return;

    if (this.hasKindSelectTarget) {
      this.kindSelectTarget.value = kind;
    }
    this.sync();
  }

  sync(event) {
    const kind = this.#kindValueFrom(event);

    if (this.hasKindSelectTarget && this.kindSelectTarget.value !== kind) {
      this.kindSelectTarget.value = kind;
    }

    this.categoryPanelTarget.classList.toggle("hidden", kind !== "category");
    this.paymentMethodPanelTarget.classList.toggle("hidden", kind !== "payment_method");
    this.paymentPlatformPanelTarget.classList.toggle("hidden", kind !== "payment_platform");

    this.kindButtonTargets.forEach((button) => {
      const active = button.dataset.kindValue === kind;
      button.setAttribute("aria-pressed", active ? "true" : "false");
      button.classList.toggle("bg-card", active);
      button.classList.toggle("text-foreground", active);
      button.classList.toggle("shadow-sm", active);
      button.classList.toggle("ring-1", active);
      button.classList.toggle("ring-border/60", active);
      button.classList.toggle("text-muted-foreground", !active);
    });
  }

  #kindValueFrom(event) {
    if (event?.currentTarget?.dataset?.kindValue) {
      return this.#normalizeKind(event.currentTarget.dataset.kindValue);
    }
    if (event?.target === this.kindSelectTarget) {
      return this.#normalizeKind(event.target.value);
    }
    return this.#normalizeKind(this.kindSelectTarget?.value);
  }

  #normalizeKind(value) {
    if (value === "payment_method" || value === "payment_platform") return value;
    return "category";
  }
}
