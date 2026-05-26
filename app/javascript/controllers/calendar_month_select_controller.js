import { Controller } from "@hotwired/stimulus";

/** Navigate when the user picks a calendar month (`?ym=YYYY-MM`, or clear `ym` for all). */
export default class extends Controller {
  static values = { url: String };

  navigate(event) {
    const ym = event.target.value;
    const url = new URL(this.urlValue, window.location.origin);
    if (ym) {
      url.searchParams.set("ym", ym);
    } else {
      url.searchParams.delete("ym");
    }
    window.location.assign(url.toString());
  }
}
