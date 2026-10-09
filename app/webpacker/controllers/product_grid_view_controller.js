import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["loading", "products"];

  updateProducts(ev) {
    this.showLoading();

    const orderCycleId = ev.detail.orderCycleId;
    // Updating the turbo-frame source will reload the frame
    this.element.src = `/order_cycles/${orderCycleId}/products`;
  }

  showLoading(ev) {
    // Turbo requests from forms within the frame bubble up here too, only the frame's own
    // requests (e.g. changing page) replace the products
    if (ev?.target && ev.target !== this.element) return;

    this.loadingTarget.style.display = "block";
    if (this.hasProductsTarget) {
      this.productsTarget.style.display = "none";
    }
  }

  // Bring the start of the list back into view after changing page
  scrollToTop() {
    // use window.scrollTo instead of element.scrollIntoView, so we can apply an offset to take into
    // account the <nav> top bar's height
    if (this.element.getBoundingClientRect().top < 0) {
      const headerOffset = document.getElementsByTagName("nav")[0].offsetHeight;
      const elementPosition = this.element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

      window.scrollTo({
        top: offsetPosition,
        behavior: "smooth",
      });
    }
  }
}
