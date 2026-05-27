import { Controller } from "@hotwired/stimulus";

/** Debounced auto-save for budget cards (POST create or PATCH update). */
export default class extends Controller {
  static targets = ["budgetForm", "status", "deleteSlot", "discardButton"];
  static values = {
    memberPrefix: String,
    debounce: { type: Number, default: 650 },
    newRecordDebounce: { type: Number, default: 1800 },
    discardConfirm: { type: String, default: "確定捨棄尚未儲存的內容？" },
    recordId: Number,
  };

  connect() {
    this._timer = null;
    this._saving = false;
    this.initialSnapshot = this.#snapshot(this.budgetFormTarget);
    this._onFormFocusOut = (event) => this.#saveOnFormFocusOut(event);
    if (this.#isNewRecord()) {
      this.budgetFormTarget.addEventListener("focusout", this._onFormFocusOut);
    }
  }

  disconnect() {
    if (this.#isNewRecord()) {
      this.budgetFormTarget.removeEventListener("focusout", this._onFormFocusOut);
    }
  }

  scheduleSave() {
    if (this.#isNewRecord()) return;

    clearTimeout(this._timer);
    this._timer = setTimeout(() => this.save(), this.debounceValue);
  }

  #saveOnFormFocusOut(event) {
    if (!this.#isNewRecord()) return;
    if (this.budgetFormTarget.contains(event.relatedTarget)) return;

    clearTimeout(this._timer);
    this._timer = setTimeout(() => this.save(), 400);
  }

  discardUnsaved(event) {
    event.preventDefault();
    const dirty =
      this.#snapshot(this.budgetFormTarget) !== this.initialSnapshot;
    if (dirty && !window.confirm(this.discardConfirmValue)) return;
    this.budgetFormTarget.reset();
    this.initialSnapshot = this.#snapshot(this.budgetFormTarget);
    this.#setStatus("");
  }

  async save() {
    const form = this.budgetFormTarget;
    if (this.#snapshot(form) === this.initialSnapshot || this._saving) return;
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }

    this._saving = true;
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

      if (json.id != null && this.#isNewRecord()) {
        const slide = this.#slideRoot();
        const track = slide?.parentElement;
        let blankClone = null;
        if (slide && track) {
          blankClone = slide.cloneNode(true);
          this.#prepareFreshBlankSlide(blankClone);
        }

        this.#promoteNewToSaved(json.id);

        if (slide) {
          const { oldToken, newToken } = this.#savedIdTokens(json.id);
          this.#renameDomTokensInSubtree(slide, oldToken, newToken);
        }

        if (blankClone && track) {
          track.appendChild(blankClone);
          this.#reinitCarouselAfterSlidesChange(slide);
        }
      }

      this.initialSnapshot = this.#snapshot(form);
      this.#setStatus("已自動儲存");
      window.setTimeout(() => {
        if (this.#snapshot(form) === this.initialSnapshot) this.#setStatus("");
      }, 2000);
    } catch {
      this.#setStatus("連線失敗");
    } finally {
      this._saving = false;
    }
  }

  #isNewRecord() {
    return !this.hasRecordIdValue || this.recordIdValue <= 0;
  }

