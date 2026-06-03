import { Controller } from "@hotwired/stimulus";

/** POST 實際支出（JSON），更新本月摘要與圓餅圖。 */
export default class extends Controller {
  static targets = ["mainForm", "status", "monthCount", "monthTotal"];

  connect() {
    this.mainFormTarget.addEventListener("submit", this.#handleSubmit);
  }

  disconnect() {
    this.mainFormTarget.removeEventListener("submit", this.#handleSubmit);
  }

  #handleSubmit = async (ev) => {
    ev.preventDefault();
    const form = this.mainFormTarget;
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }

    this.#setStatus("儲存中…");
    const token = document.querySelector('meta[name="csrf-token"]')?.content;

    try {
      const res = await fetch(form.action, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": token ?? "",
          "X-Requested-With": "XMLHttpRequest",
        },
        body: new FormData(form),
      });
      const json = await res.json().catch(() => ({}));

      if (!res.ok || !json.ok) {
        const msg = Array.isArray(json.errors)
          ? json.errors.join(" ")
          : json.error || "無法儲存";
        this.#setStatus(msg);
        return;
      }

      this.#applyMonthTally(json.month_tally);
      form.reset();
      form.dispatchEvent(new Event("reset", { bubbles: true }));
      this.#setStatus("已儲存");
      window.setTimeout(() => {
        if (this.hasStatusTarget) this.#setStatus("");
      }, 2200);

      this.dispatch("success", {
        prefix: "actual-expenditure-form",
        bubbles: true,
        detail: {
          by_category: json.month_tally?.by_category ?? {},
          month_tally: json.month_tally ?? null,
        },
      });
    } catch {
      this.#setStatus("連線失敗");
    }
  };

  #applyMonthTally(tally) {
    if (!tally) return;
    const count = Number(tally.count) || 0;
    if (this.hasMonthCountTarget) {
      this.monthCountTarget.textContent = `${count} 筆`;
    }
    const total = Number(tally.total) || 0;
    this.#applyMonthTotal(total);
  }

  #applyMonthTotal(total) {
    const formatted = this.#formatTwd(total);
    if (this.hasMonthTotalTarget) {
      this.monthTotalTargets.forEach((el) => {
        el.textContent = formatted;
      });
      return;
    }
    const fallback = document.getElementById("dashboard_month_total");
    if (fallback) fallback.textContent = formatted;
  }

  #formatTwd(n) {
    const v = Math.round(Number(n) || 0);
    return `NT$${v.toLocaleString("zh-TW")}`;
  }

  #setStatus(text) {
    if (!this.hasStatusTarget) return;
    const t = text ?? "";
    this.statusTarget.textContent = t;
    this.statusTarget.classList.toggle("hidden", !t);
  }
}
