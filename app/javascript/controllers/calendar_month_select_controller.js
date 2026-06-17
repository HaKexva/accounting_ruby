import { Controller } from "@hotwired/stimulus";

/** Navigate when the user picks a calendar month (`?ym=YYYY-MM`, or clear `ym` for all). */
export default class extends Controller {
  static values = { url: String };

  navigate(event) {
    const ym = event.target.value;
    const url = new URL(this.urlValue, window.location.origin);
    const current = new URL(window.location.href);

    // Preserve existing filters (q/category/...) when switching month.
    current.searchParams.forEach((value, key) => {
      url.searchParams.set(key, value);
    });
    if (ym) {
      url.searchParams.set("ym", ym);
    } else {
      url.searchParams.delete("ym");
    }
    window.location.assign(url.toString());
  }
}
