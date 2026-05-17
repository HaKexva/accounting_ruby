import { Controller } from "@hotwired/stimulus";

/** 歷史紀錄列表：編輯（modal）與刪除（點擊委派，避免 Stimulus action 未觸發）。 */
export default class extends Controller {
  static targets = ["modal", "editForm", "status", "listItem", "listItemBody"];

  static values = {
    recordId: Number,
  };

  connect() {
    this._boundKeydown = this.#onKeydown.bind(this);
    this._boundClick = this.#handleClick.bind(this);
    this.element.addEventListener("click", this._boundClick);
  }

  disconnect() {
    this.element.removeEventListener("click", this._boundClick);
    document.removeEventListener("keydown", this._boundKeydown);
  }

  #handleClick(event) {
    const deleteBtn = event.target.closest("[data-expenditure-history-action='destroy']");
    if (deleteBtn) {
      this.destroy(event, deleteBtn);
      return;
    }

    const editTrigger = event.target.closest(
      "[data-expenditure-history-action='open-edit']"
    );
    if (editTrigger) {
      this.openEdit(event, editTrigger);
    }
  }

  openEdit(event, trigger = event.currentTarget) {
    event.preventDefault();
    event.stopPropagation();

    const record = this.#recordFromElement(trigger);
    if (!record?.id) return;

    this.recordIdValue = Number(record.id);
    this.#populateForm(record);
    this.#syncPaymentFields();
    this.modalTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");
    document.addEventListener("keydown", this._boundKeydown);
  }

  close(event) {
    event?.preventDefault();
    this.modalTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");
    document.removeEventListener("keydown", this._boundKeydown);
    this.#setStatus("");
  }

  async save(event) {
    event.preventDefault();
    const form = this.editFormTarget;
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }

    this.#setStatus("儲存中…");
    const token = document.querySelector('meta[name="csrf-token"]')?.content;

    try {
      const res = await fetch(this.#updateUrl(), {
        method: "PATCH",
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

      this.#updateListItem(this.#normalizeRecord(json.record));
      this.close();
    } catch {
      this.#setStatus("連線失敗");
    }
  }

  destroy(event, trigger = event.currentTarget) {
    event.preventDefault();
    event.stopPropagation();

    const id = this.#expenditureIdFromElement(trigger);
    if (!id) return;
    if (!window.confirm("確定要刪除這筆記錄嗎？")) return;

    const token = document.querySelector('meta[name="csrf-token"]')?.content;

    const run = async () => {
      try {
        const res = await fetch(`/actual_expenditures/${id}`, {
          method: "DELETE",
          headers: {
            Accept: "application/json",
            "X-CSRF-Token": token ?? "",
            "X-Requested-With": "XMLHttpRequest",
          },
        });
        const json = await res.json().catch(() => ({}));

        if (!res.ok || !json.ok) {
          window.alert(json.errors?.join(" ") || "刪除失敗");
          return;
        }

        const item = this.listItemTargets.find(
          (el) => String(el.dataset.expenditureId) === String(id)
        );
        item?.remove();

        if (this.listItemTargets.length === 0) {
          window.location.reload();
        }
      } catch {
        window.alert("連線失敗");
      }
    };

    run();
  }

  #expenditureIdFromElement(el) {
    const item = el.closest("[data-expenditure-id]");
    const fromRow = item?.getAttribute("data-expenditure-id");
    if (fromRow) return fromRow;
    return null;
  }

  #recordFromElement(el) {
    const item = el.closest("[data-expenditure-id]");
    if (!item) return null;

    const raw = item.getAttribute("data-expenditure-history-record-param");
    if (!raw) return null;

    try {
      const json = this.#decodeRecordParam(raw);
      return this.#normalizeRecord(JSON.parse(json));
    } catch {
      return null;
    }
  }

  #decodeRecordParam(raw) {
    const trimmed = raw.trim();
    if (trimmed.startsWith("{")) return trimmed;
    return atob(trimmed);
  }

  #normalizeRecord(record) {
    if (!record) return null;
    if (typeof record === "string") {
      try {
        record = JSON.parse(record);
      } catch {
        return null;
      }
    }

    return {
      id: record.id,
      transaction_date:
        record.transaction_date ?? record.transactionDate ?? "",
      transaction_item:
        record.transaction_item ?? record.transactionItem ?? "",
      category: record.category ?? "",
      payment_method: record.payment_method ?? record.paymentMethod ?? "",
      credit_card_payment_method:
        record.credit_card_payment_method ??
        record.creditCardPaymentMethod ??
        "",
      payment_timing: record.payment_timing ?? record.paymentTiming ?? "",
      payment_platform: record.payment_platform ?? record.paymentPlatform ?? "",
      actual_amount: record.actual_amount ?? record.actualAmount ?? "",
      posted_amount: record.posted_amount ?? record.postedAmount ?? "",
      note: record.note ?? "",
    };
  }

  #onKeydown(event) {
    if (event.key === "Escape") this.close(event);
  }

  #updateUrl() {
    return `/actual_expenditures/${this.recordIdValue}`;
  }

  #populateForm(record) {
    const form = this.editFormTarget;
    const set = (name, value) => {
      const el = form.elements.namedItem(`actual_expenditure[${name}]`);
      if (!el) return;
      el.value = value ?? "";
      el.dispatchEvent(new Event("change", { bubbles: true }));
    };

    set("transaction_date", record.transaction_date);
    set("transaction_item", record.transaction_item);
    set("category", record.category);
    set("payment_method", record.payment_method);
    set("credit_card_payment_method", record.credit_card_payment_method || "");
    set("payment_timing", record.payment_timing || "");
    set("payment_platform", record.payment_platform || "");
    set("actual_amount", record.actual_amount);
    set("posted_amount", record.posted_amount);
    set("note", record.note || "");
  }

  #syncPaymentFields() {
    const formController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "expenditure-form"
    );
    formController?.sync?.();
  }

  #updateListItem(record) {
    if (!record?.id) return;

    const item = this.listItemTargets.find(
      (el) => String(el.dataset.expenditureId) === String(record.id)
    );
    if (!item) return;

    const body = item.querySelector(
      "[data-expenditure-history-target='listItemBody']"
    );
    if (!body) return;

    const title = record.transaction_item?.trim() || "(無標題)";
    const date = record.transaction_date || "";
    const category = record.category?.trim() || "";
    const amount = record.posted_amount ?? "";

    body.innerHTML = `
      <p class="text-sm text-muted-foreground tabular-nums">${this.#escapeHtml(date)}</p>
      <p class="text-base font-medium text-foreground truncate">${this.#escapeHtml(title)}</p>
      ${
        category
          ? `<p class="text-sm text-muted-foreground truncate">類別：${this.#escapeHtml(category)}</p>`
          : ""
      }
      <p class="text-sm font-medium tabular-nums text-destructive">金額：${this.#escapeHtml(amount)}</p>
    `;

    item.setAttribute(
      "data-expenditure-history-record-param",
      btoa(unescape(encodeURIComponent(JSON.stringify(record))))
    );
  }

  #escapeHtml(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  #setStatus(text) {
    if (!this.hasStatusTarget) return;
    const t = text ?? "";
    this.statusTarget.textContent = t;
    this.statusTarget.classList.toggle("hidden", !t);
  }
}
