import { Controller } from "@hotwired/stimulus";

const EDIT_FIELD_IDS = {
  transaction_date: "history_edit_transaction_date",
  transaction_item: "history_edit_transaction_item",
  category: "history_edit_category",
  payment_method: "history_edit_payment_method",
  credit_card_payment_method: "history_edit_credit_card_payment_method",
  payment_timing: "history_edit_payment_timing",
  payment_platform: "history_edit_payment_platform",
  actual_amount: "history_edit_actual_amount",
  posted_amount: "history_edit_posted_amount",
  note: "history_edit_note",
};

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

    const binary = atob(trimmed);
    const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
    return new TextDecoder().decode(bytes);
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
      payment_summary: record.payment_summary ?? record.paymentSummary ?? "",
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
    this.#setField("transaction_date", record.transaction_date);
    this.#setField("transaction_item", record.transaction_item);
    this.#setField("actual_amount", record.actual_amount);
    this.#setField("posted_amount", record.posted_amount);
    this.#setField("note", record.note || "");

    // 先帶入支付方式並展開子欄位，再寫入子選單（避免 disabled 無法設值）。
    this.#setSelect("category", record.category);
    this.#setSelect("payment_method", record.payment_method);
    this.#syncPaymentFields({ preserveDependent: true });

    this.#setSelect(
      "credit_card_payment_method",
      record.credit_card_payment_method
    );
    this.#setSelect("payment_timing", record.payment_timing);
    this.#setSelect("payment_platform", record.payment_platform);

    this.#syncPaymentFields();
  }

  #field(name) {
    const id = EDIT_FIELD_IDS[name];
    if (id) {
      const byId = document.getElementById(id);
      if (byId) return byId;
    }

    const form = this.editFormTarget;
    if (!form) return null;
    return form.elements.namedItem(`actual_expenditure[${name}]`);
  }

  #setField(name, value) {
    const el = this.#field(name);
    if (!el) return;
    el.value = value ?? "";
  }

  #setSelect(name, value) {
    const el = this.#field(name);
    if (!el || el.tagName !== "SELECT") return;

    const wanted = (value ?? "").toString().trim();
    const wasDisabled = el.disabled;
    el.disabled = false;

    if (!wanted) {
      el.selectedIndex = 0;
    } else {
      el.value = wanted;
      if (el.value !== wanted) {
        const option = Array.from(el.options).find(
          (opt) => opt.value === wanted || opt.text.trim() === wanted
        );
        if (option) el.value = option.value;
      }
    }

    if (wasDisabled) el.disabled = wasDisabled;
  }

  #syncPaymentFields(options = {}) {
    const formController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "expenditure-form"
    );
    formController?.sync?.(options);
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

    body.innerHTML = this.#listItemBodyHtml(record);

    item.setAttribute(
      "data-expenditure-history-record-param",
      btoa(unescape(encodeURIComponent(JSON.stringify(record))))
    );
  }

  #formatListDate(iso) {
    if (!iso) return "";
    const s = String(iso);
    const datePart = s.slice(0, 10);
    return /^\d{4}-\d{2}-\d{2}$/.test(datePart) ? datePart : s;
  }

  #paymentSummaryFromRecord(record) {
    const summary = (record.payment_summary ?? "").trim();
    if (summary) return summary;

    const methodName = (record.payment_method ?? "").trim();
    if (!methodName) return "";

    const parts = [methodName];
    if (methodName.includes("信用卡")) {
      const card = (record.credit_card_payment_method ?? "").trim();
      const timing = (record.payment_timing ?? "").trim();
      if (card) parts.push(card);
      if (timing) parts.push(timing);
    } else if (methodName === "多元支付") {
      const platform = (record.payment_platform ?? "").trim();
      if (platform) parts.push(platform);
    }
    return parts.join(" · ");
  }

  #metaChipHtml(text) {
    return `<span class="inline-block max-w-full truncate rounded-md border border-border/60 bg-muted/40 px-2 py-0.5 text-xs text-muted-foreground">${this.#escapeHtml(text)}</span>`;
  }

  #listItemBodyHtml(record) {
    const title = (record.transaction_item ?? "").trim() || "(無標題)";
    const date = this.#formatListDate(record.transaction_date);
    const chips = [];
    const category = (record.category ?? "").trim();
    if (category) chips.push(category);
    const payment = this.#paymentSummaryFromRecord(record);
    if (payment) chips.push(payment);

    const chipsHtml = chips.length
      ? `<div class="mt-2 flex flex-wrap gap-1.5">${chips.map((c) => this.#metaChipHtml(c)).join("")}</div>`
      : "";

    const amount = record.posted_amount ?? "";

    return `
      <p class="text-xs font-medium uppercase tracking-wide text-muted-foreground tabular-nums">${this.#escapeHtml(date)}</p>
      <p class="mt-1 text-base font-semibold text-foreground truncate">${this.#escapeHtml(title)}</p>
      ${chipsHtml}
      <p class="mt-2 text-sm font-semibold tabular-nums text-destructive">NT$ ${this.#escapeHtml(amount)}</p>
    `;
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
