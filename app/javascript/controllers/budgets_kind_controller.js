import { Controller } from "@hotwired/stimulus";

/** Switch 收入 / 支出 budget panels (pill segment control, like settings taxonomy). */
export default class extends Controller {
  static targets = ["kindSelect", "kindButton", "revenuePanel", "expenditurePanel"];

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
    const value = this.#kindValueFrom(event);

    if (this.hasKindSelectTarget && this.kindSelectTarget.value !== value) {
      this.kindSelectTarget.value = value;
    }

    const showRevenue = value === "revenue";
    this.revenuePanelTarget.classList.toggle("hidden", !showRevenue);
    this.expenditurePanelTarget.classList.toggle("hidden", showRevenue);

    this.kindButtonTargets.forEach((button) => {
      const active = button.dataset.kindValue === value;
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
    return value === "expenditure" ? "expenditure" : "revenue";
  }
}