  #slideRoot() {
    return this.element.closest('[aria-roledescription="slide"]');
  }

  /** POST collection URL from member prefix `/budgets/…_budgets/`. */
  #collectionUrl() {
    const p = this.memberPrefixValue || "";
    return p.endsWith("/") ? p.slice(0, -1) : p;
  }

  #savedIdTokens(id) {
    const isRevenue = (this.memberPrefixValue || "").includes("revenue_budgets");
    const oldToken = isRevenue ? "rev_new" : "exp_new";
    const newToken = isRevenue ? `rev_${id}` : `exp_${id}`;
    return { oldToken, newToken };
  }

  /** Clone is taken before promote; reset fields and POST action so it stays a blank card. */
  #prepareFreshBlankSlide(root) {
    const form = root.querySelector("form");
    if (form) {
      form.action = this.#collectionUrl();
      const method = form.querySelector('input[name="_method"]');
      method?.remove();
      form.reset();
    }

    const autoRoot = root.querySelector('[data-controller*="budget-auto-save"]');
    if (autoRoot?.dataset) {
      delete autoRoot.dataset.budgetAutoSaveRecordIdValue;
    }

    const status = root.querySelector('[data-budget-auto-save-target="status"]');
    if (status) {
      status.textContent = "";
      status.classList.add("hidden");
    }
  }

  #renameDomTokensInSubtree(root, oldToken, newToken) {
    if (!root || oldToken === newToken) return;

    [ root, ...root.querySelectorAll("*") ].forEach((el) => {
      if (el.id?.includes(oldToken)) {
        el.id = el.id.split(oldToken).join(newToken);
      }
      const htmlFor = el.getAttribute("for");
      if (htmlFor?.includes(oldToken)) {
        el.setAttribute("for", htmlFor.split(oldToken).join(newToken));
      }
      const aria = el.getAttribute("aria-controls");
      if (aria?.includes(oldToken)) {
        el.setAttribute("aria-controls", aria.split(oldToken).join(newToken));
      }
    });
  }

  #reinitCarouselAfterSlidesChange(slideEl) {
    const carouselRoot = slideEl.closest('[data-controller*="ruby-ui--carousel"]');
    if (!carouselRoot) return;

    const carouselCtrl = this.application.getControllerForElementAndIdentifier(
      carouselRoot,
      "ruby-ui--carousel"
    );
    const embla = carouselCtrl?.carousel;
    if (!embla) return;

    embla.reInit();
    requestAnimationFrame(() => {
      const slides = embla.slideNodes();
      const index = slides.indexOf(slideEl);
      if (index >= 0) {
        carouselCtrl.scrollToIndex(index);
      }
    });
  }

  #promoteNewToSaved(id) {
    const form = this.budgetFormTarget;
    form.action = `${this.memberPrefixValue}${id}`;

    let method = form.querySelector('input[name="_method"]');
    if (!method) {
      method = document.createElement("input");
      method.type = "hidden";
      method.name = "_method";
      form.appendChild(method);
    }
    method.value = "patch";

    this.recordIdValue = id;

    if (this.hasDiscardButtonTarget) {
      this.discardButtonTarget.remove();
    }

    this.#appendDeleteForm(id);
  }

  #appendDeleteForm(id) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    const form = document.createElement("form");
    form.method = "post";
    form.action = `${this.memberPrefixValue}${id}`;
    form.className = "inline-flex shrink-0 items-center justify-center";

    const auth = document.createElement("input");
    auth.type = "hidden";
    auth.name = "authenticity_token";
    auth.value = token ?? "";
    form.appendChild(auth);

    const method = document.createElement("input");
    method.type = "hidden";
    method.name = "_method";
    method.value = "delete";
    form.appendChild(method);

    const btn = document.createElement("button");
    btn.type = "submit";
    btn.textContent = "刪除";
    btn.setAttribute("data-turbo-confirm", "確定刪除此筆預算？");
    btn.className = [
      "inline-flex items-center justify-center whitespace-nowrap rounded-md font-medium transition-colors",
      "px-4 py-2 h-9 text-sm shadow-sm",
      "bg-destructive text-white hover:bg-destructive/90",
      "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring dark:bg-destructive/60",
    ].join(" ");
    form.appendChild(btn);

    this.deleteSlotTarget.appendChild(form);
  }

  #setStatus(text) {
    if (!this.hasStatusTarget) return;
    const t = text ?? "";
    this.statusTarget.textContent = t;
    this.statusTarget.classList.toggle("hidden", !t);
  }

  #snapshot(form) {
    const data = new FormData(form);
    const pairs = [];
    for (const [key, val] of data.entries()) {
      pairs.push([key, val instanceof File ? val.name : String(val)]);
    }
    pairs.sort(
      (a, b) =>
        a[0].localeCompare(b[0]) || String(a[1]).localeCompare(String(b[1]))
    );
    return pairs
      .map(
        ([k, v]) =>
          `${encodeURIComponent(k)}=${encodeURIComponent(v)}`
      )
      .join("&");
  }
}
