import { Controller } from "@hotwired/stimulus";

/** Navigate to the dashboard for the selected calendar month (`?ym=YYYY-MM`). */
export default class extends Controller {
  static values = { url: String };

  navigate(event) {
    const ym = event.target.value;
    if (!ym) return;

    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("ym", ym);
    window.location.assign(url.toString());
  }
}
