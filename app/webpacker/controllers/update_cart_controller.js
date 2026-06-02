import { Controller } from "stimulus";

export default class extends Controller {
  connect() {}

  add({ params }) {
    const ev = new CustomEvent("updateCart", {
      detail: { variant: { id: params.variant }, quantity: 1 },
    });
    window.dispatchEvent(ev);
  }
}
